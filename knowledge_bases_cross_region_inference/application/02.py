import boto3

KNOWLEDGEBASE_ID = "XXXXXXXX"  # ナレッジベース ID を記載
model_arn = "arn:aws:bedrock:us-west-2:123456789012:inference-profile/us.anthropic.claude-3-5-sonnet-20240620-v1:0"
client = boto3.client("bedrock-agent-runtime", region_name="us-west-2")
session_id = ""

prompt = (
    "20代社員は何名ほどでしょうか？"
)

response = client.retrieve_and_generate(
    input={"text": prompt},
    retrieveAndGenerateConfiguration={
        "type": "KNOWLEDGE_BASE",
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": KNOWLEDGEBASE_ID,
            "modelArn": model_arn,
        },
    },
)
print(response["output"]["text"],flush=False)
session_id = response["sessionId"]

# 書き換え
prompt = (
    "30代社員は何名ほどでしょうか？"
)

response_with_session_id = client.retrieve_and_generate(
    input={"text": prompt},
    retrieveAndGenerateConfiguration={
        "type": "KNOWLEDGE_BASE",
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": KNOWLEDGEBASE_ID,
            "modelArn": model_arn,
        },
    },
    sessionId=session_id
)

print(response_with_session_id["output"]["text"],flush=False)