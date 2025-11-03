terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ===========================================
# Lambda Function using official module
# ===========================================
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = var.function_name
  description   = var.description

  # Deployment mode: ZIP or Docker/ECR
  # When image_uri is set, use container image; otherwise use source code (ZIP)
  create_package = var.image_uri == null
  package_type   = var.image_uri != null ? "Image" : "Zip"

  # ZIP deployment parameters (ONLY when image_uri is null)
  handler     = var.image_uri == null ? var.handler : null
  runtime     = var.image_uri == null ? var.runtime : null
  source_path = var.image_uri == null ? var.source_path : null

  # Docker/ECR deployment (ONLY when image_uri is set)
  image_uri = var.image_uri

  # Use existing LabRole (AWS Academy)
  create_role = var.create_role
  lambda_role = var.lambda_role

  # Performance configuration
  timeout     = var.timeout
  memory_size = var.memory_size

  # Environment variables
  environment_variables = var.environment_variables

  # CloudWatch Logs
  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = var.tags
}
