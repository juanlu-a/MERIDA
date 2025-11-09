# ===========================================
# Lambda Module - Creates IoT Handler Lambda
# ===========================================
module "lambda_iot_handler" {
  source = "./modules/lambda"

  function_name = var.lambda_function_name
  description   = "IoT Handler Lambda - Processes messages from system/plot/+ topics"

  source_path = var.lambda_source_path
  handler     = var.lambda_handler
  runtime     = var.lambda_runtime

  # Use existing LabRole (AWS Academy)
  create_role = false
  lambda_role = var.lab_role_arn

  # Performance configuration
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  # Environment variables
  environment_variables = merge(
    var.lambda_environment_variables,
    {
      DYNAMODB_TABLE = module.dynamodb_table.table_name
      # AWS_REGION is automatically provided by Lambda runtime
    }
  )

  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = var.lambda_log_retention_days

  tags = var.tags
}
