module "luster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"
  name    = "sagemaker-hyperpod-luster"
  vpc_id  = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 988
      to_port     = 988
      protocol    = "tcp"
      description = "Lustre FSx"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 1018
      to_port     = 1023
      protocol    = "tcp"
      description = "Lustre FSx"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
}

# resource "aws_fsx_lustre_file_system" "this" {
#   storage_capacity            = 1200
#   storage_type                = "SSD"
#   file_system_type_version    = "2.15"
#   security_group_ids          = [module.luster_sg.security_group_id]
#   subnet_ids                  = [module.vpc.private_subnets[0]]
#   data_compression_type       = "LZ4"
#   deployment_type             = "PERSISTENT_2"
#   per_unit_storage_throughput = 250
#   metadata_configuration {
#     mode = "AUTOMATIC"
#   }
# }
