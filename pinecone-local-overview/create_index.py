from pinecone.grpc import PineconeGRPC
from pinecone import ServerlessSpec

pc = PineconeGRPC(api_key="pclocal", host="http://localhost:5081", ssl=True)

index_name = "pinecone-local-index"

if not pc.has_index(index_name):
    pc.create_index(
        name=index_name,
        dimension=1024,
        metric='cosine',
        spec=ServerlessSpec(
            cloud="aws",
            region="us-east-1"
        )
    )

result = pc.list_indexes()

print(result)