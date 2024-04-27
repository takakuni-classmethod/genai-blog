variable "prefix" {
  type        = string
  description = "Prefix to be used for all resources"
}

variable "network" {
  type = object({
    vpc = object({
      id = string
    })
    private_subnet_01 = object({
      id = string
    })
    private_subnet_02 = object({
      id = string
    })
  })
}

variable "vector_db" {
  type = object({
    multi_az                    = bool
    engine_name                 = string
    engine_family               = string
    database_name               = string
    master_username             = string
    manage_master_user_password = bool
    port                        = number

    postgresql_logs = object({
      enabled           = bool
      retention_in_days = number
    })

    enhanced_monitoring = object({
      enabled = bool
    })

    performance_insights = object({
      enabled          = bool
      retention_period = number
    })

    operating_window = object({
      preferred_backup                  = string
      preferred_cluster_maintenance     = string
      preferred_instance_01_maintenance = string
      preferred_instance_02_maintenance = string
    })

    scaling_configuration = object({
      max_capacity = number
      min_capacity = number
    })

    deletion_protection        = bool
    skip_final_snapshot        = bool
    apply_immediately          = bool
    auto_minor_version_upgrade = bool
  })
  description = "The database configuration for the Aurora Cluster"
}

variable "secret" {
  type = object({
    recovery_window_in_days = number
    password                = string
  })
  sensitive   = true
  description = "The password for the bedrock_user role"
}

variable "embeddings" {
  type = object({
    model_dimensions = number
  })
}
