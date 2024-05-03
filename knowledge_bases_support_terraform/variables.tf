variable "system" {
  type        = string
  description = "The name of the system"
}

variable "environment" {
  type        = string
  description = "The name of the environment"
}

variable "network" {
  type = object({
    vpc_cidr       = string
    subnet_cidr_01 = string
    subnet_cidr_02 = string
    flowlogs = object({
      enabled       = bool
      force_destroy = bool
    })
  })
  description = "The network configuration for the VPC"
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
  })
}

variable "datasource" {
  type = object({
    force_destroy = bool
  })
}

variable "knowledge_bases" {
  type = object({
    /*
    If you don't know the model ID, you can list the available models using the following command:
    aws bedrock list-foundation-models --no-cli-pager \
    --query 'modelSummaries[*].{ModelName:modelName, ModelID:modelId, Input01:inputModalities[0],Input02:inputModalities[1],Input03:inputModalities[2], Output01:outputModalities[0]}' \
    --output table
    */
    embeddings_model_id         = string
    embeddings_model_dimensions = number
  })
  description = "The database configuration for the Knowledge bases for Amazon Bedrock"
}
