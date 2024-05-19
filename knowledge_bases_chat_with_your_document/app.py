import boto3

bedrock_client = boto3.client(
    service_name="bedrock-agent-runtime", region_name="us-east-1"
)
model_id = "anthropic.claude-3-haiku-20240307-v1:0"  # Replace with your model ID
# model_id = "anthropic.claude-3-sonnet-20240229-v1:0"  # Replace with your model ID
document_uri = ""  # Replace with your S3 URI


def retrieveAndGenerate(
    input_text, source_type, model_id, document_s3_uri=None, data=None
):
    region = "us-east-1"
    model_arn = f"arn:aws:bedrock:{region}::foundation-model/{model_id}"

    if source_type == "S3":
        return bedrock_client.retrieve_and_generate(
            input={"text": input_text},
            retrieveAndGenerateConfiguration={
                "type": "EXTERNAL_SOURCES",
                "externalSourcesConfiguration": {
                    "modelArn": model_arn,
                    "sources": [
                        {
                            "sourceType": source_type,
                            "s3Location": {"uri": document_s3_uri},
                        }
                    ],
                },
            },
        )

    else:
        return bedrock_client.retrieve_and_generate(
            input={"text": input_text},
            retrieveAndGenerateConfiguration={
                "type": "EXTERNAL_SOURCES",
                "externalSourcesConfiguration": {
                    "modelArn": model_arn,
                    "sources": [
                        {
                            "sourceType": source_type,
                            "byteContent": {
                                "identifier": "testFile.txt",
                                "contentType": "text/plain",
                                "data": data,
                            },
                        }
                    ],
                },
            },
        )


response = retrieveAndGenerate(
    input_text="タコの天ぷらを作るときのコツは何ですか？",
    source_type="S3",
    model_id=model_id,
    document_s3_uri=document_uri,
)

print(response["output"]["text"])
