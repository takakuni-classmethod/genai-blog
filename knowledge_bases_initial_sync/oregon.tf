########################################################
# Data Source
########################################################
module "datasource_oregon" {
  providers = {
    aws = aws.oregon
  }
  source = "../modules/datasource"

  prefix = "${local.prefix}-${local.oregon}"
  datasource = {
    force_destroy = var.datasource.force_destroy
  }
}

########################################################
# Put Object
########################################################
resource "aws_s3_object" "momotarou_oregon" {
  for_each    = fileset("../サンプルドキュメント/semantic-chunking/", "*")
  bucket      = module.datasource_oregon.bucket.id
  key         = "./${each.value}"
  source      = "../サンプルドキュメント/semantic-chunking/${each.value}"
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/${each.value}")
}

########################################################
# Foundation Model
########################################################
data "aws_bedrock_foundation_models" "embedding_oregon" {
  provider = aws.oregon

  by_output_modality = "EMBEDDING"
}

data "aws_bedrock_foundation_model" "embedding_oregon" {
  provider = aws.oregon

  model_id = "amazon.titan-embed-text-v2:0"
}

#######################################################
# Vector Database
#######################################################
resource "aws_secretsmanager_secret" "oregon" {
  provider = aws.oregon

  name_prefix             = "${local.prefix}-pinecone"
  description             = "Password for the bedrock_user"
  recovery_window_in_days = var.vector_db.secret_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "oregon" {
  provider = aws.oregon

  secret_id = aws_secretsmanager_secret.oregon.id
  # The key name must be "apiKey" for the Pinecone Vector Database.
  # for more information, see the following:
  # https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html
  secret_string = jsonencode(
    {
      apiKey = var.vector_db.pinecone_api_key
    }
  )
}

resource "pinecone_index" "oregon" {
  name      = "${local.prefix}-${local.oregon}"
  dimension = local.model_dimension[data.aws_bedrock_foundation_model.embedding_oregon.model_id]

  spec = {
    serverless = {
      cloud  = "aws"
      region = local.oregon
    }
  }
}

########################################################
# IAM Role for Knowledge Bases
########################################################
resource "aws_iam_role" "knowledge_bases_oregon" {
  provider = aws.oregon

  name = "${local.prefix}-kb-role-${local.oregon}"
  assume_role_policy = templatefile("./policy/assume_kb.json", {
    region     = local.oregon
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-kb-role-${local.oregon}"
  }
}

resource "aws_iam_policy" "knowledge_bases_oregon" {
  provider = aws.oregon

  name = "${local.prefix}-kb-policy-${local.oregon}"
  /* 
    The policy statement that specifies the permissions for the knowledge base.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html
  */
  policy = templatefile("./policy/iam_kb.json", {
    bucket_arn = module.datasource_oregon.bucket.arn
    account_id = local.account_id
    secret_arn = aws_secretsmanager_secret.oregon.arn
  })

  tags = {
    Name = "${local.prefix}-kb-policy-${local.oregon}"
  }
}

resource "aws_iam_role_policy_attachment" "knowledge_bases_oregon" {
  provider = aws.oregon

  role       = aws_iam_role.knowledge_bases_oregon.name
  policy_arn = aws_iam_policy.knowledge_bases_oregon.arn
}

########################################################
# Knowledge Bases
########################################################
resource "aws_cloudwatch_log_group" "oregon" {
  provider = aws.oregon

  name              = "/aws/vendedlogs/bedrock/knowledge-base/APPLICATION_LOGS/${local.prefix}-knowledge-base-${local.oregon}"
  retention_in_days = 7
}

resource "aws_bedrockagent_knowledge_base" "oregon" {
  provider = aws.oregon

  name     = "${local.prefix}-knowledge-base-${local.oregon}"
  role_arn = aws_iam_role.knowledge_bases_oregon.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding_oregon.model_arn
    }
  }

  storage_configuration {
    type = "PINECONE"
    pinecone_configuration {
      connection_string      = "https://${pinecone_index.oregon.host}"
      credentials_secret_arn = aws_secretsmanager_secret.oregon.arn
      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.knowledge_bases_oregon,
  ]
}

########################################################
# Knowledge Base Data Source
########################################################
resource "aws_bedrockagent_data_source" "oregon" {
  provider = aws.oregon

  name                 = "${local.prefix}-knowledge-base-datasource-${local.oregon}"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.oregon.id
  data_deletion_policy = "DELETE" // "RETAIN"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = module.datasource_oregon.bucket.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "SEMANTIC"
      semantic_chunking_configuration {
        breakpoint_percentile_threshold = 95
        buffer_size                     = 0
        max_token                       = 300
      }
    }
  }
}

resource "terraform_data" "datasource_sync" {
  triggers_replace = [
    aws_bedrockagent_data_source.oregon
  ]

  provisioner "local-exec" {
    command = <<EOT
INGESTION_JOB_ID=$(aws bedrock-agent start-ingestion-job --region ${local.oregon} \
--data-source-id ${aws_bedrockagent_data_source.oregon.data_source_id} \
--knowledge-base-id ${aws_bedrockagent_knowledge_base.oregon.id} \
--query ingestionJob.ingestionJobId --output text)

while true; do
  export STATUS=$(aws bedrock-agent get-ingestion-job \
  --region ${local.oregon} \
  --knowledge-base-id ${aws_bedrockagent_knowledge_base.oregon.id} \
  --data-source-id ${aws_bedrockagent_data_source.oregon.data_source_id} \
  --ingestion-job-id $INGESTION_JOB_ID \
  --query ingestionJob.status \
  --output text)
  if [ "$STATUS" = "COMPLETE" ]; then
    echo "Ingestion job is complete."
    break
  elif [ "$STATUS" = "FAILED" ]; then
    echo "Ingestion job failed."
    exit 1
  fi
  sleep 10
done
EOT
  }
}
