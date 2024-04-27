########################################################
# VPC
########################################################
module "network" {
  source  = "../modules/vpc"
  prefix  = local.prefix
  network = var.network
}

########################################################
# Vector Database
########################################################
resource "random_password" "vector_db" {
  length = 16
}

module "vector_db" {
  source = "../modules/vector_db"
  prefix = local.prefix
  vector_db = merge(var.vector_db, {
    db_password = random_password.vector_db.result
  })
  network = {
    vpc              = module.network.vpc
    public_subnet_01 = module.network.public_subnet_01
    public_subnet_02 = module.network.public_subnet_02
  }
  embeddings = {
    model_dimensions = var.knowledge_bases.embeddings_model_dimensions
  }
  secret = {
    recovery_window_in_days = var.secret.recovery_window_in_days
    password                = random_password.vector_db.result
  }
}

########################################################
# Data Source
########################################################
module "datasource" {
  source = "../modules/datasource"

  prefix = local.prefix
  datasource = {
    force_destroy = var.datasource.force_destroy
  }
}

########################################################
# IAM Role for Knowledge Bases
########################################################
data "aws_bedrock_foundation_model" "embedding" {
  model_id = var.knowledge_bases.embeddings_model_id
}

resource "aws_iam_role" "knowledge_bases" {
  name               = "${local.prefix}-kb-role"
  assume_role_policy = file("./policy/assume_kb.json")
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
    model_arn      = data.aws_bedrock_foundation_model.embedding.model_arn
    bucket_arn     = module.datasource.bucket.arn
    account_id     = local.account_id
    db_cluster_arn = module.vector_db.cluster.arn
    secret_arn     = module.vector_db.secrets.arn
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
  name     = "${local.prefix}-kb"
  role_arn = aws_iam_role.knowledge_bases.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = data.aws_bedrock_foundation_model.embedding.model_arn
    }
  }

  storage_configuration {
    type = "RDS"
    rds_configuration {
      credentials_secret_arn = module.vector_db.secrets.arn
      database_name          = module.vector_db.cluster.database_name
      resource_arn           = module.vector_db.cluster.arn
      table_name             = "bedrock_integration.bedrock_kb"
      field_mapping {
        primary_key_field = "id"
        vector_field      = "embedding"
        text_field        = "chunks"
        metadata_field    = "metadata"
      }
    }
  }
}

########################################################
# Knowledge Base Data Source
########################################################
resource "awscc_bedrock_data_source" "this" {
  name              = local.prefix
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  data_source_configuration = {
    type = "S3"
    s3_configuration = {
      bucket_arn = module.datasource.bucket.arn
    }
  }
}
