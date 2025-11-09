##############################################
# SNS Topic for Alerts
##############################################
resource "aws_sns_topic" "alerts" {
  name = var.alerts_sns_topic_name

  tags = merge(
    var.tags,
    {
      Name = var.alerts_sns_topic_name
    }
  )
}

##############################################
# IAM Role and Policies for Alert Processor Lambda
##############################################
data "aws_iam_policy_document" "lambda_alerts_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_alerts" {
  name               = "${var.alert_lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_alerts_assume.json

  tags = merge(
    var.tags,
    {
      Name = "${var.alert_lambda_function_name}-role"
    }
  )
}

data "aws_iam_policy_document" "lambda_alerts_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:DescribeTable"
    ]
    resources = [
      module.dynamodb_table.table_arn,
      "${module.dynamodb_table.table_arn}/index/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.alerts.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "cognito-idp:ListUsers"
    ]
    resources = [module.cognito.user_pool_arn]
  }
}

resource "aws_iam_role_policy" "lambda_alerts_inline" {
  role   = aws_iam_role.lambda_alerts.id
  policy = data.aws_iam_policy_document.lambda_alerts_policy.json
}

##############################################
# Lambda Function - DynamoDB Stream Processor
##############################################
module "lambda_alert_processor" {
  source = "./modules/lambda"

  function_name = var.alert_lambda_function_name
  description   = "Processes DynamoDB stream events to raise environmental alerts"

  handler     = var.alert_lambda_handler
  runtime     = var.alert_lambda_runtime
  source_path = var.alert_lambda_source_path

  timeout     = var.alert_lambda_timeout
  memory_size = var.alert_lambda_memory_size

  create_role = false
  lambda_role = aws_iam_role.lambda_alerts.arn

  environment_variables = {
    DYNAMO_TABLE_NAME  = module.dynamodb_table.table_name
    USER_POOL_ID       = module.cognito.user_pool_id
    ALERTS_TOPIC_ARN   = aws_sns_topic.alerts.arn
    TOLERANCE_PERCENT  = format("%.4f", var.alert_lambda_tolerance)
  }

  cloudwatch_logs_retention_in_days = var.alert_lambda_log_retention_days

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.lambda_alerts_inline
  ]
}

##############################################
# DynamoDB Stream Event Source Mapping
##############################################
resource "aws_lambda_event_source_mapping" "alerts_stream" {
  event_source_arn  = module.dynamodb_table.table_stream_arn
  function_name     = module.lambda_alert_processor.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = var.alert_lambda_batch_size
  enabled           = true

  depends_on = [
    module.lambda_alert_processor
  ]
}

