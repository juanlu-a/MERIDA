terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ===========================================
# ECS Module - Fargate Only
# ===========================================
# This module creates ECS resources using AWS Fargate launch type.
# Network mode is hardcoded to 'awsvpc' which is required for Fargate.
# Target type for ALB is hardcoded to 'ip' for Fargate tasks.

# ===========================================
# ECS Cluster
# ===========================================
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# ===========================================
# CloudWatch Log Group for ECS
# ===========================================
resource "aws_cloudwatch_log_group" "task" {
  name              = "/ecs/${var.cluster_name}/${var.task_family}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.task_family}-logs"
    }
  )
}

# ===========================================
# ECS Task Definition (Fargate only)
# ===========================================
resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.container_cpu)
  memory                   = tostring(var.container_memory)

  execution_role_arn = var.execution_role_arn != "" ? var.execution_role_arn : var.lab_role_arn
  task_role_arn      = var.task_role_arn != "" ? var.task_role_arn : var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_image
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = var.container_environment
    }
  ])

  tags = merge(
    var.tags,
    {
      Name = var.task_family
    }
  )
}

# ===========================================
# ECS Service
# ===========================================
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Renovar tareas sin recrear ALB/TargetGroup
  force_new_deployment = true

  # Network configuration for Fargate - Private subnets only
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  # Load balancer configuration - Always enabled
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  # Dependencies handled via dynamic blocks, no need for conditional depends_on

  tags = merge(
    var.tags,
    {
      Name = var.service_name
    }
  )
}

# ===========================================
# ALB Security Group
# ===========================================
resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-sg"
  description = "ALB SG - allow HTTP from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from everyone"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
      Name = "${var.alb_name}-sg"
    }
  )
}

# ===========================================
# Application Load Balancer
# ===========================================
resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids

  enable_deletion_protection = var.alb_enable_deletion_protection
  idle_timeout               = var.alb_idle_timeout

  tags = merge(
    var.tags,
    {
      Name = var.alb_name
    }
  )
}

# ===========================================
# Target Group
# ===========================================
resource "aws_lb_target_group" "this" {
  name        = "${var.alb_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.alb_name}-tg"
    }
  )
}

# ===========================================
# ALB Listener
# ===========================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ===========================================
# Security Group Rule: ALB to ECS Tasks 
# ===========================================
resource "aws_security_group_rule" "alb_to_tasks_ingress" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = var.ecs_security_group_id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to talk to ECS tasks on container port"
}

