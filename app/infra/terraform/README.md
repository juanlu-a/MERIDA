# MERIDA Smart Grow - Terraform Infrastructure

Infrastructure as Code for the MERIDA Smart Grow IoT Platform using Terraform.

## Architecture Overview

The infrastructure consists of the following AWS services:

- **DynamoDB** - Single-table design for storing IoT data and user information
- **Lambda** - Processes messages from IoT devices
- **IoT Core** - MQTT topic rules for device communication
- **Cognito** - User authentication and authorization
- **Amplify** - Frontend hosting and deployment
- **S3** - Storage (future implementation)

## Prerequisites

### Required Tools

1. **Terraform** >= 1.0

   ```bash
   # Install Terraform
   brew install terraform  # macOS
   # or download from https://www.terraform.io/downloads
   ```

2. **AWS CLI**

   ```bash
   # Install AWS CLI
   brew install awscli  # macOS
   # or follow: https://aws.amazon.com/cli/
   ```

3. **GitHub CLI** (for updating secrets)
   ```bash
   # Install GitHub CLI
   brew install gh  # macOS
   # or follow: https://cli.github.com/
   ```

### AWS Academy Setup

This project is designed to work with AWS Academy Lab environments, which have specific constraints:

- Session-based credentials (expire after lab session)
- Cannot create IAM roles (must use LabRole)
- Limited permissions compared to regular AWS accounts

## Quick Start

### 1. First-Time Setup (Do Once)

#### Step 1.1: Copy Environment Template

```bash
cp .env.example .env.local
```

#### Step 1.2: Set Persistent Configuration

Edit `.env.local` and configure **one-time settings** that won't change:

```bash
# AWS Account ID and LabRole (stays the same)
export TF_VAR_lab_role_arn="arn:aws:iam::037689899742:role/LabRole"

# GitHub Personal Access Token (create once, use always)
# Create at: https://github.com/settings/tokens
# Required scopes: repo, admin:repo_hook
export TF_VAR_github_access_token="ghp_your_token_here"

# Python path (after installing Python 3.11)
export PATH="/opt/homebrew/bin:$PATH"
```

### 2. Every Lab Session (AWS Academy Workflow)

#### Step 2.1: Start AWS Academy Lab

1. Go to AWS Academy Learner Lab
2. Click **"Start Lab"** and wait for green light
3. Click **"AWS Details"** → Copy credentials

#### Step 2.2: Update AWS Credentials in .env.local

Edit `.env.local` and update only the **AWS credentials section**:

```bash
# ⚠️ UPDATE THESE EVERY SESSION (they expire)
export AWS_ACCESS_KEY_ID=ASIAQRRT6HLP...
export AWS_SECRET_ACCESS_KEY=coRzy3FmnSlK...
export AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjE...
export AWS_DEFAULT_REGION=us-east-1
```

#### Step 2.3: Load Environment and Deploy

```bash
# Load credentials
source .env.local

# Navigate to terraform directory
cd app/infra/terraform

# Deploy infrastructure
terraform plan
terraform apply
```

**💡 Pro Tip**: Create an alias in your `~/.zshrc`:

```bash
alias awslab='source ~/path/to/MERIDA/.env.local && cd ~/path/to/MERIDA/app/infra/terraform'
```

Then just run: `awslab` → Update credentials → `terraform apply`

### 3. Alternative: Helper Script (Legacy)

### 3. Alternative: Helper Script (Legacy)

For AWS Academy, you can also download credentials file and use the helper script:

```bash
# Option 1: Use our helper script
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv

# Option 2: Manually set credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"
```

### 2. Initialize Terraform

```bash
cd app/infra/terraform
terraform init
```

### 3. Create terraform.tfvars

Create a `terraform.tfvars` file with your configuration:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Lab Role ARN (from AWS Academy)
lab_role_arn = "arn:aws:iam::123456789012:role/LabRole"

# Lambda Configuration (if using Docker/ECR)
lambda_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/lambda-iot-handler:latest"

# Cognito Configuration
cognito_user_pool_name   = "merida-smart-grow-users"
cognito_domain_prefix    = ""  # Leave empty or set a unique domain prefix
cognito_callback_urls    = ["http://localhost:3000", "https://your-amplify-url"]
cognito_logout_urls      = ["http://localhost:3000", "https://your-amplify-url"]

# Amplify Configuration
enable_amplify            = true  # Set to false if AWS Academy blocks Amplify
amplify_app_name         = "merida-smart-grow-frontend"
amplify_repository_url   = "https://github.com/your-username/MERIDA"
github_access_token      = "ghp_yourPersonalAccessToken"
amplify_main_branch      = "main"

# API Configuration
api_base_url = "https://your-api-gateway-url"  # Update when API Gateway is deployed

# Tags
tags = {
  Environment = "dev"
  Project     = "Merida"
  Team        = "Your Team Name"
}
```

### 4. Plan and Apply

```bash
# Review the changes
terraform plan

# Apply the infrastructure
terraform apply

