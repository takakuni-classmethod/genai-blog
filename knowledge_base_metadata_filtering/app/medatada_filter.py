import os
import boto3

bucket_name = os.environ.get("BUCKET_NAME")
region = os.environ.get("AWS_REGION")
kb_id = os.environ.get("KNOWLEDGE_BASE_ID")
client = boto3.client("bedrock-agent-runtime", region_name=region)

filter = {
    "andAll": [
        {"equals": {"key": "year", "value": 2024}},
        {"equals": {"key": "for_managers", "value": True}},
    ]
}

# response = client.retrieve(
#     knowledgeBaseId=kb_id,
#     retrievalConfiguration={
#         "vectorSearchConfiguration": {
#             "filter": filter,
#             "numberOfResults": 5,
#         },
#     },
#     retrievalQuery={"text": "来年はどんな事業に注力する予定ですか？"},
# )

response = client.retrieve_and_generate(
    input={"text": "来年はどんな事業に注力する予定ですか？"},
    retrieveAndGenerateConfiguration={
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": kb_id,
            "modelArn": "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
            "retrievalConfiguration": {
                "vectorSearchConfiguration": {
                    "filter": filter,
                    "numberOfResults": 5,
                }
            },
        },
        "type": "KNOWLEDGE_BASE",
    },
)

print(response["output"]["text"])
