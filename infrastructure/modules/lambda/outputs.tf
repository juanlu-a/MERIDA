output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.lambda_function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.lambda_function.lambda_function_invoke_arn
}

output "lambda_cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for Lambda"
  value       = module.lambda_function.lambda_cloudwatch_log_group_name
}

output "lambda_cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for Lambda"
  value       = module.lambda_function.lambda_cloudwatch_log_group_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = var.lambda_role
}
