terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ===========================================
# VPC
# ===========================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = merge(
    var.tags,
    {
      Name  = var.vpc_name
      Owner = "Demo"
    }
  )
}

# ===========================================
# Internet Gateway
# ===========================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-IGW"
      Owner = "Demo"
    }
  )
}

# ===========================================
# Public Subnets
# ===========================================
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnet_a_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-PubSubnetA"
      Owner = "Demo"
      Type  = "Public"
    }
  )
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-PubSubnetB"
      Owner = "Demo"
      Type  = "Public"
    }
  )
}

# ===========================================
# Private Subnets
# ===========================================
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.prv_subnet_a_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-PrvSubnetA"
      Owner = "Demo"
      Type  = "Private"
    }
  )
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.prv_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-PrvSubnetB"
      Owner = "Demo"
      Type  = "Private"
    }
  )
}

# ===========================================
# Route Tables
# ===========================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-PubRouteTable"
      Owner = "Demo"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-PrvRouteTable"
      Owner = "Demo"
    }
  )
}

# ===========================================
# Routes
# ===========================================
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Private route table: NO NAT Gateway - all AWS service access via VPC Endpoints
# Traffic to AWS services (ECR, CloudWatch, IoT, etc.) uses Interface Endpoints
# Traffic to S3/DynamoDB uses Gateway Endpoints

# ===========================================
# Route Table Associations
# ===========================================
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ===========================================
# Security Groups
# ===========================================

# Security Group for ECS Container Tasks
# - No ingress rules here (added dynamically by ECS module from ALB)
# - Egress allowed to VPC Endpoints and outbound
resource "aws_security_group" "ecs_container" {
  name        = "${var.vpc_name}-ECSContainerSG"
  description = "Security group for ECS container tasks in private subnets"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-ECSContainerSG"
      Owner = "Demo"
    }
  )
}

# Security Group for VPC Endpoints (Interface endpoints)
# - Allow traffic from ECS tasks to endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.vpc_name}-VPCEndpointsSG"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTPS from ECS tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_container.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-VPCEndpointsSG"
      Owner = "Demo"
    }
  )
}

# ===========================================
# VPC Endpoints - Architecture without NAT Gateway
# ===========================================
# ECS tasks in private subnets access AWS services via VPC Endpoints
# Gateway endpoints (S3, DynamoDB): No cost, route table based
# Interface endpoints: Private IPs in subnets, DNS enabled, cost per hour/GB

# ===========================================
# Gateway Endpoints (No cost, route table based)
# ===========================================

# S3 Gateway Endpoint - For ECR image layers and logs
# Required for ECR to pull image layers from S3 without internet access
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-S3-Gateway-Endpoint"
    }
  )

  depends_on = [aws_vpc.main, aws_route_table.private]
}

# DynamoDB Gateway Endpoint - For Lambda/ECS to access DynamoDB tables
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-DynamoDB-Gateway-Endpoint"
    }
  )

  depends_on = [aws_vpc.main, aws_route_table.private]
}

# ===========================================
# Interface Endpoints (Private IPs in subnets, DNS enabled)
# ===========================================

# CloudWatch Logs Interface Endpoint
# Required for ECS tasks to send logs to CloudWatch without internet access
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-CloudWatch-Logs-Endpoint"
    }
  )

  depends_on = [
    aws_vpc.main,
    aws_subnet.private_a,
    aws_subnet.private_b,
    aws_security_group.vpc_endpoints
  ]
}

# ECR API Interface Endpoint
# Required for ECS tasks to authenticate and get metadata from ECR
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-ECR-API-Endpoint"
    }
  )

  depends_on = [
    aws_vpc.main,
    aws_subnet.private_a,
    aws_subnet.private_b,
    aws_security_group.vpc_endpoints
  ]
}

