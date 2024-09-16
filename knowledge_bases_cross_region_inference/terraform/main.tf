########################################################
# Data Source
########################################################
module "datasource" {
  source = "../../modules/datasource"

  prefix = "${local.prefix}-${local.region}"
  datasource = {
    force_destroy = var.datasource.force_destroy
  }
}

########################################################
# Put Object
########################################################
resource "aws_s3_object" "company_wide_bp_2023" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/company-wide/2023年度事業計画.md"
  # アップロード先(S3)
  key    = "company-wide/2023年度事業計画.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/company-wide/2023年度事業計画.md")
}

resource "aws_s3_object" "company_wide_bp_2024" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/company-wide/2024年度事業計画.md"
  # アップロード先(S3)
  key    = "company-wide/2024年度事業計画.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/company-wide/2024年度事業計画.md")
}

resource "aws_s3_object" "company_wide_om" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/company-wide/オフィスの利用方法.md"
  # アップロード先(S3)
  key    = "company-wide/オフィスの利用方法.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/company-wide/オフィスの利用方法.md")
}

resource "aws_s3_object" "company_wide_cr" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/company-wide/就業規則.md"
  # アップロード先(S3)
  key    = "company-wide/就業規則.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/company-wide/就業規則.md")
}

resource "aws_s3_object" "department_en_goal" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/department/engineer/目標設定について.md"
  # アップロード先(S3)
  key    = "department/engineer/目標設定について.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/department/engineer/目標設定について.md")
}

resource "aws_s3_object" "department_sl_goal" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/department/sales/目標設定について.md"
  # アップロード先(S3)
  key    = "department/sales/目標設定について.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/department/sales/目標設定について.md")
}

resource "aws_s3_object" "department_hr_co" {
  # アップロード元(ローカル)
  source = "../../サンプルドキュメント/department/hr/サンプルサンプル株式会社_会社説明資料.pdf"
  # アップロード先(S3)
  key    = "department/hr/サンプルサンプル株式会社_会社説明資料.pdf"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  source_hash = filemd5("../../サンプルドキュメント/department/hr/サンプルサンプル株式会社_会社説明資料.pdf")
}

#######################################################
# Vector Database
#######################################################
resource "pinecone_index" "this" {
  name      = "${local.prefix}-knowledge-base-${local.region}"
  dimension = local.model_dimension[data.aws_bedrock_foundation_model.embedding.model_id]

  spec = {
    serverless = {
      cloud  = "aws"
      region = local.region
    }
  }
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${local.prefix}-vctrdb-secret-${local.account_id}-${local.region}"
  description             = "Password for the bedrock_user"
  recovery_window_in_days = var.vector_db.secret_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  # The key name must be "apiKey" for the Pinecone Vector Database.
  # for more information, see the following:
  # https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html
  secret_string = jsonencode(
    {
      apiKey = var.vector_db.pinecone_api_key
    }
  )
}

########################################################
# Foundation Model
########################################################
data "aws_bedrock_foundation_models" "embedding" {
  by_output_modality = "EMBEDDING"
}

data "aws_bedrock_foundation_model" "embedding" {
  model_id = local.region == "ap-northeast-1" ? "amazon.titan-embed-text-v1" : "amazon.titan-embed-text-v2:0"
}

########################################################
# IAM Role for Knowledge Bases
########################################################
locals {
  claude3_sonnet_model_arn     = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
  claude3_5_sonnet_model_arn   = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
  claude3_sonnet_prorile_arn   = "arn:aws:bedrock:${local.region}:${local.account_id}:inference-profile/us.anthropic.claude-3-sonnet-20240229-v1:0"
  claude3_5_sonnet_prorile_arn = "arn:aws:bedrock:${local.region}:${local.account_id}:inference-profile/us.anthropic.claude-3-5-sonnet-20240620-v1:0"
}

resource "aws_iam_role" "knowledge_bases" {
  name = "${local.prefix}-kb-role"
  assume_role_policy = templatefile("./policy/assume_kb.json", {
    region     = local.region
    account_id = local.account_id
  })
  tags = {
    Name = "${local.prefix}-kb-role"
  }
}

resource "aws_iam_policy" "knowledge_bases" {
  name = "${local.prefix}-kb-policy"
  /* 
    The policy statement that specifies the permissions for the knowledge base.
    For more information, see the following:
    https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html
  */
  policy = templatefile("./policy/iam_kb.json", {
    bucket_arn = module.datasource.bucket.arn
    account_id = local.account_id
    secret_arn = aws_secretsmanager_secret.this.arn
  })

  tags = {
    Name = "${local.prefix}-kb-policy"
  }
}

resource "aws_iam_role_policy_attachment" "knowledge_bases" {
  role       = aws_iam_role.knowledge_bases.name
  policy_arn = aws_iam_policy.knowledge_bases.arn
}

########################################################
# Knowledge Bases
########################################################
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/vendedlogs/bedrock/knowledge-base/APPLICATION_LOGS/${local.prefix}-knowledge-base"
  retention_in_days = 7
}

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "${local.prefix}-knowledge-base"
  role_arn = aws_iam_role.knowledge_bases.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding.model_arn
    }
  }

  storage_configuration {
    type = "PINECONE"
    pinecone_configuration {
      connection_string      = "https://${pinecone_index.this.host}"
      credentials_secret_arn = aws_secretsmanager_secret.this.arn
      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
      }
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.knowledge_bases,
  ]
}

########################################################
# Knowledge Base Data Source
########################################################
resource "aws_bedrockagent_data_source" "this" {
  name                 = "${local.prefix}-knowledge-base-datasource"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  data_deletion_policy = "DELETE" // "RETAIN"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = module.datasource.bucket.arn
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

    parsing_configuration {
      parsing_strategy = "BEDROCK_FOUNDATION_MODEL"
      bedrock_foundation_model_configuration {
        model_arn = local.claude3_sonnet_prorile_arn
      }
    }
  }
}
