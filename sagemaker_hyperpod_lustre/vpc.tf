module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "sagemaker-hyperpod"
  cidr = "10.0.0.0/16"

  azs                = ["${local.region}a", "${local.region}c"]
  private_subnets    = ["10.0.1.0/24"]
  public_subnets     = ["10.0.101.0/24"]
  enable_nat_gateway = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = module.vpc.vpc_id
  service_name    = "com.amazonaws.${local.region}.s3"
  route_table_ids = module.vpc.private_route_table_ids
}
