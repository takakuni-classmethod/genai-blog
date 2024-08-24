import boto3

KNOWLEDGEBASE_ID = "295SHUIWOD"  # ナレッジベース ID を記載
# model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-instant-v1"
# model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-v2"
# model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-v2:1"
# model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
# model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
bedrock_agent = boto3.client("bedrock-agent-runtime", region_name="us-west-2")

prompt = (
    "Amazon Bedrock って何ですか？"
)

response = bedrock_agent.retrieve_and_generate(
    input={"text": prompt},
    retrieveAndGenerateConfiguration={
        "type": "KNOWLEDGE_BASE",
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": KNOWLEDGEBASE_ID,
            "modelArn": model_arn,
            # "orchestrationConfiguration": {
            #     "queryTransformationConfiguration": {"type": "QUERY_DECOMPOSITION"}
            # },
        },
    },
)
print(response["output"]["text"],flush=False)
