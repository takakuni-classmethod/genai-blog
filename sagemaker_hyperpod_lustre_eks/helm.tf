resource "helm_release" "hyperpod_dependencies" {
  name              = "hyperpod-dependencies"
  chart             = "./sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart"
  dependency_update = true
  wait              = false

  depends_on = [
    aws_eks_access_policy_association.this
  ]
}

resource "helm_release" "aws_fsx_csi_driver" {
  name              = "aws-fsx-csi-driver"
  repository        = "https://kubernetes-sigs.github.io/aws-fsx-csi-driver"
  chart             = "aws-fsx-csi-driver"
  namespace         = "kube-system"
  dependency_update = true
  wait              = false

  depends_on = [
    aws_eks_access_policy_association.this
  ]
}
