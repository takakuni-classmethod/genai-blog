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
