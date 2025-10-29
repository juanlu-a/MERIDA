variable "rule_name" {
  description = "Rule for the Iot handler Lambda function where the messeges will be processed and saved in the database"
  type        = string
  default     = "iot_to_lambda_rule"
}

variable "rule_description" {
  description = ""
  type        = string
  default     = "IoT Rule to forward system/plot/+ messages to Lambda"
}

variable "sql" {
  description = "SQL query for the IoT rule"
  type        = string
  default     = "SELECT * FROM 'system/plot/+'"
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function (not invoke ARN)"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda Iot Handler function"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

