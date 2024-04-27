########################################################
# VPC
########################################################
output "vpc" {
  value = aws_vpc.this
}

########################################################
# Route Table
########################################################
output "rtb" {
  value = aws_route_table.this
}

########################################################
# Subnet
########################################################
output "private_subnet_01" {
  value = aws_subnet.private_01
}

output "private_subnet_02" {
  value = aws_subnet.private_02
}

########################################################
# VPC Flowlogs
########################################################
output "flowlog" {
  value = aws_flow_log.this
}

output "flowlog_bucket" {
  value = aws_s3_bucket.this
}
