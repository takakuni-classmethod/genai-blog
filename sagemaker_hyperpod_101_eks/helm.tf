resource "helm_release" "hyperpod_dependencies" {
  name              = "hyperpod-dependencies"
  chart             = "./sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart"
  dependency_update = true
  wait              = false

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_access_entry.this
  ]
}
