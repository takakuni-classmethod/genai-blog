###################################################
# Security Group for SageMaker HyperPod Cluster
###################################################
resource "aws_security_group" "hyperpod" {
  name        = "sagemaker-hyperpod-sg"
  vpc_id      = module.vpc.vpc_id
  description = "sagemaker-hyperpod-sg"

  tags = {
    Name = "sagemaker-hyperpod-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_ipv4" {
  security_group_id            = aws_security_group.hyperpod.id
  referenced_security_group_id = aws_security_group.hyperpod.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.hyperpod.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

###################################################
# SageMaker HyperPod Cluster
###################################################
resource "awscc_sagemaker_cluster" "this" {
  cluster_name = "sagemaker-hyperpod"

  instance_groups = [
    {
      execution_role      = aws_iam_role.hyperpod.arn
      instance_count      = 1
      instance_group_name = "controller-group"
      instance_type       = "ml.t3.medium"
      life_cycle_config = {
        source_s3_uri = "s3://${aws_s3_bucket.life_cycle_scripts.id}/config/"
        on_create     = "on_create.sh"
      }
    },
    # {
    #   execution_role      = aws_iam_role.hyperpod.arn
    #   instance_count      = 2
    #   instance_group_name = "worker-group"
    #   instance_type       = "ml.t3.medium"
    #   life_cycle_config = {
    #     source_s3_uri = "s3://${aws_s3_bucket.life_cycle_scripts.id}/config/"
    #     on_create     = "on_create.sh"
    #   }
    # }
  ]

  vpc_config = {
    security_group_ids = [aws_security_group.hyperpod.id]
    subnets            = [module.vpc.private_subnets[0]]
  }

  depends_on = [
    aws_iam_role_policy_attachment.hyperpod_vpc,
    aws_vpc_endpoint.s3
  ]
}
