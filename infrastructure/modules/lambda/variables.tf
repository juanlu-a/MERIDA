variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda handler (e.g., app.lambda_handler). Not used for container images."
  type        = string
  default     = null
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.13). Not used for container images."
  type        = string
  default     = null
}

variable "source_path" {
  description = "Path to the Lambda source code directory (for ZIP deployment)"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for Lambda container deployment (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-lambda:latest)"
  type        = string
  default     = null
}

variable "create_role" {
  description = "Whether to create a new IAM role for Lambda"
  type        = bool
  default     = false
}

variable "lambda_role" {
  description = "ARN of existing IAM role to use for Lambda"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
