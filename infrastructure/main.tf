terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# ===========================================
# DynamoDB Module - Creates SmartGrowData Table
# ===========================================
module "dynamodb_table" {
  source = "./modules/dynamodb"

  table_name                    = var.dynamodb_table_name
  billing_mode                  = var.dynamodb_billing_mode
  gsi_name                      = var.dynamodb_gsi_name
  enable_point_in_time_recovery = var.dynamodb_enable_pitr
  ttl_attribute                 = var.dynamodb_ttl_attribute

  tags = var.tags
}

# ===========================================
# Lambda Module - Creates IoT Handler Lambda
# ===========================================
module "lambda_iot_handler" {
  source = "./modules/lambda"

  function_name = var.lambda_function_name
  description   = "IoT Handler Lambda - Processes messages from system/plot/+ topics"
  
  
  # Docker/ECR deployment (optional)
  image_uri   = var.lambda_image_uri

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

# ===========================================
# IoT Module - Creates IoT Topic Rule
# ===========================================
module "iot_rule" {
  source = "./modules/iot"

  rule_name            = var.iot_rule_name
  rule_description     = var.iot_rule_description
  sql                  = var.iot_rule_sql
  lambda_function_arn  = module.lambda_iot_handler.lambda_function_arn
  lambda_function_name = module.lambda_iot_handler.lambda_function_name

  tags = var.tags
}


