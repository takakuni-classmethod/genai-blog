output "upgate_config" {
  value = <<EOT
aws eks update-kubeconfig \
  --region ${local.region} \
  --name ${aws_eks_cluster.this.name}
EOT
}
