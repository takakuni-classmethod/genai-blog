########################################################
# Security Group
########################################################
output "sg" {
  value = aws_security_group.this
}

########################################################
# DB Subnet Group
########################################################
output "subnet_group" {
  value = aws_db_subnet_group.this
}

########################################################
# Parameter Group
########################################################
output "cluster_parameter_group" {
  value = aws_rds_cluster_parameter_group.this
}
output "db_parameter_group" {
  value = aws_db_parameter_group.this
}
output "instance_parameter_group" {
  value = aws_db_parameter_group.this
}

########################################################
# CloudWatch Log Group
########################################################
output "log_group" {
  value = aws_cloudwatch_log_group.this
}

########################################################
# IAM Role
########################################################
output "iam_role" {
  value = aws_iam_role.this
}

########################################################
# Aurora Cluster
########################################################
output "cluster" {
  value = aws_rds_cluster.this
}

########################################################
# Secrets
########################################################
output "secrets" {
  value = aws_secretsmanager_secret.this
}

########################################################
# Aurora Instance
########################################################
output "instance_01" {
  value = aws_rds_cluster_instance.this_01
}

output "instance_02" {
  value = aws_rds_cluster_instance.this_02
}
