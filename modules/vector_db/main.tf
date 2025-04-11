########################################################
# Security Group
########################################################
resource "aws_security_group" "this" {
  name        = "${var.prefix}-kb-vctrdb-sg"
  vpc_id      = var.network.vpc.id
  description = "Security group for the Vector Database"
  tags = {
    Name = "${var.prefix}-kb-vctrdb-sg"
  }
}

########################################################
# Subnet Group
########################################################
resource "aws_db_subnet_group" "this" {
  name = "${var.prefix}-kb-vctrdb-sbntgrp"
  subnet_ids = [
    var.network.private_subnet_01.id,
    var.network.private_subnet_02.id,
  ]

  tags = {
    Name = "${var.prefix}-kb-vctrdb-sbntgrp"
  }
}

########################################################
# Parameter Group
########################################################
resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.prefix}-kb-vctrdb-clstrprmgrp"
  family      = var.vector_db.engine_family
  description = "Parameter group for Aurora Cluser"
}
resource "aws_db_parameter_group" "this" {
  name        = "${var.prefix}-kb-vctrdb-instnsprmgrp"
  family      = var.vector_db.engine_family
  description = "Parameter group for Aurora Instance"
}

########################################################
# CloudWatch Log Group
########################################################
resource "aws_cloudwatch_log_group" "this" {
  count = var.vector_db.postgresql_logs.enabled ? 1 : 0

  name              = "/aws/rds/cluster/${var.prefix}-kb-vctrdb/postgresql"
  retention_in_days = var.vector_db.postgresql_logs.retention_in_days
}

########################################################
# IAM Role for Aurora
########################################################
resource "aws_iam_role" "this" {
  count = var.vector_db.enhanced_monitoring.enabled ? 1 : 0

  name               = "${var.prefix}-kb-vctrdb-role"
  assume_role_policy = file("${path.module}/policy/assume_rds_monitoring.json")

  tags = {
    Name = "${var.prefix}-kb-vctrdb-role"
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count = var.vector_db.enhanced_monitoring.enabled ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

########################################################
# Aurora Cluster
########################################################
resource "aws_rds_cluster" "this" {
  cluster_identifier               = "${var.prefix}-vctrdb-cluster"
  engine                           = var.vector_db.engine_name
  preferred_backup_window          = var.vector_db.operating_window.preferred_backup
  preferred_maintenance_window     = var.vector_db.operating_window.preferred_cluster_maintenance
  database_name                    = var.vector_db.database_name
  port                             = var.vector_db.port
  vpc_security_group_ids           = [aws_security_group.this.id]
  db_subnet_group_name             = aws_db_subnet_group.this.name
  enable_http_endpoint             = true
  storage_encrypted                = true
  master_username                  = var.vector_db.master_username
  manage_master_user_password      = var.vector_db.manage_master_user_password
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.this.name
  db_instance_parameter_group_name = aws_db_parameter_group.this.name
  enabled_cloudwatch_logs_exports  = var.vector_db.postgresql_logs.enabled ? ["postgresql"] : null

  serverlessv2_scaling_configuration {
    min_capacity = var.vector_db.scaling_configuration.min_capacity
    max_capacity = var.vector_db.scaling_configuration.max_capacity
  }

  deletion_protection = var.vector_db.deletion_protection
  skip_final_snapshot = var.vector_db.skip_final_snapshot
  apply_immediately   = var.vector_db.apply_immediately

  tags = {
    Name = "${var.prefix}-vector-db"
  }
}

########################################################
# Secrets Manager for bedrock_user ROLE
########################################################
resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.prefix}-kb-vctrdb-secret"
  description             = "Password for the bedrock_user role"
  recovery_window_in_days = var.secret.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(
    {
      username = "bedrock_user"
      password = var.secret.password
    }
  )
}

