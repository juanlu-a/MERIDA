# ⚡ Quick Start Guide - MERIDA Smart Grow

**For when you've already done the initial setup and just need the commands.**

---

## 🚀 Every Lab Session (AWS Academy)

### 1. Start AWS Lab & Update Credentials

```bash
# Download credentials from AWS Academy Lab

# Update GitHub secrets
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv

# Set local environment (copy from AWS Details)
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_REGION="us-east-1"

# Verify
aws sts get-caller-identity
```

---

## 🏗️ Deploy Infrastructure (First Time or After Changes)

```bash
cd app/infra/terraform

# Plan (optional - to see what will change)
terraform plan

# Apply
terraform apply
# Type: yes

# Save outputs
terraform output > ../../../outputs.txt
terraform output cognito_user_pool_id
terraform output cognito_client_id
```

---

## 🎨 Configure Frontend (First Time)

```bash
cd app/web

# Create .env from template
cp .env.example .env

# Edit .env with values from: terraform output
nano .env

# Install dependencies
npm install
```

---

## 💻 Local Development

```bash
# Start frontend dev server
cd app/web
npm run dev
# Open: http://localhost:3000
```

---

## 👤 Create Cognito User (First Time)

```bash
# Get User Pool ID
cd app/infra/terraform
POOL_ID=$(terraform output -raw cognito_user_pool_id)

# Create user
aws cognito-idp admin-create-user \
  --user-pool-id $POOL_ID \
  --username your.email@example.com \
  --user-attributes Name=email,Value=your.email@example.com Name=email_verified,Value=true \
  --temporary-password "TempPass123!" \
  --message-action SUPPRESS

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $POOL_ID \
  --username your.email@example.com \
  --password "YourPassword123!" \
  --permanent
```

---

## 🚢 Deploy to Production

```bash
# Commit changes
git add .
git commit -m "Your message"
git push origin main

# Go to GitHub Actions
# https://github.com/YOUR_USERNAME/MERIDA/actions

# Wait for build → Approve deployment → Done!
```

---

## 🔄 Update Workflow

### Making Frontend Changes
```bash
cd app/web

# Make changes in src/
# Test locally
npm run dev

# Deploy
git add .
git commit -m "Update: description"
git push origin main

# Approve in GitHub Actions
```

### Making Infrastructure Changes
```bash
cd app/infra/terraform

# Edit .tf files
# Review
terraform plan

# Apply
terraform apply

# If Cognito changed, update app/web/.env
```

---

## 📊 Useful Commands

```bash
# Get all Terraform outputs
cd app/infra/terraform
terraform output

# Get specific output
terraform output cognito_user_pool_id
terraform output amplify_app_url

# List GitHub secrets
gh secret list

# List Cognito users
POOL_ID=$(terraform output -raw cognito_user_pool_id)
aws cognito-idp list-users --user-pool-id $POOL_ID

# Check Amplify app status
aws amplify list-apps

# Frontend type check
cd app/web
npm run type-check

# Frontend lint
npm run lint

# Build frontend locally
npm run build
```

---

## ⚠️ Quick Fixes

### AWS Session Expired
```bash
# Re-export credentials
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

### GitHub Actions Failing
```bash
# Update secrets
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv
```

### Terraform State Issues
```bash
cd app/infra/terraform
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Frontend Build Issues
```bash
cd app/web
rm -rf node_modules package-lock.json dist
npm install
```

---

## 📂 File Locations

| What | Where |
|------|-------|
| Terraform config | `app/infra/terraform/terraform.tfvars` |
| Frontend env | `app/web/.env` |
| Update secrets script | `scripts/update-github-secrets.sh` |
| GitHub Actions | `.github/workflows/` |
| Full guide | `DEPLOYMENT_GUIDE.md` |

---

## 🆘 Emergency Teardown

```bash
# Destroy all infrastructure
cd app/infra/terraform
terraform destroy
# Type: yes

# ⚠️ WARNING: This deletes everything!
```

---

**Need detailed instructions? See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
