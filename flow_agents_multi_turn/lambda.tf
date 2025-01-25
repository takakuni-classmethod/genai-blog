########################################################
# IAM Role for Lambda
########################################################
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags = {
    Name = "${local.prefix}-lambda-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

########################################################
# Lambda Function
########################################################
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "lambda/src"
  output_path = "lambda/lambda_function.zip"
}

resource "aws_lambda_function" "this" {
  function_name = "${local.prefix}-function"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda.arn

  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout = 180
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromBedrock"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "bedrock.amazonaws.com"
  source_arn    = "arn:aws:bedrock:${local.region}:${local.account_id}:agent/${aws_bedrockagent_agent.this.id}"
}
