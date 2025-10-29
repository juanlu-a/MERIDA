# Lambda Function
# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb_table.table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb_table.table_arn
}

# Lambda Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_iot_handler.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_iot_handler.lambda_function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.lambda_iot_handler.lambda_function_invoke_arn
}

output "lambda_cloudwatch_log_group" {
  description = "CloudWatch Log Group name for Lambda"
  value       = module.lambda_iot_handler.lambda_cloudwatch_log_group_name
}

# IoT Rule
output "iot_rule_arn" {
  description = "ARN of the IoT rule"
  value       = module.iot_rule.rule_arn
}

output "iot_rule_name" {
  description = "Name of the IoT rule"
  value       = module.iot_rule.rule_name
}
