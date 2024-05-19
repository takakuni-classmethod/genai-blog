########################################################
# Data Source
########################################################
module "datasource" {
  source = "../modules/datasource"

  prefix = "${local.prefix}-${local.region}"
  datasource = {
    force_destroy = var.datasource.force_destroy
  }
}

########################################################
# Put Object
########################################################
resource "aws_s3_object" "sample_business_plan" {
  # アップロード元(ローカル)
  source = "../サンプルドキュメント/company-wide/2024年度事業計画.md"
  # アップロード先(S3)
  key    = "company-wide/2024年度事業計画.md"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  etag = filemd5("../サンプルドキュメント/company-wide/2024年度事業計画.md")
}

resource "aws_s3_object" "sample_business_plan_metadata" {
  # アップロード元(ローカル)
  source = "../サンプルドキュメント/company-wide/2024年度事業計画.md.metadata.json"
  # アップロード先(S3)
  key    = "company-wide/2024年度事業計画.md.metadata.json"
  bucket = module.datasource.bucket.id

  # エンティティタグ (ファイル更新のトリガーに必要)
  etag = filemd5("../サンプルドキュメント/company-wide/2024年度事業計画.md.metadata.json")
}

########################################################
# Vector Database
#######################################################
resource "pinecone_index" "this" {
  name      = "knowledge-base"
  dimension = 1536
  # dimension = 1024
  spec = {
    serverless = {
      cloud  = "aws"
      region = local.region
    }
  }
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${local.prefix}-vctrdb-secret"
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
  model_id = "amazon.titan-embed-text-v1"
  # model_id = "amazon.titan-embed-text-v1:2:8k"
  # model_id = "amazon.titan-embed-text-v2:0"
  # model_id = "amazon.titan-embed-g1-text-02"
}

########################################################
# IAM Role for Knowledge Bases
########################################################
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
    model_arn  = data.aws_bedrock_foundation_model.embedding.model_arn
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
}
