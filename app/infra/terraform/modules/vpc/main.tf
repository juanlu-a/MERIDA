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
# Elastic IP for NAT Gateway
# ===========================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-NAT-EIP"
      Owner = "Demo"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# ===========================================
# NAT Gateway (SOLO en AZ-A)
# ===========================================
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = merge(
    var.tags,
    {
      Name  = "${var.vpc_name}-NAT"
      Owner = "Demo"
    }
  )

  depends_on = [aws_internet_gateway.main]
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

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

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
# VPC Endpoints (Gateway) - Sin costo adicional
# ===========================================

# DynamoDB Gateway Endpoint - Para que ECS acceda a DynamoDB sin usar NAT
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-DynamoDB-Endpoint"
    }
  )
}

# S3 Gateway Endpoint - Para logs de ECS sin usar NAT
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-S3-Endpoint"
    }
  )
}

# ===========================================
# VPC Endpoints (Interface) - ECR para pull de imágenes
# ===========================================

# ECR API endpoint - para autenticación y metadata
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
}

# ECR DKR endpoint - para pull/push de imágenes
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
}

# CloudWatch Logs endpoint - para logs de contenedores
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
}

# IoT Core endpoint - DISABLED: IoT Core VPC Endpoint not available in all regions
# IoT Core can still be accessed over the internet gateway
# resource "aws_vpc_endpoint" "iot_core" {
#   vpc_id              = aws_vpc.main.id
#   service_name        = "com.amazonaws.${var.aws_region}.iot"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
#
#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.vpc_name}-IoT-Core-Endpoint"
#     }
#   )
# }

# ===========================================
# Data Sources
# ===========================================
data "aws_availability_zones" "available" {
  state = "available"
}

