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

output "alert_lambda_function_arn" {
  description = "ARN of the DynamoDB stream alert processor Lambda"
  value       = module.lambda_alert_processor.lambda_function_arn
}

output "alert_lambda_function_name" {
  description = "Name of the DynamoDB stream alert processor Lambda"
  value       = module.lambda_alert_processor.lambda_function_name
}

output "alerts_sns_topic_arn" {
  description = "ARN of the SNS topic used for alert notifications"
  value       = aws_sns_topic.alerts.arn
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

# ===========================================
# VPC Network Outputs
# ===========================================

output "vpc_id" {
  description = "ID of the main VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the main VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_a_id" {
  description = "ID of Private Subnet A"
  value       = module.vpc.private_subnet_a_id
}

output "private_subnet_b_id" {
  description = "ID of Private Subnet B"
  value       = module.vpc.private_subnet_b_id
}

output "public_subnet_a_id" {
  description = "ID of Public Subnet A"
  value       = module.vpc.public_subnet_a_id
}

output "public_subnet_b_id" {
  description = "ID of Public Subnet B"
  value       = module.vpc.public_subnet_b_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "nat_eip_allocation_id" {
  description = "Allocation ID of the NAT Gateway EIP"
  value       = module.vpc.nat_eip_allocation_id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = module.vpc.private_route_table_id
}

output "ecs_container_security_group_id" {
  description = "ID of the ECS container security group"
  value       = module.vpc.ecs_container_security_group_id
}

output "ecs_container_security_group_name" {
  description = "Name of the ECS container security group"
  value       = module.vpc.ecs_container_security_group_name
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

# ===========================================
# VPC Endpoints Outputs
# ===========================================

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = module.vpc.dynamodb_endpoint_id
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "Prefix list ID of the DynamoDB VPC endpoint"
  value       = module.vpc.dynamodb_endpoint_prefix_list_id
}

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = module.vpc.s3_endpoint_id
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint"
  value       = module.vpc.s3_endpoint_prefix_list_id
}

# ===========================================
# ECS Outputs
# ===========================================

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs.task_definition_arn
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = module.ecs.service_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "ecs_alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "ecs_alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.ecs.alb_arn
}

output "ecs_target_group_arn" {
  description = "ARN of the target group"
  value       = module.ecs.target_group_arn
}

output "ecs_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs.log_group_name
}

# ===========================================
# Cognito Outputs
# ===========================================

output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = module.cognito.user_pool_arn
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = module.cognito.user_pool_endpoint
}

output "cognito_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = module.cognito.user_pool_client_id
}

output "cognito_user_pool_domain" {
  description = "Domain of the Cognito User Pool (if created)"
  value       = module.cognito.user_pool_domain
}

# ===========================================
# Amplify Outputs
# ===========================================

output "amplify_app_id" {
  description = "ID of the Amplify app"
  value       = var.enable_amplify ? module.amplify[0].app_id : null
}

output "amplify_default_domain" {
  description = "Default domain of the Amplify app"
  value       = var.enable_amplify ? module.amplify[0].default_domain : null
}

output "amplify_app_url" {
  description = "URL of the deployed Amplify app"
  value       = var.enable_amplify ? module.amplify[0].branch_url : null
}

output "amplify_app_name" {
  description = "Name of the Amplify app"
  value       = var.enable_amplify ? module.amplify[0].app_name : null
}
