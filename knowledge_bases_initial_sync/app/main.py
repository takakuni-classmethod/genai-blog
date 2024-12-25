import sys
import boto3

AWS_ACCOUNT_ID = "123456789012"  # AWS アカウント ID を記載

################################################
# Oregon
################################################
REGION = 'us-west-2'  # リージョンを記載
KNOWLEDGEBASE_ID = 'RKYSGDHVAT'  # ナレッジベース ID を記載

letency = "standard"
letency = "optimized"

bedrock_agent_runtime = boto3.client("bedrock-agent-runtime", region_name=REGION)

def search(prompt):
    response = bedrock_agent_runtime.retrieve_and_generate(
        input={"text": prompt},
        retrieveAndGenerateConfiguration={
            "type": "KNOWLEDGE_BASE",
            "knowledgeBaseConfiguration": {
                "generationConfiguration": {
                    "performanceConfig": {
                        "latency" : letency
                    }
                },
                "knowledgeBaseId": KNOWLEDGEBASE_ID,
                "modelArn": f"arn:aws:bedrock:{REGION}:{AWS_ACCOUNT_ID}:inference-profile/us.anthropic.claude-3-5-haiku-20241022-v1:0",
            },
        },
    )
    print(response["output"]["text"],flush=False)

if __name__ == "__main__":
    args = sys.argv
    search(args[1])