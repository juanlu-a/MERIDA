variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda IoT Handler function"
  type        = string
  default     = "Lambda-IoT-Handler"
}

variable "lambda_handler" {
  description = "Lambda handler (e.g., app.lambda_handler)"
  type        = string
  default     = "app.lambda_handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "lambda_source_path" {
  description = "Path to the Lambda source code directory - Terraform empaqueta automáticamente"
  type        = string
  default     = "../../../lambdas/lambda_iot_handler"
}

variable "lambda_log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

variable "alert_lambda_function_name" {
  description = "Name of the Lambda function that processes DynamoDB stream events"
  type        = string
  default     = "PlotAlertProcessor"
}

variable "alert_lambda_handler" {
  description = "Lambda handler for the alert processor function"
  type        = string
  default     = "app.lambda_handler"
}

variable "alert_lambda_runtime" {
  description = "Runtime for the alert processor Lambda"
  type        = string
  default     = "python3.11"
}

variable "alert_lambda_source_path" {
  description = "Source path for the alert processor Lambda code"
  type        = string
  default     = "../lambdas/lambda_alert_processor"
}

variable "alert_lambda_timeout" {
  description = "Timeout in seconds for the alert processor Lambda"
  type        = number
  default     = 30
}

variable "alert_lambda_memory_size" {
  description = "Memory size in MB for the alert processor Lambda"
  type        = number
  default     = 256
}

variable "alert_lambda_log_retention_days" {
  description = "CloudWatch Logs retention in days for the alert processor Lambda"
  type        = number
  default     = 14
}

variable "alert_lambda_tolerance" {
  description = "Tolerance factor (as a decimal) applied when comparing measurements against ideal values"
  type        = number
  default     = 0.1
}

variable "alert_lambda_batch_size" {
  description = "Maximum number of stream records to process per Lambda invocation"
  type        = number
  default     = 10
}

variable "alerts_sns_topic_name" {
  description = "SNS topic name used to deliver facility alert emails"
  type        = string
  default     = "merida-alerts-topic"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "lab_role_arn" {
  description = "ARN of the AWS Academy LabRole (e.g., arn:aws:iam::123456789012:role/LabRole)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to write to"
  type        = string
  default     = "SmartGrowData"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_gsi_name" {
  description = "Name of the Global Secondary Index"
  type        = string
  default     = "GSI"
}

variable "dynamodb_enable_pitr" {
  description = "Enable Point-in-Time Recovery for DynamoDB"
  type        = bool
  default     = true
}

variable "dynamodb_ttl_attribute" {
  description = "Attribute name for TTL (Time To Live). Leave empty to disable."
  type        = string
  default     = ""
}

variable "lambda_environment_variables" {
  description = "Additional environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "iot_rule_name" {
  description = "Name of the IoT rule"
  type        = string
  default     = "iot_to_lambda_rule"
}

variable "iot_rule_description" {
  description = "Description of the IoT rule"
  type        = string
  default     = "IoT Rule to forward system/plot/+ messages to Lambda"
}

variable "iot_rule_sql" {
  description = "SQL query for the IoT rule"
  type        = string
  default     = "SELECT * FROM 'system/plot/+'"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "Merida"
  }
}

# ===========================================
# VPC Network Variables
# ===========================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "MyMainVPC"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "prv_subnet_a_cidr" {
  description = "CIDR block for the Private subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "pub_subnet_a_cidr" {
  description = "CIDR block for the Public subnet A"
  type        = string
  default     = "10.0.2.0/24"
}

variable "prv_subnet_b_cidr" {
  description = "CIDR block for the Private subnet B"
  type        = string
  default     = "10.0.3.0/24"
}

variable "pub_subnet_b_cidr" {
  description = "CIDR block for the Public subnet B"
  type        = string
  default     = "10.0.4.0/24"
}

# ===========================================
# ECS Configuration (Fargate Only)
# ===========================================

variable "ecs_cluster_name" {
  description = "Name for the ECS cluster"
  type        = string
  default     = "merida-cluster"
}

variable "ecs_enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = false
}

variable "ecs_task_family" {
  description = "Family name for the ECS task definition"
  type        = string
  default     = "merida-task"
}

variable "ecs_container_name" {
  description = "Container name used inside the task definition"
  type        = string
  default     = "merida-container"
}

variable "ecs_container_image" {
  description = "Container image to run"
  type        = string
  default     = "nginx:alpine"
}

variable "ecs_container_cpu" {
  description = "CPU units reserved for the container (256, 512, 1024, etc.)"
  type        = number
  default     = 256
}

variable "ecs_container_memory" {
  description = "Memory (MB) reserved for the container"
  type        = number
  default     = 512
}

variable "ecs_container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "ecs_container_environment" {
  description = "Environment variables for the container"
  type        = list(map(string))
  default     = []
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "merida-service"
}

variable "ecs_desired_count" {
  description = "Desired number of tasks for the service"
  type        = number
  default     = 1
}

variable "ecs_create_alb" {
  description = "If true, create an ALB + target group and wire ECS service to it"
  type        = bool
  default     = false
}

