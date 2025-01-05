###################################################
# Hello Sample file
###################################################
resource "aws_s3_object" "hello_from_s3" {
  bucket = aws_s3_bucket.data_repository.bucket
  key    = "training/hello_from_s3.txt"

  content = "hello! from S3!"

  depends_on = [
    kubernetes_pod_v1.this
  ]
}

############################################
# Sample Kubernetes Pod
############################################
resource "kubernetes_pod_v1" "this" {
  metadata {
    name = "s3-app"
  }
  spec {
    container {
      name    = "app"
      image   = "amazon/aws-cli"
      command = ["/bin/sh"]
      args    = ["-c", "echo 'Hello from the container!' >> /data/$(date -u).txt; tail -f /dev/null"]
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
    aws_eks_addon.s3_csi_driver,
    aws_iam_role_policy_attachment.s3_csi_driver
  ]
}