########################################################
# Aurora Instance
########################################################
resource "aws_rds_cluster_instance" "this_01" {
  identifier                            = "${var.prefix}-vctrdb-instance-01"
  cluster_identifier                    = aws_rds_cluster.this.id
  instance_class                        = "db.serverless"
  engine                                = aws_rds_cluster.this.engine
  availability_zone                     = "${local.region}a"
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  db_parameter_group_name               = aws_db_parameter_group.this.name
  db_subnet_group_name                  = aws_db_subnet_group.this.name
  monitoring_interval                   = var.vector_db.enhanced_monitoring.enabled ? 60 : null
  monitoring_role_arn                   = var.vector_db.enhanced_monitoring.enabled ? aws_iam_role.this[0].arn : null
  preferred_maintenance_window          = var.vector_db.operating_window.preferred_instance_01_maintenance
  performance_insights_enabled          = var.vector_db.performance_insights.enabled
  performance_insights_retention_period = var.vector_db.performance_insights.retention_period
  auto_minor_version_upgrade            = var.vector_db.auto_minor_version_upgrade
  apply_immediately                     = var.vector_db.apply_immediately

  lifecycle {
    ignore_changes = [engine_version]
  }
  tags = {
    Name = "${var.prefix}-vctrdb-instance-01"
  }
}

resource "aws_rds_cluster_instance" "this_02" {
  count = var.vector_db.multi_az ? 1 : 0

  identifier                            = "${var.prefix}-vctrdb-instance-02"
  cluster_identifier                    = aws_rds_cluster.this.id
  instance_class                        = "db.serverless"
  engine                                = aws_rds_cluster.this.engine
  availability_zone                     = "${local.region}c"
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  db_parameter_group_name               = aws_db_parameter_group.this.name
  db_subnet_group_name                  = aws_db_subnet_group.this.name
  monitoring_interval                   = var.vector_db.enhanced_monitoring.enabled ? 60 : null
  monitoring_role_arn                   = var.vector_db.enhanced_monitoring.enabled ? aws_iam_role.this[0].arn : null
  preferred_maintenance_window          = var.vector_db.operating_window.preferred_instance_02_maintenance
  performance_insights_enabled          = var.vector_db.performance_insights.enabled
  performance_insights_retention_period = var.vector_db.performance_insights.retention_period
  auto_minor_version_upgrade            = var.vector_db.auto_minor_version_upgrade
  apply_immediately                     = var.vector_db.apply_immediately

  lifecycle {
    ignore_changes = [engine_version]
  }
  tags = {
    Name = "${var.prefix}-vctrdb-instance-02"
  }
}

########################################################
# Setup Vector Database
########################################################
resource "terraform_data" "setup_vector_db" {
  triggers_replace = [
    aws_rds_cluster.this.id
  ]

  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html
  # Install pgvector and check the version
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/01_install_pgvector.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.this.arn
      SECRET_ARN    = aws_rds_cluster.this.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.this.database_name
    }
  }

  # Create a specific schema that Bedrock can use to query the data
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/02_create_schema.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.this.arn
      SECRET_ARN    = aws_rds_cluster.this.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.this.database_name
    }
  }

  # Create a new role that Bedrock can use to query the database
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/03_create_role.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.this.arn
      SECRET_ARN    = aws_rds_cluster.this.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.this.database_name
      ROLE_NAME     = "bedrock_user"
      PASSWORD      = var.secret.password
    }
  }

  # Grant the bedrock_user permission to manage the bedrock_integration schema
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/04_grant_schema.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.this.arn
      SECRET_ARN    = aws_rds_cluster.this.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.this.database_name
      ROLE_NAME     = "bedrock_user"
    }
  }

  # Login as the bedrock_user and create a table in the bedrock_integration schema
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/05_create_table.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION              = local.region
      CLUSTER_ARN         = aws_rds_cluster.this.arn
      SECRET_ARN          = aws_secretsmanager_secret.this.arn
      DATABASE_NAME       = aws_rds_cluster.this.database_name
      EMBEDDING_DIMENSION = var.embeddings.model_dimensions
    }
  }

  # Create an index with the cosine operator which the bedrock can use to query the data.
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/06_create_vector_index.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.this.arn
      SECRET_ARN    = aws_secretsmanager_secret.this.arn
      DATABASE_NAME = aws_rds_cluster.this.database_name
    }
  }

  # Create an index with the cosine operator which the bedrock can use to query the data.
  provisioner "local-exec" {
    command     = "bash ./setup_vector_db/07_create_text_index.sh"
    working_dir = "${path.module}/scripts"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.this.arn
      SECRET_ARN    = aws_secretsmanager_secret.this.arn
      DATABASE_NAME = aws_rds_cluster.this.database_name
    }
  }

  # Writer instance will start and execute the SQL statement
  depends_on = [aws_rds_cluster_instance.this_01]
}
