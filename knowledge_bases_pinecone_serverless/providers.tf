terraform {
  required_providers {
    pinecone = {
      source  = "pinecone-io/pinecone"
      version = "0.7.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "0.76.0"
    }
  }
}

provider "pinecone" {
  api_key = var.vector_db.pinecone_api_key
}

provider "aws" {
  region = "us-west-2"
}

provider "awscc" {
  region = "us-west-2"
}

data "aws_region" "this" {}
data "aws_caller_identity" "this" {}

locals {
  region     = data.aws_region.this.name
  account_id = data.aws_caller_identity.this.account_id
}
