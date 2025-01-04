###################################################
# Persistent Volume and Persistent Volume Claim
###################################################
resource "kubernetes_storage_class_v1" "this" {
  metadata {
    name = "fsx-sc"
  }
  storage_provisioner = "fsx.csi.aws.com"
  parameters = {
    "fileSystemId"     = aws_fsx_lustre_file_system.this.id
    "subnetId"         = aws_fsx_lustre_file_system.this.subnet_ids[0]
    "securityGroupIds" = aws_security_group.lustre.id
  }

  depends_on = [
    aws_eks_access_policy_association.this
  ]
}

resource "kubernetes_persistent_volume_v1" "this" {
  metadata {
    name = "fsx-pv"
  }

  spec {
    capacity = {
      storage = "1200Gi"
    }
    access_modes                     = ["ReadWriteMany"]
    volume_mode                      = "Filesystem"
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = kubernetes_storage_class_v1.this.metadata[0].name
    persistent_volume_source {
      csi {
        driver        = "fsx.csi.aws.com"
        volume_handle = aws_fsx_lustre_file_system.this.id
        volume_attributes = {
          dnsname   = aws_fsx_lustre_file_system.this.dns_name
          mountname = aws_fsx_lustre_file_system.this.mount_name
        }
      }
    }
  }

  depends_on = [
    aws_eks_access_policy_association.this
  ]
}

resource "kubernetes_persistent_volume_claim_v1" "this" {
  metadata {
    name = "fsx-claim"
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class_v1.this.metadata[0].name
    resources {
      requests = {
        storage = "1200Gi"
      }
    }
  }

  depends_on = [
    aws_eks_access_policy_association.this,
    kubernetes_persistent_volume_v1.this
  ]
}

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
    kubernetes_persistent_volume_v1.this
  ]
}
