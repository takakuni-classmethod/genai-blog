#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html
# Create an index with the cosine operator which the bedrock can use to query the data
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "ALTER TABLE bedrock_integration.bedrock_kb \
  ADD COLUMN IF NOT EXISTS target VARCHAR(100), \
  ADD COLUMN IF NOT EXISTS year SMALLINT, \
  ADD COLUMN IF NOT EXISTS for_managers BOOLEAN;"