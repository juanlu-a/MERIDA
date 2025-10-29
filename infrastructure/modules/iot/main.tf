terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------
# IoT Topic Rule: system/plot/+ → Lambda
# -----------------------
resource "aws_iot_topic_rule" "iot_to_lambda_rule" {
  name        = var.rule_name
  description = var.rule_description
  enabled     = true
  sql         = var.sql
  sql_version = "2016-03-23"

  lambda {
    function_arn = var.lambda_function_arn
  }

  tags = var.tags
}

# Lambda permission for IoT Rule
resource "aws_lambda_permission" "iot_invoke" {
  statement_id  = "AllowExecutionFromIoTRule"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.iot_to_lambda_rule.arn
}

