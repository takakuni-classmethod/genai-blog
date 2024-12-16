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

resource "aws_iam_role_policy_attachment" "hyperpod_s3" {
  role       = aws_iam_role.hyperpod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

data "aws_iam_policy_document" "hyperpod_vpc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DetachNetworkInterface"
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
  name        = "${local.prefix}-hyperpod-vpc-policy"
  description = "IAM policy for SageMaker HyperPod VPC"
  policy      = data.aws_iam_policy_document.hyperpod_vpc.json
}

resource "aws_iam_role_policy_attachment" "hyperpod_vpc" {
  role       = aws_iam_role.hyperpod.name
  policy_arn = aws_iam_policy.hyperpod_vpc.arn
}
