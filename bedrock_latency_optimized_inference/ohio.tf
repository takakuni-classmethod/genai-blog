########################################################
# Data Source
########################################################
module "datasource_ohio" {
  providers = {
    aws = aws.ohio
  }
  source = "../modules/datasource"

  prefix = "${local.prefix}-${local.ohio}"
  datasource = {
    force_destroy = var.datasource.force_destroy
  }
}

########################################################
# Put Object
########################################################
resource "aws_s3_object" "momotarou_chapter1_ohio" {
  provider = aws.ohio

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt"
  # アップロード先(S3)
  key    = "桃太郎第1章.txt"
  bucket = module.datasource_ohio.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt")
}

resource "aws_s3_object" "momotarou_chapter2_ohio" {
  provider = aws.ohio

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt"
  # アップロード先(S3)
  key    = "桃太郎第2章.txt"
  bucket = module.datasource_ohio.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt")
}

resource "aws_s3_object" "momotarou_chapter3_ohio" {
  provider = aws.ohio

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt"
  # アップロード先(S3)
  key    = "桃太郎第3章.txt"
  bucket = module.datasource_ohio.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt")
}

resource "aws_s3_object" "momotarou_chapter4_ohio" {
  provider = aws.ohio

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt"
  # アップロード先(S3)
  key    = "桃太郎第4章.txt"
  bucket = module.datasource_ohio.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt")
}

########################################################
# Foundation Model
########################################################
data "aws_bedrock_foundation_models" "embedding_ohio" {
  provider = aws.ohio

  by_output_modality = "EMBEDDING"
}

data "aws_bedrock_foundation_model" "embedding_ohio" {
  provider = aws.ohio

  model_id = "amazon.titan-embed-text-v2:0"
}

