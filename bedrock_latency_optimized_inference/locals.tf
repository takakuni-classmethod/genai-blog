data "aws_caller_identity" "this" {}

data "aws_region" "virginia" {
  provider = aws.virginia
}

data "aws_region" "oregon" {
  provider = aws.oregon
}

data "aws_region" "ohio" {
  provider = aws.ohio
}

locals {
  prefix     = "ltncy-optmzd-infrnc"
  account_id = data.aws_caller_identity.this.account_id
  oregon     = data.aws_region.oregon.name
  ohio       = data.aws_region.ohio.name
  virginia   = data.aws_region.virginia.name

  model_dimension = {
    "amazon.titan-embed-text-v2:0" = 1024
    "amazon.titan-embed-image-v1"  = 1024
    "amazon.titan-embed-text-v1"   = 1536
    "cohere.embed-multilingual-v3" = 1024
    "cohere.embed-english-v3"      = 1024
  }
}
