# ===========================================
# Common Variables
# ===========================================

variable "aws_region" {
  description = "AWS region to operate in"
  type        = string
}

variable "lab_role_arn" {
  description = "ARN of the lab role for execution and task roles"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===========================================
# Cluster Configuration
# ===========================================

variable "cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = false
}

# ===========================================
# Task Definition Configuration (Fargate only)
# ===========================================

variable "task_family" {
  description = "Family name for the ECS task definition"
  type        = string
}

# task_network_mode always set to "awsvpc" for Fargate

variable "container_name" {
  description = "Container name used inside the task definition"
  type        = string
}

variable "container_image" {
  description = "Container image to run"
  type        = string
}

variable "container_cpu" {
  description = "CPU units reserved for the container"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory (MB) reserved for the container"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(map(string))
  default     = []
}

# ===========================================
# Service Configuration
# ===========================================

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks for the service"
  type        = number
  default     = 1
}

# ===========================================
# Networking Configuration (Fargate always uses awsvpc)
# ===========================================

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to deploy ECS tasks"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for ECS tasks"
  type        = list(string)
  default     = []
}

variable "ecs_security_group_id" {
  description = "Existing ECS security group ID (for ALB integration)"
  type        = string
  default     = ""
}

# ===========================================
# IAM Roles
# ===========================================

variable "execution_role_arn" {
  description = "ARN of the Task Execution role (used by ECS to pull images / write logs)"
  type        = string
  default     = ""
}

variable "task_role_arn" {
  description = "ARN of the Task Role for the task (application permissions)"
  type        = string
  default     = ""
}

# ===========================================
# Load Balancer Configuration
# ===========================================

variable "create_alb" {
  description = "If true, create an ALB + target group and wire ECS service to it"
  type        = bool
  default     = false
}

variable "alb_name" {
  description = "Name prefix for the ALB resources"
  type        = string
  default     = "ecs-demo-alb"
}

variable "alb_subnet_ids" {
  description = "Subnets for the ALB (public subnets)"
  type        = list(string)
  default     = []
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "alb_enable_deletion_protection" {
  description = "Enable deletion protection on ALB"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN to attach to the HTTPS listener. Leave empty to skip HTTPS."
  type        = string
  default     = ""
}

variable "alb_ssl_policy" {
  description = "SSL policy to use for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

# ===========================================
# Health Check Configuration
# ===========================================

variable "health_check_enabled" {
  description = "Whether health checks are enabled"
  type        = bool
  default     = true
}

variable "health_check_interval" {
  description = "Approximate amount of time between health checks"
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "Destination for the health check request"
  type        = string
  default     = "/health"
}

variable "health_check_timeout" {
  description = "Amount of time during which no response from a target means a failed health check"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive health check successes required before considering a target healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering a target unhealthy"
  type        = number
  default     = 2
}

variable "health_check_matcher" {
  description = "Response codes to use when checking for a healthy response"
  type        = string
  default     = "200-399"
}

# ===========================================
# Deployment Configuration
# ===========================================

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on the number of tasks that must remain in the RUNNING state"
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "Upper limit on the number of tasks that can be in the RUNNING state"
  type        = number
  default     = 200
}

# ===========================================
# Logging Configuration
# ===========================================

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

# ===========================================
# Legacy Variables (for backwards compatibility)
# ===========================================

variable "target_group_arn" {
  description = "ARN of an existing ALB target group (optional)"
  type        = string
  default     = ""
}

