import os
import boto3
from botocore.exceptions import ClientError

client = boto3.client("bedrock-runtime", region_name="us-west-2")
guardrail_identifier = os.getenv("GUARDRAIL_IDENTIFIER")
guardrail_version = os.getenv("GUARDRAIL_VERSION")

model_id = "amazon.titan-text-express-v1"
# model_id = "anthropic.claude-3-opus-20240229-v1:0"
# model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

guardrail_config = {
    "guardrailIdentifier": guardrail_identifier,
    "guardrailVersion": guardrail_version
}
user_message = "こんにちは！私の名前はたかくにです。あなたの名前は何ですか？"

conversation = [
    {
        "role": "user",
        "content": [{"text": user_message}],
    }
]

try:
    response = client.converse(
        modelId=model_id,
        messages=conversation,
        inferenceConfig={"maxTokens": 512, "temperature": 1},
    )

    response_text = response["output"]["message"]["content"][0]["text"]
    print(response_text)

except (ClientError, Exception) as e:
    print(f"ERROR: Can't invoke '{model_id}'. Reason: {e}")
    exit(1)