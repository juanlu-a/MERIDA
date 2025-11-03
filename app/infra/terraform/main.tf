terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# ===========================================
# Cognito Module - User Authentication
# ===========================================
module "cognito" {
  source = "./modules/cognito"

  user_pool_name = var.cognito_user_pool_name
  domain_prefix  = var.cognito_domain_prefix
  callback_urls  = var.cognito_callback_urls
  logout_urls    = var.cognito_logout_urls

  tags = var.tags
}

# ===========================================
# Amplify Module - Frontend Hosting
# ===========================================
# NOTE: AWS Academy might not support Amplify.
# If you encounter permission errors, use Amplify Console UI
# or consider S3 + CloudFront as an alternative.
module "amplify" {
  source = "./modules/amplify"

  count = var.enable_amplify ? 1 : 0 # Optional: disable if AWS Academy blocks it

  app_name             = var.amplify_app_name
  repository_url       = var.amplify_repository_url
  github_access_token  = var.github_access_token
  main_branch_name     = var.amplify_main_branch
  iam_service_role_arn = var.lab_role_arn

  # Pass Cognito configuration as environment variables
  environment_variables = merge(
    var.amplify_environment_variables,
    {
      VITE_AWS_REGION           = var.aws_region
      VITE_COGNITO_USER_POOL_ID = module.cognito.user_pool_id
      VITE_COGNITO_CLIENT_ID    = module.cognito.user_pool_client_id
      VITE_API_BASE_URL         = var.api_base_url
    }
  )

  enable_auto_branch_creation = var.amplify_enable_pr_previews
  enable_auto_build           = var.amplify_enable_auto_build

  tags = var.tags
}
