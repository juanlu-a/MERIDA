# MERIDA Smart Grow - Terraform Infrastructure

Infrastructure as Code for the MERIDA Smart Grow IoT Platform using Terraform.

## Architecture Overview

The infrastructure consists of the following AWS services:

- **DynamoDB** - Single-table design for storing IoT data and user information
- **Lambda** - Processes IoT ingestion and DynamoDB stream alerts
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

### 1. Configure AWS Credentials

For AWS Academy, download your credentials file and run:

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

### Lambda Functions

- **IoT Handler (`lambda_iot_handler`)**  
  Receives MQTT payloads from IoT Core, normalizes the message and stores it in the `SmartGrowData` DynamoDB table using the single-table design.

- **Alert Processor (`lambda_alert_processor`)**  
  Subscribed to the DynamoDB stream of `SmartGrowData`. When a new plot state (`PK = PLOT#<id>`, `SK = STATE#<timestamp>`) is inserted, it:
  1. Reads the live measurements (temperature, humidity, light, irrigation, etc.).
  2. Fetches the ideal parameters for the species (`PK = FACILITY#<facility_id>`, `SK = SPECIES#<id>`).
  3. Applies the tolerance defined by `alert_lambda_tolerance` (default ±10%).
  4. If a deviation exists, lists all Cognito users and publishes an email alert through the `merida-alerts-topic` SNS topic.

Environment variables injected by Terraform:

| Variable            | Description                                                    |
|---------------------|----------------------------------------------------------------|
| `DYNAMO_TABLE_NAME` | DynamoDB table name (SmartGrowData)                            |
| `USER_POOL_ID`      | Cognito User Pool ID used to fetch user emails                 |
| `ALERTS_TOPIC_ARN`  | SNS topic that delivers alert emails                           |
| `TOLERANCE_PERCENT` | Decimal tolerance applied to compare live vs. ideal readings   |

IAM permissions granted to the alert processor Lambda allow it to query DynamoDB, list Cognito users, publish to SNS, and write CloudWatch Logs.

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

# Get alert processing resources
terraform output alert_lambda_function_name
terraform output alerts_sns_topic_arn
```

## DynamoDB Table Structure

La tabla `SmartGrowData` sigue un diseño de tabla única. Las claves principales (`PK`, `SK`) y atributos auxiliares se reutilizan para múltiples tipos de entidad:

| Caso de uso                               | `PK` ejemplo              | `SK` ejemplo                      | Comentarios clave |
|-------------------------------------------|---------------------------|-----------------------------------|-------------------|
| Estado de una parcela (ingestión IoT)     | `PLOT#<plot_id>`          | `STATE#<timestamp>`               | Contiene lecturas como `temperature`, `humidity`, `light`, `irrigation`, `SpeciesId`, `FacilityId`, además de `Timestamp`. |
| Eventos asociados (riego, etc.)           | `PLOT#<plot_id>`          | `EVENT#<timestamp>`               | Prefija atributos específicos (`irrigation_amount`, etc.). |
| Parámetros ideales por especie/facilidad  | `FACILITY#<facility_id>`  | `SPECIES#<species_id>`            | Atributos como `IdealTemperature`, `IdealHumidity`, `IdealLight`, `IdealIrrigation`. El Lambda de alertas consulta estos valores. |
| Perfil global de especie (fallback)       | `SPECIES#<species_id>`    | `PROFILE`                         | Útil cuando no hay registro específico por instalación. |
| Relación negocio → instalaciones/usuarios | `BUSINESS#<business_id>`  | `FACILITY#<facility_id>`          | Puede almacenar colecciones de usuarios (`Users`) u otros metadatos del negocio. |

Índices secundarios:

- `GSI_PK` / `GSI_SK`: permiten consultas adicionales. Por ejemplo, las mediciones IoT guardan `GSI_PK = FACILITY#<facility_id>` y `GSI_SK = TIMESTAMP#<timestamp>` para obtener históricos por instalación ordenados por tiempo.

Streams y automatizaciones:

- La tabla tiene **DynamoDB Streams** habilitado (`NEW_AND_OLD_IMAGES`). El módulo `lambda_alert_processor` se activa en cada `INSERT` de estados (`STATE#`) para verificar desviaciones y publicar alertas por SNS/Cognito.

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
