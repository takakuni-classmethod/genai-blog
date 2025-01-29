module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31.6"

  cluster_name                   = "deepseek-inference"
  cluster_version                = "1.32"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
}


output "command" {
  value = <<EOF
aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-east-1
EOF
}
