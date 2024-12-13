output "life_cycle_scripts_provisioning_parameters" {
  value = aws_s3_object.life_cycle_scripts_provisioning_parameters.content
}

module "slurm_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "5.2.0"
  name                = "sagemaker-hyperpod-slurm"
  vpc_id              = module.vpc.vpc_id
  ingress_rules       = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
}

resource "awscc_sagemaker_cluster" "this" {
  cluster_name = "sagemaker-hyperpod"

  instance_groups = [{
    execution_role      = aws_iam_role.hyperpod.arn
    instance_count      = 1
    instance_group_name = "controller-machine"
    instance_type       = "ml.t3.medium"
    life_cycle_config = {
      source_s3_uri = "s3://${aws_s3_bucket.life_cycle_scripts.id}/config/"
      on_create     = "on_create.sh"
    }
  }]
}
