########################################################
# Data Source
########################################################
module "datasource_virginia" {
  providers = {
    aws = aws.virginia
  }
  source = "../modules/datasource"

  prefix = "${local.prefix}-${local.virginia}"
  datasource = {
    force_destroy = var.datasource.force_destroy
  }
}

########################################################
# Put Object
########################################################
resource "aws_s3_object" "momotarou_chapter1_virginia" {
  provider = aws.virginia

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt"
  # アップロード先(S3)
  key    = "桃太郎第1章.txt"
  bucket = module.datasource_virginia.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第1章.txt")
}

resource "aws_s3_object" "momotarou_chapter2_virginia" {
  provider = aws.virginia

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt"
  # アップロード先(S3)
  key    = "桃太郎第2章.txt"
  bucket = module.datasource_virginia.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第2章.txt")
}

resource "aws_s3_object" "momotarou_chapter3_virginia" {
  provider = aws.virginia

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt"
  # アップロード先(S3)
  key    = "桃太郎第3章.txt"
  bucket = module.datasource_virginia.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第3章.txt")
}

resource "aws_s3_object" "momotarou_chapter4_virginia" {
  provider = aws.virginia

  # アップロード元(ローカル)
  source = "../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt"
  # アップロード先(S3)
  key    = "桃太郎第4章.txt"
  bucket = module.datasource_virginia.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../サンプルドキュメント/semantic-chunking/桃太郎第4章.txt")
}

########################################################
# Foundation Model
########################################################
data "aws_bedrock_foundation_models" "embedding_virginia" {
  provider = aws.virginia

  by_output_modality = "EMBEDDING"
}

data "aws_bedrock_foundation_model" "embedding_virginia" {
  provider = aws.virginia

  model_id = "amazon.titan-embed-text-v2:0"
}

