############################################
# Sample Kubernetes Pod
############################################
resource "kubernetes_pod_v1" "this" {
  metadata {
    name = "fsx-app"
  }
  spec {
    container {
      name    = "app"
      image   = "centos"
      command = ["/bin/sh"]
      args    = ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]
      volume_mount {
        name       = "persistent-storage"
        mount_path = "/data"
      }
    }
    volume {
      name = "persistent-storage"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim_v1.this.metadata[0].name
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_v1.this,
    awscc_sagemaker_cluster.this,
    aws_iam_role_policy_attachment.fsx_csi_driver,
  ]
}
