resource "awscc_sagemaker_cluster" "this" {
  cluster_name = "sagemaker-hyperpod"

  instance_groups = [{
    execution_role      = aws_iam_role.hyperpod.arn
    instance_count      = 1
    instance_group_name = "controller-machine"
    instance_type       = "ml.t3.medium"
    life_cycle_config = {
      source_s3_uri = "s3://${aws_s3_bucket.life_cycle_scripts.id}/config/"
      on_create     = "on_create.sh"
    }
  }]
}
