import boto3

KNOWLEDGEBASE_ID = "XXXXXXXXXX"  # ナレッジベース ID を記載
model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
bedrock_agent = boto3.client("bedrock-agent-runtime", region_name="us-west-2")

prompt = (
    "Amazon Bedrock って何ですか？食べ物ですか？美味しいですか？どこで利用できますか？お高いんでしょう...？"
)

response = bedrock_agent.retrieve_and_generate(
    input={"text": prompt},
    retrieveAndGenerateConfiguration={
        "type": "KNOWLEDGE_BASE",
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": KNOWLEDGEBASE_ID,
            "modelArn": model_arn,
            "orchestrationConfiguration": {
                "queryTransformationConfiguration": {"type": "QUERY_DECOMPOSITION"}
            },
        },
    },
)
# print(response)
print(response["output"]["text"],flush=False)