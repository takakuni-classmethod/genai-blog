#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html

EMBEDDING_DIMENSION=$(echo $EMBEDDING_DIMENSION | sed 's/"//g')

# Login as the bedrock_user and create a table in the bedrock_integration schema
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "CREATE TABLE IF NOT EXISTS bedrock_integration.bedrock_kb (id uuid PRIMARY KEY, embedding vector($EMBEDDING_DIMENSION), chunks text, metadata json);"