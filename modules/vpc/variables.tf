variable "prefix" {
  type        = string
  description = "Prefix to be used for all resources"
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
}
