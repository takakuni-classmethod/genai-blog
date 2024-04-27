#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html

ROLE_NAME=$(echo $ROLE_NAME | sed 's/"//g')

# Grant the bedrock_user permission to manage the bedrock_integration schema
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "GRANT ALL ON SCHEMA bedrock_integration to $ROLE_NAME;"