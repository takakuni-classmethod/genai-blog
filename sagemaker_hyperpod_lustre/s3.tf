###################################################
# Lifecycle Script Bucket for SageMaker HyperPod Cluster
###################################################
resource "aws_s3_bucket" "life_cycle_scripts" {
  bucket = "${local.prefix}-hyperpod-lifecycle-${local.account_id}"
}

resource "aws_s3_bucket_public_access_block" "life_cycle_scripts" {
  bucket                  = aws_s3_bucket.life_cycle_scripts.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "life_cycle_scripts" {
  bucket = aws_s3_bucket.life_cycle_scripts.bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

###################################################
# Lifecycle Script Objects for SageMaker HyperPod Cluster
###################################################
resource "aws_s3_object" "life_cycle_scripts" {
  for_each = fileset("./config/", "**")
  bucket   = aws_s3_bucket.life_cycle_scripts.bucket
  key      = "config/${each.value}"
  source   = "./config/${each.value}"
}

resource "aws_s3_object" "life_cycle_scripts_provisioning_parameters" {
  bucket = aws_s3_bucket.life_cycle_scripts.bucket
  key    = "config/provisioning_parameters.json"

  content = jsonencode(
    {
      "version"          = "1.0.0"
      "workload_manager" = "slurm"
      "controller_group" = "controller-group"
      "worker_groups"    = []
      "fsx_dns_name"     = aws_fsx_lustre_file_system.this.dns_name
      "fsx_mountname"    = aws_fsx_lustre_file_system.this.mount_name
    }
  )
}
