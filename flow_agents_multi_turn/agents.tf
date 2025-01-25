########################################################
# IAM Role for Agents
########################################################
locals {
  claude3_sonnet_model_arn   = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
  claude3_5_sonnet_model_arn = "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
}

data "aws_iam_policy_document" "assume_bedrock" {
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
      values   = ["arn:aws:bedrock:${local.region}:${local.account_id}:agent/*"]
    }
  }
}

resource "aws_iam_role" "agents" {
  name               = "${local.prefix}-agents-role"
  assume_role_policy = data.aws_iam_policy_document.assume_bedrock.json
  tags = {
    Name = "${local.prefix}-agents-role"
  }
}

data "aws_iam_policy_document" "policy_agents" {
  statement {
    sid     = "AllowModelInvocationForOrchestration"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      local.claude3_5_sonnet_model_arn,
      local.claude3_sonnet_model_arn
    ]
  }
}

resource "aws_iam_policy" "agents" {
  name   = "${local.prefix}-agents-policy"
  policy = data.aws_iam_policy_document.policy_agents.json

  tags = {
    Name = "${local.prefix}-agents-policy"
  }
}

resource "aws_iam_role_policy_attachment" "agents" {
  role       = aws_iam_role.agents.name
  policy_arn = aws_iam_policy.agents.arn
}

########################################################
# Agents
########################################################
resource "aws_bedrockagent_agent" "this" {
  agent_name              = "${local.prefix}-agent"
  agent_resource_role_arn = aws_iam_role.agents.arn
  foundation_model        = "anthropic.claude-3-5-sonnet-20240620-v1:0"
  prepare_agent           = true
  instruction             = local.prompt
}

resource "aws_bedrockagent_agent_alias" "this" {
  agent_alias_name = "latest"
  agent_id         = aws_bedrockagent_agent.this.agent_id
}

resource "aws_bedrockagent_agent_action_group" "this" {
  action_group_name          = "${local.prefix}-agent"
  agent_id                   = aws_bedrockagent_agent.this.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = aws_lambda_function.this.arn
  }
  function_schema {
    member_functions {
      functions {
        name        = "get_available_vacations_days"
        description = "get the number of vacations available for a certain employee"
        parameters {
          map_block_key = "employee_id"
          type          = "integer"
          description   = "the id of the employee to get the available vacations"
          required      = true
        }
      }
      functions {
        name        = "reserve_vacation_time"
        description = "reserve vacation time for a specific employee - you need all parameters to reserve vacation time"
        parameters {
          map_block_key = "employee_id"
          type          = "integer"
          description   = "the id of the employee for which time off will be reserved"
          required      = true
        }
        parameters {
          map_block_key = "start_date"
          type          = "string"
          description   = "the start date for the vacation time"
          required      = true
        }
        parameters {
          map_block_key = "end_date"
          type          = "string"
          description   = "the end date for the vacation time"
          required      = true
        }
      }
    }
  }
}
