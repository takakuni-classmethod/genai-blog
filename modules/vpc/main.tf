########################################################
# VPC
########################################################
resource "aws_vpc" "this" {
  cidr_block           = var.network.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-kb-vpc"
  }
}

########################################################
# Internet Gateway
########################################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-kb-igw"
  }
}

########################################################
# Route Table
########################################################
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-kb-rtb"
  }
}

resource "aws_route" "this" {
  route_table_id         = aws_route_table.this.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

########################################################
# Subnet
########################################################
resource "aws_subnet" "public_01" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.network.subnet_cidr_01
  availability_zone = "${local.region}a"

  tags = {
    Name = "${var.prefix}-kb-public-subnet-01"
  }
}
resource "aws_route_table_association" "public_01" {
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.public_01.id
}

resource "aws_subnet" "public_02" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.network.subnet_cidr_02
  availability_zone = "${local.region}c"

  tags = {
    Name = "${var.prefix}-kb-public-subnet-02"
  }
}
resource "aws_route_table_association" "public_02" {
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.public_02.id
}

########################################################
# VPC Flow Logs
########################################################
resource "aws_s3_bucket" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  bucket        = "${var.prefix}-kb-flowlogs-${local.account_id}"
  force_destroy = var.network.flowlogs.force_destroy
  tags = {
    Name = "${var.prefix}-kb-flowlogs-${local.account_id}"
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket
  /*
  for more information on the policy, see:
  https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/flow-logs-s3.html#flow-logs-s3-permissions
  */
  policy = templatefile("${path.module}/policy/bucket_flowlog.json", {
    bucket_arn = aws_s3_bucket.this[0].arn
    account_id = local.account_id
    region     = local.region
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  bucket                  = aws_s3_bucket.this[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket

  rule {
    id     = "Expire 30 days"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
    expiration {
      days = 30
    }
  }
}

resource "aws_flow_log" "this" {
  count = var.network.flowlogs.enabled ? 1 : 0

  log_destination      = aws_s3_bucket.this[0].arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
  depends_on           = [aws_s3_bucket_policy.this]

  tags = {
    Name = "${var.prefix}-kb-flowlogs"
  }
}
