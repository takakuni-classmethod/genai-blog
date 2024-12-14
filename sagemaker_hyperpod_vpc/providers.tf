terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.23.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "ap-northeast-1"
}

provider "awscc" {
  # Configuration options
  region = "ap-northeast-1"
}

data "aws_caller_identity" "self" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.self.account_id
  region     = data.aws_region.current.name
}
