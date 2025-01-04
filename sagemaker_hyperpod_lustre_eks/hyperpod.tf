###################################################
# IAM Role for SageMaker HyperPod Cluster
###################################################
resource "aws_iam_role" "hyperpod" {
  name = "${local.prefix}-hyperpod-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sagemaker.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "hyperpod_managed" {
  role       = aws_iam_role.hyperpod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerClusterInstanceRolePolicy"
}

data "aws_iam_policy_document" "hyperpod_vpc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses",
      "ecr:BatchGetImage",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "eks-auth:AssumeRoleForPodIdentity"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["arn:aws:ec2:*:*:network-interface/*"]
  }
}

resource "aws_iam_policy" "hyperpod_vpc" {
  name        = "${local.prefix}-vpc-policy"
  description = "IAM policy for SageMaker HyperPod VPC"
  policy      = data.aws_iam_policy_document.hyperpod_vpc.json
}

resource "aws_iam_role_policy_attachment" "hyperpod_vpc" {
  role       = aws_iam_role.hyperpod.name
  policy_arn = aws_iam_policy.hyperpod_vpc.arn
}

data "aws_iam_policy_document" "hyperpod_lifecycle" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      aws_s3_bucket.life_cycle_scripts.arn,
      "${aws_s3_bucket.life_cycle_scripts.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "hyperpod_lifecycle" {
  name        = "${local.prefix}-lifecycle-policy"
  description = "IAM policy for SageMaker HyperPod Lifecycle Scripts"
  policy      = data.aws_iam_policy_document.hyperpod_lifecycle.json
}

resource "aws_iam_role_policy_attachment" "hyperpod_lifecycle" {
  role       = aws_iam_role.hyperpod.name
  policy_arn = aws_iam_policy.hyperpod_lifecycle.arn
}

###################################################
# Security Group for SageMaker HyperPod Cluster
###################################################
resource "aws_security_group" "hyperpod" {
  name        = "${local.prefix}-hyperpod-sg"
  vpc_id      = module.vpc.vpc_id
  description = "${local.prefix}-hyperpod-sg"

  tags = {
    Name = "${local.prefix}-hyperpod-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "hyperpod_allow_all_traffic_ipv4" {
  security_group_id            = aws_security_group.hyperpod.id
  referenced_security_group_id = aws_security_group.hyperpod.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "hyperpod_allow_all_traffic_eks" {
  security_group_id            = aws_security_group.hyperpod.id
  referenced_security_group_id = aws_security_group.eks.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "hyperpod_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.hyperpod.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "hyperpod_allow_all_traffic_self" {
  security_group_id            = aws_security_group.hyperpod.id
  referenced_security_group_id = aws_security_group.hyperpod.id
  ip_protocol                  = "-1"
}

###################################################
# SageMaker HyperPod Cluster
###################################################
resource "awscc_sagemaker_cluster" "this" {
  cluster_name = "${local.prefix}-hyperpod-cluster"

  orchestrator = {
    eks = {
      cluster_arn = aws_eks_cluster.this.arn
    }
  }

  vpc_config = {
    security_group_ids = [aws_security_group.hyperpod.id]
    subnets            = [module.vpc.private_subnets[0]]
  }

  node_recovery = "Automatic" # Automatic | None 
  # https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreateCluster.html#sagemaker-CreateCluster-request-NodeRecovery

  instance_groups = [
    {
      execution_role      = aws_iam_role.hyperpod.arn
      instance_count      = 2
      instance_group_name = "worker-group"
      instance_type       = "ml.g5.xlarge"
      life_cycle_config = {
        source_s3_uri = "s3://${aws_s3_bucket.life_cycle_scripts.id}/config/"
        on_create     = "on_create.sh"
      }
      instance_storage_configs = [{
        ebs_volume_config = {
          volume_size_in_gb = 500
        }
      }]
    },
  ]

  depends_on = [
    aws_iam_role_policy_attachment.hyperpod_vpc,
    aws_iam_role_policy_attachment.hyperpod_lifecycle,
    aws_vpc_endpoint.s3,
    helm_release.hyperpod_dependencies
  ]
}