variable "ecs_alb_name" {
  description = "Name prefix for the ALB resources"
  type        = string
  default     = "merida-alb"
}

variable "ecs_alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "ecs_alb_enable_deletion_protection" {
  description = "Enable deletion protection on ALB"
  type        = bool
  default     = false
}

variable "ecs_alb_certificate_arn" {
  description = "ACM certificate ARN for the ECS ALB HTTPS listener. Leave empty to disable HTTPS."
  type        = string
  default     = ""
}

variable "ecs_alb_ssl_policy" {
  description = "SSL policy to use on the ECS ALB HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "ecs_execution_role_arn" {
  description = "ARN of the Task Execution role (used by ECS to pull images / write logs). Leave empty to use lab_role_arn"
  type        = string
  default     = ""
}

variable "ecs_task_role_arn" {
  description = "ARN of the Task Role for the task (application permissions). Leave empty to use lab_role_arn"
  type        = string
  default     = ""
}

variable "ecs_health_check_enabled" {
  description = "Whether health checks are enabled"
  type        = bool
  default     = true
}

variable "ecs_health_check_interval" {
  description = "Approximate amount of time between health checks"
  type        = number
  default     = 30
}

variable "ecs_health_check_path" {
  description = "Destination for the health check request"
  type        = string
  default     = "/"
}

variable "ecs_health_check_timeout" {
  description = "Amount of time during which no response from a target means a failed health check"
  type        = number
  default     = 5
}

variable "ecs_health_check_healthy_threshold" {
  description = "Number of consecutive health check successes required before considering a target healthy"
  type        = number
  default     = 2
}

variable "ecs_health_check_unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering a target unhealthy"
  type        = number
  default     = 2
}

variable "ecs_health_check_matcher" {
  description = "Response codes to use when checking for a healthy response"
  type        = string
  default     = "200-399"
}

variable "ecs_log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

  # ===========================================
  # ECR Configuration
  # ===========================================

  variable "ecr_repository_name" {
    description = "Name of the ECR repository for backend image"
    type        = string
    default     = "merida-backend"
  }

variable "ecr_create_repository" {
  description = "Whether Terraform should create the ECR repository"
  type        = bool
  default     = true
}

  variable "ecr_image_tag_mutability" {
    description = "ECR image tag mutability (MUTABLE or IMMUTABLE)"
    type        = string
    default     = "MUTABLE"
  }

  variable "ecr_scan_on_push" {
    description = "Scan images on push to ECR"
    type        = bool
    default     = true
  }

  variable "ecr_encryption_type" {
    description = "ECR encryption type (AES256 or KMS)"
    type        = string
    default     = "AES256"
  }

  variable "ecr_image_count" {
    description = "Number of tagged images to keep in ECR"
    type        = number
    default     = 10
  }

  variable "ecr_untagged_image_days" {
    description = "Number of days to keep untagged images in ECR"
    type        = number
    default     = 7
  }

# ===========================================
# Cognito Variables
# ===========================================

variable "cognito_user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
  default     = "merida-smart-grow-users"
}

variable "cognito_domain_prefix" {
  description = "Domain prefix for Cognito hosted UI (e.g., 'merida-smart-grow'). Leave empty to skip domain creation."
  type        = string
  default     = ""
}

variable "cognito_callback_urls" {
  description = "List of allowed callback URLs for Cognito OAuth"
  type        = list(string)
  default     = ["http://localhost:3000", "http://localhost:3000/"]
}

variable "cognito_logout_urls" {
  description = "List of allowed logout URLs for Cognito OAuth"
  type        = list(string)
  default     = ["http://localhost:3000", "http://localhost:3000/"]
}

# ===========================================
# Amplify Variables
# ===========================================

variable "enable_amplify" {
  description = "Enable AWS Amplify module (set to false if AWS Academy blocks it)"
  type        = bool
  default     = true
}

variable "amplify_app_name" {
  description = "Name of the Amplify application"
  type        = string
  default     = "merida-smart-grow-frontend"
}

variable "amplify_repository_url" {
  description = "GitHub repository URL (e.g., https://github.com/username/repo)"
  type        = string
  default     = ""
}

variable "github_access_token" {
  description = "GitHub personal access token for Amplify to access the repository"
  type        = string
  sensitive   = true
  default     = ""
}

variable "amplify_main_branch" {
  description = "Main branch name for Amplify deployment"
  type        = string
  default     = "main"
}

variable "amplify_enable_pr_previews" {
  description = "Enable automatic preview environments for pull requests"
  type        = bool
  default     = false
}

variable "amplify_enable_auto_build" {
  description = "Enable automatic builds on push to main branch"
  type        = bool
  default     = true
}

variable "amplify_environment_variables" {
  description = "Additional environment variables for Amplify app"
  type        = map(string)
  default     = {}
}

variable "api_base_url" {
  description = "Base URL for the backend API (will be passed to frontend as VITE_API_BASE_URL)"
  type        = string
  default     = "http://localhost:8000"
}
