terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.60.0"
    }
    pinecone = {
      source  = "pinecone-io/pinecone"
      version = "0.7.4"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  # region = "ap-northeast-1"
}
provider "pinecone" {
  api_key = var.vector_db.pinecone_api_key
}

data "aws_region" "this" {}
data "aws_caller_identity" "this" {}

locals {
  prefix     = "${var.system_name}-${var.environment_name}"
  region     = data.aws_region.this.name
  account_id = data.aws_caller_identity.this.account_id

  model_dimension = {
    "amazon.titan-embed-text-v2:0" = 1024
    "amazon.titan-embed-image-v1"  = 1024
    "amazon.titan-embed-text-v1"   = 1536
    "cohere.embed-multilingual-v3" = 1024
    "cohere.embed-english-v3"      = 1024
  }
}
