output "rule_arn" {
  description = "ARN of the IoT rule"
  value       = aws_iot_topic_rule.iot_to_lambda_rule.arn
}

output "rule_name" {
  description = "Name of the IoT rule"
  value       = aws_iot_topic_rule.iot_to_lambda_rule.name
}

