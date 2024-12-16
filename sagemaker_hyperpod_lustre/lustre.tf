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
}
