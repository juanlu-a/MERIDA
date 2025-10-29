variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda IoT Handler function"
  type        = string
  default     = "Lambda-IoT-Handler"
}

variable "lambda_handler" {
  description = "Lambda handler (e.g., app.lambda_handler)"
  type        = string
  default     = "app.lambda_handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_source_path" {
  description = "Path to the Lambda source code directory (for ZIP deployment)"
  type        = string
  default     = "./lambda_code"
}

variable "lambda_image_uri" {
  description = "ECR image URI for Lambda container deployment. If set, overrides source_path."
  type        = string
  default     = null
}

variable "lambda_log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "lab_role_arn" {
  description = "ARN of the AWS Academy LabRole (e.g., arn:aws:iam::123456789012:role/LabRole)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to write to"
  type        = string
  default     = "SmartGrowData"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_gsi_name" {
  description = "Name of the Global Secondary Index"
  type        = string
  default     = "GSI"
}

variable "dynamodb_enable_pitr" {
  description = "Enable Point-in-Time Recovery for DynamoDB"
  type        = bool
  default     = true
}

variable "dynamodb_ttl_attribute" {
  description = "Attribute name for TTL (Time To Live). Leave empty to disable."
  type        = string
  default     = ""
}

variable "lambda_environment_variables" {
  description = "Additional environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "iot_rule_name" {
  description = "Name of the IoT rule"
  type        = string
  default     = "iot_to_lambda_rule"
}

variable "iot_rule_description" {
  description = "Description of the IoT rule"
  type        = string
  default     = "IoT Rule to forward system/plot/+ messages to Lambda"
}

variable "iot_rule_sql" {
  description = "SQL query for the IoT rule"
  type        = string
  default     = "SELECT * FROM 'system/plot/+'"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "Merida"
  }
}
