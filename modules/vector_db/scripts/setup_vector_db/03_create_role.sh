#!/bin/bash
# For more information, see the official documentation:
# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html
# For more information on the SQL commands used in this script, see the documentation:
# https://stackoverflow.com/questions/8092086/create-postgresql-role-user-if-it-doesnt-exist

ROLE_NAME=$(echo $ROLE_NAME | sed 's/"//g')
PASSWORD=$(echo $PASSWORD | sed 's/"//g')

# Create a new role that Bedrock can use to query the database

aws rds-data --region $REGION execute-statement \
  --resource-arn $CLUSTER_ARN \
  --secret-arn $SECRET_ARN \
  --database $DATABASE_NAME \
  --sql "
    DO
    \$do\$
    BEGIN
      IF EXISTS (
          SELECT FROM pg_catalog.pg_roles 
          WHERE rolname = '$ROLE_NAME') THEN

          RAISE NOTICE 'Role $ROLE_NAME already exists. Skipping.';
      ELSE
          CREATE ROLE $ROLE_NAME LOGIN PASSWORD '$PASSWORD';
      END IF;
    END
    \$do\$;"