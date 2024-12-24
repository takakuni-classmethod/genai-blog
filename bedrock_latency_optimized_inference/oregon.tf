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
resource "aws_s3_object" "momotarou_chapter1_oregon" {
  provider = aws.oregon

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt"
  # アップロード先(S3)
  key    = "桃太郎第1章.txt"
  bucket = module.datasource_oregon.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt")
}

resource "aws_s3_object" "momotarou_chapter2_oregon" {
  provider = aws.oregon

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt"
  # アップロード先(S3)
  key    = "桃太郎第2章.txt"
  bucket = module.datasource_oregon.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt")
}

resource "aws_s3_object" "momotarou_chapter3_oregon" {
  provider = aws.oregon

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt"
  # アップロード先(S3)
  key    = "桃太郎第3章.txt"
  bucket = module.datasource_oregon.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt")
}

resource "aws_s3_object" "momotarou_chapter4_oregon" {
  provider = aws.oregon

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt"
  # アップロード先(S3)
  key    = "桃太郎第4章.txt"
  bucket = module.datasource_oregon.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt")
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

########################################################
# IAM Role for Agents
########################################################
resource "aws_iam_role" "agents_oregon" {
  provider = aws.oregon

  name = "${local.prefix}-agents-role-${local.oregon}"
  assume_role_policy = templatefile("./policy/assume_agent.json", {
    region     = local.oregon
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-agents-role-${local.oregon}"
  }
}

resource "aws_iam_policy" "agents_oregon" {
  provider = aws.oregon

  name = "${local.prefix}-agents-policy-${local.oregon}"
  /* 
    The policy statement that specifies the permissions for the agents.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html
  */
  policy = templatefile("./policy/iam_agent.json", {
    kb_arn     = aws_bedrockagent_knowledge_base.oregon.arn
    secret_arn = aws_secretsmanager_secret.oregon.arn
  })

  tags = {
    Name = "${local.prefix}-agents-policy-${local.oregon}"
  }
}

resource "aws_iam_role_policy_attachment" "agents_oregon" {
  provider = aws.oregon

  role       = aws_iam_role.agents_oregon.name
  policy_arn = aws_iam_policy.agents_oregon.arn
}

########################################################
# Agents
########################################################
resource "aws_bedrockagent_agent" "oregon" {
  provider = aws.oregon

  agent_name              = "${local.prefix}-agents-${local.oregon}"
  agent_resource_role_arn = aws_iam_role.agents_oregon.arn
  foundation_model        = "us.anthropic.claude-3-5-haiku-20241022-v1:0"
  prepare_agent           = true
  instruction             = local.prompt
}

resource "aws_bedrockagent_agent_knowledge_base_association" "oregon" {
  provider = aws.oregon

  agent_id             = aws_bedrockagent_agent.oregon.id
  description          = "Momo Taro Knowledge Base"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.oregon.id
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent_alias" "oregon" {
  provider = aws.oregon

  agent_alias_name = "${local.prefix}-agents-alias-${local.oregon}"
  agent_id         = aws_bedrockagent_agent.oregon.agent_id
  description      = "${local.prefix}-agents-alias-${local.oregon}"

  depends_on = [
    aws_bedrockagent_agent_knowledge_base_association.oregon,
  ]

  lifecycle {
    replace_triggered_by = [
      aws_bedrockagent_agent.oregon,
    ]
  }
}

########################################################
# IAM Role for Flow
########################################################
resource "aws_iam_role" "flows_oregon" {
  provider = aws.oregon

  name = "${local.prefix}-flows-role-${local.oregon}"
  assume_role_policy = templatefile("./policy/assume_agent.json", {
    region     = local.oregon
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-flows-role-${local.oregon}"
  }
}

resource "aws_iam_policy" "flows_oregon" {
  provider = aws.oregon

  name = "${local.prefix}-flows-policy-${local.oregon}"
  /* 
    The policy statement that specifies the permissions for the agents.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html
  */
  policy = templatefile("./policy/iam_flow.json", {
    kb_arn     = aws_bedrockagent_knowledge_base.oregon.arn
    secret_arn = aws_secretsmanager_secret.oregon.arn
  })

  tags = {
    Name = "${local.prefix}-flows-policy-${local.oregon}"
  }
}

resource "aws_iam_role_policy_attachment" "flows_oregon" {
  provider = aws.oregon

  role       = aws_iam_role.flows_oregon.name
  policy_arn = aws_iam_policy.flows_oregon.arn
}
