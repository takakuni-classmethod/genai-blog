########################################################
# VPC
########################################################
output "vpc" {
  value = aws_vpc.this
}

########################################################
# Internet Gateway
########################################################
output "igw" {
  value = aws_internet_gateway.this
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
output "public_subnet_01" {
  value = aws_subnet.public_01
}

output "public_subnet_02" {
  value = aws_subnet.public_02
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