# Save important outputs
terraform output > outputs.txt
```

## Module Structure

```
modules/
├── cognito/     - AWS Cognito User Pool
├── amplify/     - AWS Amplify App
├── dynamodb/    - DynamoDB table for IoT data
├── lambda/      - Lambda functions
├── iot/         - IoT Core rules and topics
└── s3/          - S3 buckets (future)
```

### Cognito Module

Creates a Cognito User Pool with:

- Email verification
- Password recovery
- Secure password policy
- User Pool Client for web applications

**Outputs:**

- `cognito_user_pool_id` - User Pool ID (needed for frontend)
- `cognito_client_id` - Client ID (needed for frontend)

### Amplify Module

Creates an AWS Amplify App with:

- GitHub integration
- Automatic builds on push
- Environment variables injection
- Custom domain support (optional)

**Important:** AWS Academy may block Amplify creation. If you encounter errors, set `enable_amplify = false` and deploy to S3 + CloudFront instead.

## Important Outputs

After running `terraform apply`, get these values:

```bash
# Get Cognito credentials for frontend
terraform output cognito_user_pool_id
terraform output cognito_client_id

# Get Amplify URL
terraform output amplify_app_url

# Get DynamoDB table name
terraform output dynamodb_table_name
```

## Updating Frontend Configuration

After deploying infrastructure:

1. Get Terraform outputs:

   ```bash
   terraform output
   ```

2. Update frontend `.env` file:

   ```bash
   cd ../../web
   cp .env.example .env
   # Edit .env with Cognito values
   ```

3. Or let Amplify handle it automatically (environment variables are injected during build)

## GitHub Actions Integration

### Setting Up GitHub Secrets

#### Required Secrets

Update these secrets each time you start an AWS Academy lab:

```bash
# Use the helper script
./scripts/update-github-secrets.sh

# Or manually set via GitHub UI:
# Settings → Secrets and variables → Actions → New repository secret
```

- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_SESSION_TOKEN` - AWS session token (required for AWS Academy)
- `LAB_ROLE_ARN` - LabRole ARN from AWS Academy
- `GH_PAT` - GitHub Personal Access Token (for Amplify)

#### Optional Secrets/Variables

- `VITE_COGNITO_USER_POOL_ID` - Auto-populated by Terraform, but can override
- `VITE_COGNITO_CLIENT_ID` - Auto-populated by Terraform, but can override

### Creating a GitHub Personal Access Token

For Amplify to access your repository:

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Set expiration (recommend 90 days)
4. Select scopes:
   - `repo` (all)
   - `admin:repo_hook` (all)
5. Generate and copy the token
6. Add it as `GH_PAT` secret in your repository

## Troubleshooting

### Amplify Creation Fails

AWS Academy might not support AWS Amplify. Solutions:

1. **Disable Amplify module:**

   ```hcl
   enable_amplify = false
   ```

2. **Use Amplify Console UI instead:**

   - Go to AWS Amplify Console
   - Click "New app" → "Host web app"
   - Connect your GitHub repository
   - Amplify will auto-detect build settings from `amplify.yml`

3. **Alternative: Deploy to S3 + CloudFront**
   - Create S3 bucket for static hosting
   - Use GitHub Actions to sync build files
   - (Terraform module coming soon)

### Session Token Expired

AWS Academy sessions expire. When you see authentication errors:

```bash
# Update credentials
./scripts/update-github-secrets.sh ~/Downloads/new-credentials.csv

# Or update environment variables
export AWS_SESSION_TOKEN="new-token"
```

### terraform init Fails

If you see provider download errors:

```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

### Resource Already Exists

If resources were created outside Terraform:

```bash
# Import existing resource
terraform import module.cognito.aws_cognito_user_pool.main us-east-1_ABC123

# Or delete and recreate
aws cognito-idp delete-user-pool --user-pool-id us-east-1_ABC123
terraform apply
```

## State Management

Currently using **local state** (terraform.tfstate file).

**Important:**

- Do NOT commit `terraform.tfstate` to Git
- Backup your state file regularly
- Consider using remote state for team collaboration

### Enabling Remote State (Future)

Uncomment and configure in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "merida/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Cleanup

To destroy all infrastructure:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm with: yes
```

**Warning:** This will delete:

- Cognito User Pool (all users will be deleted)
- DynamoDB table (all data will be deleted)
- Amplify app
- All other managed resources

## Variables Reference

See `variables.tf` for all available configuration options.

### Required Variables

- `lab_role_arn` - LabRole ARN from AWS Academy

### Optional Variables

All other variables have sensible defaults. Override in `terraform.tfvars` as needed.

## Contributing

When modifying infrastructure:

1. Create a feature branch
2. Make changes
3. Run `terraform fmt -recursive`
4. Run `terraform validate`
5. Create a pull request
6. GitHub Actions will run `terraform plan`

## Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [AWS Academy Learner Lab](https://awsacademy.instructure.com/)

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review Terraform and AWS documentation
3. Create an issue in the GitHub repository
