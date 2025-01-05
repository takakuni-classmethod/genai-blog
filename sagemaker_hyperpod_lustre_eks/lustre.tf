###################################################
# Security Group for Lustre File System
###################################################
resource "aws_security_group" "lustre" {
  name        = "${local.prefix}-lustre-sg"
  vpc_id      = module.vpc.vpc_id
  description = "${local.prefix}-hyperpod-sg"

  tags = {
    Name = "${local.prefix}-lustre-sg"
  }
}
# Ingress
resource "aws_vpc_security_group_ingress_rule" "lustre_all_traffic_self" {
  security_group_id            = aws_security_group.lustre.id
  referenced_security_group_id = aws_security_group.lustre.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "lustre_all_traffic_hyperpod" {
  security_group_id            = aws_security_group.lustre.id
  referenced_security_group_id = aws_security_group.hyperpod.id
  ip_protocol                  = "-1"
}

# Egress
resource "aws_vpc_security_group_egress_rule" "lustre_all_traffic_self" {
  security_group_id            = aws_security_group.lustre.id
  referenced_security_group_id = aws_security_group.lustre.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "lustre_all_traffic_hyperpod" {
  security_group_id            = aws_security_group.lustre.id
  referenced_security_group_id = aws_security_group.hyperpod.id
  ip_protocol                  = "-1"
}

###################################################
# Data Repository for Lustre File System
###################################################
resource "aws_s3_bucket" "data_repository" {
  bucket        = "${local.prefix}-hyperpod-data-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "data_repository" {
  bucket                  = aws_s3_bucket.data_repository.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data_repository" {
  bucket = aws_s3_bucket.data_repository.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

###################################################
# Lustre File System
###################################################
resource "aws_fsx_lustre_file_system" "this" {
  storage_type                = "SSD"
  file_system_type_version    = "2.15"
  storage_capacity            = 1200
  security_group_ids          = [aws_security_group.lustre.id]
  subnet_ids                  = [module.vpc.private_subnets[0]]
  data_compression_type       = "LZ4"
  deployment_type             = "PERSISTENT_2"
  per_unit_storage_throughput = 250

  metadata_configuration {
    mode = "AUTOMATIC"
  }
}

resource "aws_fsx_data_repository_association" "this" {
  file_system_id       = aws_fsx_lustre_file_system.this.id
  data_repository_path = "s3://${aws_s3_bucket.data_repository.bucket}"
  file_system_path     = "/"

  s3 {
    auto_export_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }

    auto_import_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }
  }
}

###################################################
# Hello Sample file
###################################################
resource "aws_s3_object" "hello_from_s3" {
  bucket = aws_s3_bucket.data_repository.bucket
  key    = "hello_from_s3.txt"

  content = "hello! from S3!"

  depends_on = [aws_fsx_data_repository_association.this]
}

###################################################
# FSx CSI Driver
###################################################
data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
  depends_on = [
    aws_eks_cluster.this
  ]
}

resource "aws_iam_openid_connect_provider" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.this.certificates[0].sha1_fingerprint
  ]
}

data "aws_iam_policy_document" "assume_csi_driver" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:aud"
      values = [
        "sts.amazonaws.com",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.this.url}:sub"
      values = [
        "system:serviceaccount:kube-system:fsx-csi-controller-sa",
      ]
    }
  }
}

resource "aws_iam_role" "fsx_csi_driver" {
  name = "${local.prefix}-fsx-csi-driver-role"

  assume_role_policy = data.aws_iam_policy_document.assume_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "fsx_csi_driver" {
  role       = aws_iam_role.fsx_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonFSxFullAccess"
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

data "kubernetes_service_account_v1" "this" {
  metadata {
    name      = "fsx-csi-controller-sa"
    namespace = "kube-system"
  }

  depends_on = [
    helm_release.aws_fsx_csi_driver,
    aws_eks_access_policy_association.this
  ]
}

resource "kubernetes_annotations" "this" {
  api_version = "v1"
  kind        = "ServiceAccount"

  metadata {
    name      = data.kubernetes_service_account_v1.this.metadata[0].name
    namespace = data.kubernetes_service_account_v1.this.metadata[0].namespace
  }

  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.fsx_csi_driver.arn
  }

  depends_on = [
    aws_eks_access_policy_association.this
  ]
}

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