# ECR Docker Interface Endpoint
# Required for ECS tasks to pull/push Docker images from/to ECR
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-ECR-DKR-Endpoint"
    }
  )

  depends_on = [
    aws_vpc.main,
    aws_subnet.private_a,
    aws_subnet.private_b,
    aws_security_group.vpc_endpoints
  ]
}

# EKS Control Plane Interface Endpoint
# Required for ECS/Fargate tasks to communicate with EKS control plane
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-EKS-Endpoint"
    }
  )

  depends_on = [
    aws_vpc.main,
    aws_subnet.private_a,
    aws_subnet.private_b,
    aws_security_group.vpc_endpoints
  ]
}

# ===========================================
# IoT Core Interface Endpoints
# ===========================================
# IoT Core endpoints DO NOT support automatic Private DNS
# You must configure Route 53 Private Hosted Zone to resolve IoT endpoints
# See comments below for Route 53 configuration instructions

# IoT Core Data Plane Interface Endpoint
# Required for MQTT/TLS connections to IoT Core data plane (publish/subscribe)
# private_dns_enabled = false: Must configure Route 53 Private Hosted Zone manually
# Note: IoT Core endpoints may not be available in all AZs - using only private_a subnet
# If creation fails, try using only the AZ that supports the service
resource "aws_vpc_endpoint" "iot_data" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.iot.data"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]  # Using only one subnet to avoid AZ compatibility issues
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = false

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-IoT-Data-Endpoint"
    }
  )

  depends_on = [
    aws_vpc.main,
    aws_subnet.private_a,
    aws_subnet.private_b,
    aws_security_group.vpc_endpoints
  ]
}

# IoT Core Credentials Interface Endpoint
# Required for IoT device credential provisioning and rotation
# private_dns_enabled = false: Must configure Route 53 Private Hosted Zone manually
# Note: IoT Core endpoints may not be available in all AZs - using only private_a subnet
# If creation fails, try using only the AZ that supports the service
resource "aws_vpc_endpoint" "iot_credentials" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.iot.credentials"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_a.id]  # Using only one subnet to avoid AZ compatibility issues
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = false

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-IoT-Credentials-Endpoint"
    }
  )

  depends_on = [
    aws_vpc.main,
    aws_subnet.private_a,
    aws_subnet.private_b,
    aws_security_group.vpc_endpoints
  ]
}

# ===========================================
# Route 53 Configuration for IoT Core Endpoints
# ===========================================
# Since IoT Core endpoints have private_dns_enabled = false, we automatically
# configure Route 53 Private Hosted Zone to resolve IoT Core endpoints.

# Get IoT Core endpoint address (data plane)
data "aws_iot_endpoint" "data" {
  endpoint_type = "iot:Data-ATS"
}

# Get IoT Core endpoint address (credentials)
data "aws_iot_endpoint" "credentials" {
  endpoint_type = "iot:CredentialProvider"
}

# Get Network Interfaces for IoT Data VPC Endpoint
# Note: We use external data source since for_each can't use values known only after apply
data "aws_network_interfaces" "iot_data" {
  filter {
    name   = "vpc-endpoint-id"
    values = [aws_vpc_endpoint.iot_data.id]
  }

  depends_on = [aws_vpc_endpoint.iot_data]
}

# Get Network Interfaces for IoT Credentials VPC Endpoint
data "aws_network_interfaces" "iot_credentials" {
  filter {
    name   = "vpc-endpoint-id"
    values = [aws_vpc_endpoint.iot_credentials.id]
  }

  depends_on = [aws_vpc_endpoint.iot_credentials]
}

# Private Hosted Zone for IoT Core endpoints
resource "aws_route53_zone" "iot_private" {
  name = "iot.${var.aws_region}.amazonaws.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-IoT-Private-Zone"
    }
  )

  depends_on = [aws_vpc.main, aws_vpc_endpoint.iot_data, aws_vpc_endpoint.iot_credentials]
}

