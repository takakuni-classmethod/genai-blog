from pinecone.grpc import PineconeGRPC

pc = PineconeGRPC(api_key="pclocal", host="http://localhost:5081")

result = pc.list_indexes()

print(result)