#######################################################
# Vector Database
#######################################################
resource "aws_secretsmanager_secret" "virginia" {
  provider = aws.virginia

  name_prefix             = "${local.prefix}-pinecone"
  description             = "Password for the bedrock_user"
  recovery_window_in_days = var.vector_db.secret_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "virginia" {
  provider = aws.virginia

  secret_id = aws_secretsmanager_secret.virginia.id
  # The key name must be "apiKey" for the Pinecone Vector Database.
  # for more information, see the following:
  # https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html
  secret_string = jsonencode(
    {
      apiKey = var.vector_db.pinecone_api_key
    }
  )
}

resource "pinecone_index" "virginia" {
  name      = "${local.prefix}-${local.virginia}"
  dimension = local.model_dimension[data.aws_bedrock_foundation_model.embedding_virginia.model_id]

  spec = {
    serverless = {
      cloud  = "aws"
      region = local.virginia
    }
  }
}

########################################################
# IAM Role for Knowledge Bases
########################################################
resource "aws_iam_role" "knowledge_bases_virginia" {
  provider = aws.virginia

  name = "${local.prefix}-kb-role-${local.virginia}"
  assume_role_policy = templatefile("./policy/assume_kb.json", {
    region     = local.virginia
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-kb-role-${local.virginia}"
  }
}

resource "aws_iam_policy" "knowledge_bases_virginia" {
  provider = aws.virginia

  name = "${local.prefix}-kb-policy-${local.virginia}"
  /* 
    The policy statement that specifies the permissions for the knowledge base.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html
  */
  policy = templatefile("./policy/iam_kb.json", {
    bucket_arn = module.datasource_virginia.bucket.arn
    account_id = local.account_id
    secret_arn = aws_secretsmanager_secret.virginia.arn
  })

  tags = {
    Name = "${local.prefix}-kb-policy-${local.virginia}"
  }
}

resource "aws_iam_role_policy_attachment" "knowledge_bases_virginia" {
  provider = aws.virginia

  role       = aws_iam_role.knowledge_bases_virginia.name
  policy_arn = aws_iam_policy.knowledge_bases_virginia.arn
}

########################################################
# Knowledge Bases
########################################################
resource "aws_cloudwatch_log_group" "virginia" {
  provider = aws.virginia

  name              = "/aws/vendedlogs/bedrock/knowledge-base/APPLICATION_LOGS/${local.prefix}-knowledge-base-${local.virginia}"
  retention_in_days = 7
}

resource "aws_bedrockagent_knowledge_base" "virginia" {
  provider = aws.virginia

  name     = "${local.prefix}-knowledge-base-${local.virginia}"
  role_arn = aws_iam_role.knowledge_bases_virginia.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding_virginia.model_arn
    }
  }

  storage_configuration {
    type = "PINECONE"
    pinecone_configuration {
      connection_string      = "https://${pinecone_index.virginia.host}"
      credentials_secret_arn = aws_secretsmanager_secret.virginia.arn
      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.knowledge_bases_virginia,
  ]
}

########################################################
# Knowledge Base Data Source
########################################################
resource "aws_bedrockagent_data_source" "virginia" {
  provider = aws.virginia

  name                 = "${local.prefix}-knowledge-base-datasource-${local.virginia}"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.virginia.id
  data_deletion_policy = "DELETE" // "RETAIN"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = module.datasource_virginia.bucket.arn
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
resource "aws_iam_role" "agents_virginia" {
  provider = aws.virginia

  name = "${local.prefix}-agents-role-${local.virginia}"
  assume_role_policy = templatefile("./policy/assume_agent.json", {
    region     = local.virginia
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-agents-role-${local.virginia}"
  }
}

resource "aws_iam_policy" "agents_virginia" {
  provider = aws.virginia

  name = "${local.prefix}-agents-policy-${local.virginia}"
  /* 
    The policy statement that specifies the permissions for the agents.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html
  */
  policy = templatefile("./policy/iam_agent.json", {
    kb_arn     = aws_bedrockagent_knowledge_base.virginia.arn
    secret_arn = aws_secretsmanager_secret.virginia.arn
  })

  tags = {
    Name = "${local.prefix}-agents-policy-${local.virginia}"
  }
}

resource "aws_iam_role_policy_attachment" "agents_virginia" {
  provider = aws.virginia

  role       = aws_iam_role.agents_virginia.name
  policy_arn = aws_iam_policy.agents_virginia.arn
}

########################################################
# Agents
########################################################
resource "aws_bedrockagent_agent" "virginia" {
  provider = aws.virginia

  agent_name              = "${local.prefix}-agents-${local.virginia}"
  agent_resource_role_arn = aws_iam_role.agents_virginia.arn
  foundation_model        = "us.anthropic.claude-3-5-haiku-20241022-v1:0"
  prepare_agent           = true
  instruction             = local.prompt
}

resource "aws_bedrockagent_agent_knowledge_base_association" "virginia" {
  provider = aws.virginia

  agent_id             = aws_bedrockagent_agent.virginia.id
  description          = "Momo Taro Knowledge Base"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.virginia.id
  knowledge_base_state = "ENABLED"
}

resource "aws_bedrockagent_agent_alias" "virginia" {
  provider = aws.virginia

  agent_alias_name = "${local.prefix}-agents-alias-${local.virginia}"
  agent_id         = aws_bedrockagent_agent.virginia.agent_id
  description      = "${local.prefix}-agents-alias-${local.virginia}"

  depends_on = [
    aws_bedrockagent_agent_knowledge_base_association.virginia,
  ]

  lifecycle {
    replace_triggered_by = [
      aws_bedrockagent_agent.virginia,
    ]
  }
}

########################################################
# IAM Role for Flow
########################################################
resource "aws_iam_role" "flows_virginia" {
  provider = aws.virginia

  name = "${local.prefix}-flows-role-${local.virginia}"
  assume_role_policy = templatefile("./policy/assume_agent.json", {
    region     = local.virginia
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-flows-role-${local.virginia}"
  }
}

resource "aws_iam_policy" "flows_virginia" {
  provider = aws.virginia

  name = "${local.prefix}-flows-policy-${local.virginia}"
  /* 
    The policy statement that specifies the permissions for the agents.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/agents-permissions.html
  */
  policy = templatefile("./policy/iam_flow.json", {
    kb_arn     = aws_bedrockagent_knowledge_base.virginia.arn
    secret_arn = aws_secretsmanager_secret.virginia.arn
  })

  tags = {
    Name = "${local.prefix}-flows-policy-${local.virginia}"
  }
}

resource "aws_iam_role_policy_attachment" "flows_virginia" {
  provider = aws.virginia

  role       = aws_iam_role.flows_virginia.name
  policy_arn = aws_iam_policy.flows_virginia.arn
}
