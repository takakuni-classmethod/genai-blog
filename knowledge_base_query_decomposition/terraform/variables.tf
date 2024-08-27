variable "system_name" {
  type        = string
  description = "The name of the system"
}

variable "environment_name" {
  type        = string
  description = "The name of the environment"
}

variable "vector_db" {
  type = object({
    pinecone_api_key               = string
    secret_recovery_window_in_days = number
  })
  sensitive = true
}

variable "datasource" {
  type = object({
    force_destroy = bool
  })
}
