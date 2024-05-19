import os
import boto3

region = os.environ.get("AWS_REGION")
kb_id = os.environ.get("KNOWLEDGE_BASE_ID")
client = boto3.client("bedrock-agent-runtime", region_name=region)

generation_configuration = {
    "inferenceConfig": {
        "textInferenceConfig": {
            "maxTokens": 2048,  # Default
            "temperature": 1,  # Default
            "topP": 1,  # Default
            "stopSequences": ["Observation"],
        }
    },
    "additionalModelRequestFields": {"top_k": 50},  # Deafault
}

response = client.retrieve_and_generate(
    input={"text": "来年はどんな事業に注力する予定ですか？"},
    retrieveAndGenerateConfiguration={
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": kb_id,
            "modelArn": "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
            "generationConfiguration": generation_configuration,
        },
        "type": "KNOWLEDGE_BASE",
    },
)

print(response["output"]["text"])
