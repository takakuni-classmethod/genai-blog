system      = "takakuni"
environment = "dev"

########################################################
# VPC
########################################################
network = {
  vpc_cidr       = "10.0.0.0/16"
  subnet_cidr_01 = "10.0.0.0/24"
  subnet_cidr_02 = "10.0.1.0/24"
  flowlogs = {
    enabled       = false
    force_destroy = true # For testing purposes only
  }
}

########################################################
# Vector Database
########################################################
vector_db = {
  multi_az                    = false
  engine_name                 = "aurora-postgresql"
  engine_family               = "aurora-postgresql15"
  database_name               = "postgresql"
  master_username             = "kb_admin"
  manage_master_user_password = true
  port                        = 5432

  postgresql_logs = {
    enabled           = true
    retention_in_days = 7 # For testing purposes only
  }

  enhanced_monitoring = {
    enabled = true
  }

  performance_insights = {
    enabled          = true
    retention_period = 7 # For testing purposes only
  }

  operating_window = {
    preferred_backup                  = "17:00-17:30"
    preferred_cluster_maintenance     = "sun:18:00-sun:18:30"
    preferred_instance_01_maintenance = "sun:19:00-sun:19:30"
    preferred_instance_02_maintenance = "sun:20:00-sun:20:30"
  }

  scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 1
  }

  deletion_protection        = false # For testing purposes only
  skip_final_snapshot        = true  # For testing purposes only
  apply_immediately          = true  # For testing purposes only
  auto_minor_version_upgrade = true
}

secret = {
  recovery_window_in_days = 7 # For testing purposes only
}

########################################################
# Data Source
########################################################
datasource = {
  force_destroy = true # For testing purposes only
}

########################################################
# Knowledge Bases
########################################################
knowledge_bases = {
  embeddings_model_id         = "cohere.embed-multilingual-v3"
  embeddings_model_dimensions = 1024
}