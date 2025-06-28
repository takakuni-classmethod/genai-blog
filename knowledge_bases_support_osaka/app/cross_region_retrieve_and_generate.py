import os
import json
import boto3

bucket_name = os.environ.get("BUCKET_NAME")
kb_id = os.environ.get("KNOWLEDGE_BASE_ID")
agent_runtime_tokyo = boto3.client(
    "bedrock-agent-runtime", region_name="ap-northeast-1"
)
agent_runtime_oregon = boto3.client("bedrock-agent-runtime", region_name="us-west-2")
bedrock_runtime_oregon = boto3.client("bedrock-runtime", region_name="us-west-2")

text_model_id = "cohere.command-r-plus-v1:0"
messsage = "事業計画について教えてください"

filter = {
    "andAll": [
        {"equals": {"key": "year", "value": 2023}},
        {"equals": {"key": "for_managers", "value": True}},
    ]
}

# 東京リージョン
## ベクトル検索
vector_search_response = agent_runtime_tokyo.retrieve(
    knowledgeBaseId=kb_id,
    retrievalConfiguration={
        "vectorSearchConfiguration": {
            "filter": filter,
            "numberOfResults": 5,
        },
    },
    retrievalQuery={"text": messsage},
)
retrieval_results = vector_search_response.get("retrievalResults")

# オレゴンリージョン
## 質問文の生成
generate_search_query_request = json.dumps(
    {
        "message": messsage,
        "search_queries_only": True,
    }
)

generate_search_query_response = bedrock_runtime_oregon.invoke_model(
    body=generate_search_query_request,
    contentType="application/json",
    accept="application/json",
    modelId=text_model_id,
)

generate_search_query_response_body = json.loads(
    generate_search_query_response.get("body").read()
)
search_queries = generate_search_query_response_body.get("search_queries")

## ドキュメントの整形
documents = []
for query in search_queries:
    query_text = query.get("text")
    for result in retrieval_results:
        result_text = result.get("content").get("text")
        documents.append({"title": query_text, "snippet": result_text})

## 回答分の生成
answer_request = json.dumps(
    {
        "message": messsage,
        "documents": documents,
    }
)

answer_response = bedrock_runtime_oregon.invoke_model(
    body=answer_request,
    contentType="application/json",
    accept="application/json",
    modelId=text_model_id,
)

answer_response_body = json.loads(answer_response.get("body").read())
output_text = answer_response_body.get("text")

print(output_text)
