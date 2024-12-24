terraform {
  required_providers {
    pinecone = {
      source  = "pinecone-io/pinecone"
      version = "0.8.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
  }
}

provider "pinecone" {
  api_key = var.vector_db.pinecone_api_key
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

provider "aws" {
  alias  = "ohio"
  region = "us-east-2"
}

provider "aws" {
  alias  = "oregon"
  region = "us-west-2"
}
