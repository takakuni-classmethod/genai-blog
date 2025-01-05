###################################################
# IAM Role for EKS Cluster
###################################################
resource "aws_iam_role" "eks" {
  name = "${local.prefix}-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

###################################################
# Security Group for EKS Cluster
###################################################
resource "aws_security_group" "eks" {
  name        = "${local.prefix}-eks-sg"
  vpc_id      = module.vpc.vpc_id
  description = "${local.prefix}-eks-sg"

  tags = {
    Name = "${local.prefix}-eks-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_allow_all_traffic_hyperpod" {
  security_group_id            = aws_security_group.eks.id
  referenced_security_group_id = aws_security_group.hyperpod.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "eks_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.eks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

###################################################
# EKS Cluster
###################################################
resource "aws_eks_cluster" "this" {
  name = "${local.prefix}-eks-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.eks.arn
  version  = "1.30"

  vpc_config {
    security_group_ids = [aws_security_group.eks.id]
    subnet_ids         = module.vpc.private_subnets
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
  ]
}

###################################################
# EKS Cluster Access Entries
###################################################
data "aws_iam_session_context" "this" {
  arn = data.aws_caller_identity.self.arn
}

resource "aws_eks_access_entry" "this" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_iam_session_context.this.issuer_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.this.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

###################################################
# EKS Cluster Addons
###################################################
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.19.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}

###################################################
# HyperPod Dependencies
###################################################
resource "helm_release" "hyperpod_dependencies" {
  name              = "hyperpod-dependencies"
  chart             = "./sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart"
  dependency_update = true
  wait              = false

  depends_on = [
    aws_eks_access_policy_association.this
  ]
}
