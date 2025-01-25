########################################################
# IAM Role for Amazon Bedrock Flows
########################################################
data "aws_iam_policy_document" "assume_flows" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bedrock:${local.region}:${local.account_id}:flow/*"]
    }
  }
}

resource "aws_iam_role" "flows" {
  name               = "${local.prefix}-flow-role"
  assume_role_policy = data.aws_iam_policy_document.assume_flows.json
  tags = {
    Name = "${local.prefix}-flow-role"
  }
}

// ... existing code ...

data "aws_iam_policy_document" "flows" {
  statement {
    sid     = "InvokeModel"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      local.claude3_5_sonnet_model_arn,
      local.claude3_sonnet_model_arn
    ]
  }
  statement {
    sid       = "UsePromptFromPromptManagement"
    effect    = "Allow"
    actions   = ["bedrock:RenderPrompt"]
    resources = ["*"]
  }
  statement {
    sid     = "InvokeAgent"
    effect  = "Allow"
    actions = ["bedrock:InvokeAgent"]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "flows" {
  name   = "${local.prefix}-flow-policy"
  policy = data.aws_iam_policy_document.flows.json

  tags = {
    Name = "${local.prefix}-flow-policy"
  }
}

resource "aws_iam_role_policy_attachment" "flows" {
  role       = aws_iam_role.flows.name
  policy_arn = aws_iam_policy.flows.arn
}
