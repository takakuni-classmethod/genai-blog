import boto3
import json
from pinecone.grpc import PineconeGRPC, GRPCClientConfig

pc = PineconeGRPC(api_key="pclocal", host="http://localhost:5081")
client = boto3.client("bedrock-runtime", region_name="us-east-1")

model_id = "amazon.titan-embed-text-v2:0"
index_name = "pinecone-local-index"
input_text = "Please recommend books with a theme similar to the movie 'Inception'."

native_request = {"inputText": input_text}
request = json.dumps(native_request)
response = client.invoke_model(modelId=model_id, body=request)
request_id = response["ResponseMetadata"]["RequestId"]
model_response = json.loads(response["body"].read())
embedding = model_response["embedding"]

host = pc.describe_index(index_name).host
index = pc.Index(host=host, grpc_config=GRPCClientConfig(secure=False))


result = index.upsert(
    vectors=[
        {
            "id": request_id,
            "values": embedding,
            "metadata": {"text": input_text}
        }
    ]
)

print(result)