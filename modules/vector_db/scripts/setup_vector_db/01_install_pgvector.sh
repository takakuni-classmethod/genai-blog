#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html

# Install pgvector extension
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "CREATE EXTENSION IF NOT EXISTS vector;"

# Check the version of the pg_vector extension
aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "SELECT extversion FROM pg_extension WHERE extname='vector';"