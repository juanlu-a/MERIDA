output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_a_id" {
  description = "ID of Private Subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID of Private Subnet B"
  value       = aws_subnet.private_b.id
}

output "public_subnet_a_id" {
  description = "ID of Public Subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID of Public Subnet B"
  value       = aws_subnet.public_b.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# NAT Gateway removed - using VPC Endpoints

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "ecs_container_security_group_id" {
  description = "ID of the ECS container security group"
  value       = aws_security_group.ecs_container.id
}

output "ecs_container_security_group_name" {
  description = "Name of the ECS container security group"
  value       = aws_security_group.ecs_container.name
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_endpoints_security_group_name" {
  description = "Name of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.name
}

output "availability_zones" {
  description = "List of availability zones used"
  value = [
    aws_subnet.public_a.availability_zone,
    aws_subnet.public_b.availability_zone
  ]
}

# ===========================================
# VPC Endpoints Outputs
# ===========================================

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "Prefix list ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.prefix_list_id
}

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "cloudwatch_logs_endpoint_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = aws_vpc_endpoint.cloudwatch_logs.id
}

output "eks_endpoint_id" {
  description = "ID of the EKS VPC endpoint"
  value       = aws_vpc_endpoint.eks.id
}

output "iot_data_endpoint_id" {
  description = "ID of the IoT Core Data VPC endpoint. Note: Requires Route 53 Private Hosted Zone configuration for DNS resolution."
  value       = aws_vpc_endpoint.iot_data.id
}

output "iot_data_endpoint_dns_names" {
  description = "DNS names of the IoT Core Data VPC endpoint ENIs. Use these to create Route 53 A records."
  value       = aws_vpc_endpoint.iot_data.dns_entry
}

output "iot_credentials_endpoint_id" {
  description = "ID of the IoT Core Credentials VPC endpoint. Note: Requires Route 53 Private Hosted Zone configuration for DNS resolution."
  value       = aws_vpc_endpoint.iot_credentials.id
}

output "iot_credentials_endpoint_dns_names" {
  description = "DNS names of the IoT Core Credentials VPC endpoint ENIs. Use these to create Route 53 A records."
  value       = aws_vpc_endpoint.iot_credentials.dns_entry
}

