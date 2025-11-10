##############################################
# Lambda Function - Responsible Subscription Sync
##############################################
module "lambda_responsible_sync" {
  source = "./modules/lambda"

  function_name = var.responsible_sync_lambda_function_name
  description   = "Synchronises SNS subscriptions when facility responsibles change"

  handler     = var.responsible_sync_lambda_handler
  runtime     = var.responsible_sync_lambda_runtime
  source_path = var.responsible_sync_lambda_source_path

  timeout     = var.responsible_sync_lambda_timeout
  memory_size = var.responsible_sync_lambda_memory_size

  create_role = false
  lambda_role = var.lab_role_arn

  environment_variables = {
    ALERTS_TOPIC_ARN = aws_sns_topic.alerts.arn
  }

  cloudwatch_logs_retention_in_days = var.responsible_sync_lambda_log_retention_days

  tags = var.tags
}

##############################################
# DynamoDB Stream Event Source Mapping (Responsibles)
##############################################
resource "aws_lambda_event_source_mapping" "responsible_sync_stream" {
  event_source_arn  = module.dynamodb_table.table_stream_arn
  function_name     = module.lambda_responsible_sync.lambda_function_arn
  starting_position = "LATEST"
  batch_size        = 10
  enabled           = true

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName = ["INSERT", "MODIFY", "REMOVE"]
        dynamodb = {
          Keys = {
            pk = {
              S = [
                {
                  prefix = "FACILITY#"
                }
              ]
            }
            sk = {
              S = ["RESPONSIBLES"]
            }
          }
        }
      })
    }
  }

  depends_on = [
    module.lambda_responsible_sync
  ]
}

