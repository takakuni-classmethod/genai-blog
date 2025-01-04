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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
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
  # region = "ap-northeast-1"
}

provider "awscc" {
  # Configuration options
  region = "us-west-2"
  # region = "ap-northeast-1"
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token

    # exec {
    #   api_version = "client.authentication.k8s.io/v1beta1"
    #   args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name]
    #   command     = "aws"
    # }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token

  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.this.name]
  #   command     = "aws"
  # }
}

data "aws_caller_identity" "self" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.self.account_id
  region     = data.aws_region.current.name
  prefix     = "hyprpd-eks"
}
