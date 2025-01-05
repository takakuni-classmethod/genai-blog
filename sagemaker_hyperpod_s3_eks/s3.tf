###################################################
# Data Repository
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
# Mountpoint for Amazon S3 CSI Driver at AWS
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
        "system:serviceaccount:kube-system:s3-csi-driver-sa",
      ]
    }
  }
}

resource "aws_iam_role" "s3_csi_driver" {
  name               = "${local.prefix}-s3-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.assume_csi_driver.json
}

data "aws_iam_policy_document" "s3_csi_driver" {
  statement {
    sid = "MountpointFullBucketAccess"
    actions = [
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.data_repository.arn,
    ]
  }
  statement {
    sid = "MountpointFullObjectAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.data_repository.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_csi_driver" {
  name        = "${local.prefix}-s3-csi-driver-policy"
  description = "IAM policy for Amazon S3 CSI Driver"
  policy      = data.aws_iam_policy_document.s3_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "s3_csi_driver" {
  role       = aws_iam_role.s3_csi_driver.name
  policy_arn = aws_iam_policy.s3_csi_driver.arn
}

resource "aws_eks_addon" "s3_csi_driver" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-mountpoint-s3-csi-driver"
  addon_version            = "v1.11.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.s3_csi_driver.arn

  depends_on = [
    aws_iam_role_policy_attachment.s3_csi_driver
  ]
}

###################################################
# Persistent Volume and Persistent Volume Claim
###################################################
resource "kubernetes_persistent_volume_v1" "this" {
  metadata {
    name = "s3-pv"
  }

  spec {
    capacity = {
      storage = "1200Gi" # 設定必須オプションなものの無視される値
    }
    access_modes = ["ReadWriteMany"]
    mount_options = [
      "allow-delete",
      "allow-overwrite",
      "region ${local.region}",
      "prefix training/"
    ]
    persistent_volume_source {
      csi {
        driver        = "s3.csi.aws.com"
        volume_handle = "s3-csi-driver-volume"
        volume_attributes = {
          bucketName = aws_s3_bucket.data_repository.bucket
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
    name = "s3-claim"
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = ""
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
