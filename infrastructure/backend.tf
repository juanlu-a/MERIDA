# Backend configuration
# Uncomment and configure when ready to use remote state

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "merida/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }

# For local development, use local backend:
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
