variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "SmartGrowData"
}

variable "billing_mode" {
  description = "Billing mode for DynamoDB (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "gsi_name" {
  description = "Name of the Global Secondary Index"
  type        = string
  default     = "GSI"
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery for the table"
  type        = bool
  default     = true
}

variable "ttl_attribute" {
  description = "Attribute name for TTL (Time To Live). Leave empty to disable TTL."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(string)
  default     = {}
}

