output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.smart_grow_data.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.smart_grow_data.arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.smart_grow_data.id
}

output "table_stream_arn" {
  description = "ARN of the table stream (if enabled)"
  value       = aws_dynamodb_table.smart_grow_data.stream_arn
}

output "gsi_name" {
  description = "Name of the Global Secondary Index"
  value       = var.gsi_name
}