# Get private IPs for IoT Data endpoint using external data source
# This works around the limitation of for_each with unknown values
# Note: May return empty during plan phase - will populate after first apply
data "external" "iot_data_ips" {
  program = ["bash", "-c", <<-EOT
    endpoint_id="${aws_vpc_endpoint.iot_data.id}"
    if [ -z "$endpoint_id" ] || [ "$endpoint_id" = "" ]; then
      echo '{"ips":""}'
      exit 0
    fi
    ips=$(aws ec2 describe-network-interfaces \
      --filters "Name=vpc-endpoint-id,Values=$endpoint_id" \
      --query 'NetworkInterfaces[*].PrivateIpAddress' \
      --output text \
      --region ${var.aws_region} 2>/dev/null || echo "")
    if [ -z "$ips" ]; then
      echo '{"ips":""}'
    else
      echo "{\"ips\":\"$ips\"}"
    fi
  EOT
  ]

  depends_on = [aws_vpc_endpoint.iot_data]
}

# Get private IPs for IoT Credentials endpoint using external data source
data "external" "iot_credentials_ips" {
  program = ["bash", "-c", <<-EOT
    endpoint_id="${aws_vpc_endpoint.iot_credentials.id}"
    if [ -z "$endpoint_id" ] || [ "$endpoint_id" = "" ]; then
      echo '{"ips":""}'
      exit 0
    fi
    ips=$(aws ec2 describe-network-interfaces \
      --filters "Name=vpc-endpoint-id,Values=$endpoint_id" \
      --query 'NetworkInterfaces[*].PrivateIpAddress' \
      --output text \
      --region ${var.aws_region} 2>/dev/null || echo "")
    if [ -z "$ips" ]; then
      echo '{"ips":""}'
    else
      echo "{\"ips\":\"$ips\"}"
    fi
  EOT
  ]

  depends_on = [aws_vpc_endpoint.iot_credentials]
}

# Extract IoT Data endpoint hostname and parse IPs from external data source
locals {
  iot_data_domain_clean        = replace(replace(data.aws_iot_endpoint.data.endpoint_address, "https://", ""), "http://", "")
  iot_data_hostname            = split(".", local.iot_data_domain_clean)[0] # e.g., xxxxxxxxxxxxxx-ats
  iot_credentials_hostname     = "credentials"
  iot_data_ips_list            = split(" ", trimspace(data.external.iot_data_ips.result.ips))
  iot_credentials_ips_list     = split(" ", trimspace(data.external.iot_credentials_ips.result.ips))
}

# A record for IoT Data endpoint - all ENI IPs in single record
# Note: Records will be populated automatically after VPC endpoints are created
resource "aws_route53_record" "iot_data" {
  zone_id = aws_route53_zone.iot_private.zone_id
  name    = local.iot_data_hostname
  type    = "A"
  ttl     = 300

  records = length(local.iot_data_ips_list) > 0 && local.iot_data_ips_list[0] != "" ? local.iot_data_ips_list : []

  depends_on = [
    aws_route53_zone.iot_private,
    aws_vpc_endpoint.iot_data,
    data.external.iot_data_ips
  ]
}

# A record for IoT Credentials endpoint - all ENI IPs in single record
# Note: Records will be populated automatically after VPC endpoints are created
resource "aws_route53_record" "iot_credentials" {
  zone_id = aws_route53_zone.iot_private.zone_id
  name    = local.iot_credentials_hostname
  type    = "A"
  ttl     = 300

  records = length(local.iot_credentials_ips_list) > 0 && local.iot_credentials_ips_list[0] != "" ? local.iot_credentials_ips_list : []

  depends_on = [
    aws_route53_zone.iot_private,
    aws_vpc_endpoint.iot_credentials,
    data.external.iot_credentials_ips
  ]
}

# ===========================================
# Data Sources
# ===========================================
data "aws_availability_zones" "available" {
  state = "available"
}

