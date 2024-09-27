terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.68.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_region" "this" {}
data "aws_caller_identity" "this" {}

locals {
  prefix     = "hr-assistant"
  region     = data.aws_region.this.name
  account_id = data.aws_caller_identity.this.account_id
}
