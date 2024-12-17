import json
from pinecone.grpc import PineconeGRPC, GRPCClientConfig

pc = PineconeGRPC(api_key="pclocal", host="http://localhost:5081")

index_name = "pinecone-local-index"
host = pc.describe_index(index_name).host
index = pc.Index(host=host, grpc_config=GRPCClientConfig(secure=False))

for ids in index.list():
    print(index.fetch(ids))