#######################################################
# Vector Database
#######################################################
resource "aws_secretsmanager_secret" "ohio" {
  provider = aws.ohio

  name_prefix             = "${local.prefix}-pinecone"
  description             = "Password for the bedrock_user"
  recovery_window_in_days = var.vector_db.secret_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "ohio" {
  provider = aws.ohio

  secret_id = aws_secretsmanager_secret.ohio.id
  # The key name must be "apiKey" for the Pinecone Vector Database.
  # for more information, see the following:
  # https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html
  secret_string = jsonencode(
    {
      apiKey = var.vector_db.pinecone_api_key
    }
  )
}

resource "pinecone_index" "ohio" {
  name      = "${local.prefix}-${local.ohio}"
  dimension = local.model_dimension[data.aws_bedrock_foundation_model.embedding_ohio.model_id]

  spec = {
    serverless = {
      cloud  = "aws"
      region = local.virginia # The region where the Pinecone index is created.
    }
  }
}

########################################################
# IAM Role for Knowledge Bases
########################################################
resource "aws_iam_role" "knowledge_bases_ohio" {
  provider = aws.ohio

  name = "${local.prefix}-kb-role-${local.ohio}"
  assume_role_policy = templatefile("./policy/assume_kb.json", {
    region     = local.ohio
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-kb-role-${local.ohio}"
  }
}

resource "aws_iam_policy" "knowledge_bases_ohio" {
  provider = aws.ohio

  name = "${local.prefix}-kb-policy-${local.ohio}"
  /* 
    The policy statement that specifies the permissions for the knowledge base.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html
  */
  policy = templatefile("./policy/iam_kb.json", {
    bucket_arn = module.datasource_ohio.bucket.arn
    account_id = local.account_id
    secret_arn = aws_secretsmanager_secret.ohio.arn
  })

  tags = {
    Name = "${local.prefix}-kb-policy-${local.ohio}"
  }
}

resource "aws_iam_role_policy_attachment" "knowledge_bases_ohio" {
  provider = aws.ohio

  role       = aws_iam_role.knowledge_bases_ohio.name
  policy_arn = aws_iam_policy.knowledge_bases_ohio.arn
}

########################################################
# Knowledge Bases
########################################################
resource "aws_cloudwatch_log_group" "ohio" {
  provider = aws.ohio

  name              = "/aws/vendedlogs/bedrock/knowledge-base/APPLICATION_LOGS/${local.prefix}-knowledge-base-${local.ohio}"
  retention_in_days = 7
}

resource "aws_bedrockagent_knowledge_base" "ohio" {
  provider = aws.ohio

  name     = "${local.prefix}-knowledge-base-${local.ohio}"
  role_arn = aws_iam_role.knowledge_bases_ohio.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding_ohio.model_arn
    }
  }

  storage_configuration {
    type = "PINECONE"
    pinecone_configuration {
      connection_string      = "https://${pinecone_index.ohio.host}"
      credentials_secret_arn = aws_secretsmanager_secret.ohio.arn
      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.knowledge_bases_ohio,
  ]
}

########################################################
# Knowledge Base Data Source
########################################################
resource "aws_bedrockagent_data_source" "ohio" {
  provider = aws.ohio

  name                 = "${local.prefix}-knowledge-base-datasource-${local.ohio}"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.ohio.id
  data_deletion_policy = "DELETE" // "RETAIN"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = module.datasource_ohio.bucket.arn
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
resource "aws_iam_role" "agents_ohio" {
  provider = aws.ohio

  name = "${local.prefix}-agents-role-${local.ohio}"
  assume_role_policy = templatefile("./policy/assume_agent.json", {
    region     = local.ohio
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-agents-role-${local.ohio}"
  }
}

resource "aws_iam_policy" "agents_ohio" {
  provider = aws.ohio

  name = "${local.prefix}-agents-policy-${local.ohio}"
  /* 
    The policy statement that specifies the permissions for the agents.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html
  */
  policy = templatefile("./policy/iam_agent.json", {
    kb_arn     = aws_bedrockagent_knowledge_base.ohio.arn
    secret_arn = aws_secretsmanager_secret.ohio.arn
  })

  tags = {
    Name = "${local.prefix}-agents-policy-${local.ohio}"
  }
}

resource "aws_iam_role_policy_attachment" "agents_ohio" {
  provider = aws.ohio

  role       = aws_iam_role.agents_ohio.name
  policy_arn = aws_iam_policy.agents_ohio.arn
}

########################################################
# Agents
########################################################
resource "aws_bedrockagent_agent" "ohio" {
  provider = aws.ohio

  agent_name              = "${local.prefix}-agents-${local.ohio}"
  agent_resource_role_arn = aws_iam_role.agents_ohio.arn
  foundation_model        = "us.anthropic.claude-3-5-haiku-20241022-v1:0"
  prepare_agent           = true
  instruction             = local.prompt
}

resource "aws_bedrockagent_agent_knowledge_base_association" "ohio" {
  provider = aws.ohio

  agent_id             = aws_bedrockagent_agent.ohio.id
  description          = "Momo Taro Knowledge Base"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.ohio.id
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent_alias" "ohio" {
  provider = aws.ohio

  agent_alias_name = "${local.prefix}-agents-alias-${local.ohio}"
  agent_id         = aws_bedrockagent_agent.ohio.agent_id
  description      = "${local.prefix}-agents-alias-${local.ohio}"

  depends_on = [
    aws_bedrockagent_agent_knowledge_base_association.ohio,
  ]

  lifecycle {
    replace_triggered_by = [
      aws_bedrockagent_agent.ohio,
    ]
  }
}

########################################################
# IAM Role for Flow
########################################################
resource "aws_iam_role" "flows_ohio" {
  provider = aws.ohio

  name = "${local.prefix}-flows-role-${local.ohio}"
  assume_role_policy = templatefile("./policy/assume_agent.json", {
    region     = local.ohio
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-flows-role-${local.ohio}"
  }
}

resource "aws_iam_policy" "flows_ohio" {
  provider = aws.ohio

  name = "${local.prefix}-flows-policy-${local.ohio}"
  /* 
    The policy statement that specifies the permissions for the agents.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html
  */
  policy = templatefile("./policy/iam_flow.json", {
    kb_arn     = aws_bedrockagent_knowledge_base.ohio.arn
    secret_arn = aws_secretsmanager_secret.ohio.arn
  })

  tags = {
    Name = "${local.prefix}-flows-policy-${local.ohio}"
  }
}

resource "aws_iam_role_policy_attachment" "flows_ohio" {
  provider = aws.ohio

  role       = aws_iam_role.flows_ohio.name
  policy_arn = aws_iam_policy.flows_ohio.arn
}
