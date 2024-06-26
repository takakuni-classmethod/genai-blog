data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  prefix     = "${var.system}-${var.environment}"
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}
