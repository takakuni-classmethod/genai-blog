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
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-west-2"
}

provider "awscc" {
  # Configuration options
  region = "us-west-2"
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_caller_identity" "self" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.self.account_id
  region     = data.aws_region.current.name
  prefix     = "hyprpd-tskgvrn"
}
