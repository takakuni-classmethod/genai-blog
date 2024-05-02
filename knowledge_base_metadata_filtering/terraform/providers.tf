terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.47.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "0.75.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "awscc" {
  region = "us-west-2"
}
