# 🚀 MERIDA Smart Grow - Deployment Guide

**Complete step-by-step guide to deploy your IoT platform**

---

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] AWS Academy Lab started and running
- [ ] GitHub account with repository created
- [ ] Git installed on your computer
- [ ] Terraform installed (>= 1.0)
- [ ] GitHub CLI installed (`gh`)
- [ ] Node.js 20+ installed

---

## 🔧 Part 1: Initial Setup (One-Time)

### Step 1.1: Install Required Tools

#### Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**Windows:**
```bash
winget install --id GitHub.cli
```

#### Install Terraform

**macOS:**
```bash
brew install terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
unzip terraform_1.9.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Windows:**
Download from https://www.terraform.io/downloads

#### Verify installations

```bash
gh --version       # Should show version
terraform version  # Should show 1.x
node --version     # Should show 20.x or higher
```

### Step 1.2: Login to GitHub CLI

```bash
gh auth login
```

Follow the prompts:
1. Select: **GitHub.com**
2. Select: **HTTPS**
3. Authenticate with: **Login with a web browser**
4. Copy the code and press Enter
5. Paste code in browser and authorize

✅ **Verify:** Run `gh auth status` - should show "Logged in"

### Step 1.3: Create GitHub Personal Access Token

This token allows Amplify to access your repository.

1. **Open GitHub in browser:**
   - Go to https://github.com/settings/tokens

2. **Generate new token:**
   - Click: **"Tokens (classic)"** → **"Generate new token (classic)"**

3. **Configure token:**
   - **Note:** "MERIDA Amplify Access"
   - **Expiration:** 90 days
   - **Select scopes:**
     - ✅ `repo` (all sub-items)
     - ✅ `admin:repo_hook` (all sub-items)

4. **Generate and save:**
   - Click **"Generate token"**
   - **⚠️ IMPORTANT:** Copy the token NOW (starts with `ghp_`)
   - Save it temporarily in a notes app

✅ **You should have:** A token like `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## 🔐 Part 2: Configure AWS Academy Credentials (Do This Every Lab Session)

### Step 2.1: Start Your AWS Academy Lab

1. Go to your AWS Academy course
2. Click **"Learner Lab"**
3. Click **"Start Lab"**
4. Wait for the indicator to turn **green**

### Step 2.2: Download AWS Credentials

1. In the lab, click **"AWS Details"**
2. Click **"Download PEM"** (if needed for SSH)
3. Click **"Show"** next to AWS CLI credentials
4. Copy the credentials OR download as CSV

You should see something like:
```
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

### Step 2.3: Get Your Lab Role ARN

1. Still in "AWS Details", look for **IAM Role**
2. Copy the full ARN, it looks like:
   ```
   arn:aws:iam::123456789012:role/LabRole
   ```
3. Save this - you'll need it multiple times

### Step 2.4: Update GitHub Secrets

**Option A: Using the Helper Script (Recommended)**

```bash
# Navigate to project root
cd /path/to/MERIDA

# Run the helper script
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv
```

When prompted, paste your **Lab Role ARN**

**Option B: Manual via GitHub CLI**

```bash
# Set each secret individually
gh secret set AWS_ACCESS_KEY_ID --body "ASIA..."
gh secret set AWS_SECRET_ACCESS_KEY --body "..."
gh secret set AWS_SESSION_TOKEN --body "..."
gh secret set LAB_ROLE_ARN --body "arn:aws:iam::123456789012:role/LabRole"
gh secret set GH_PAT --body "ghp_your_github_token_here"
```

**Option C: Manual via GitHub Web UI**

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** for each:
   - Name: `AWS_ACCESS_KEY_ID`, Value: `ASIA...`
   - Name: `AWS_SECRET_ACCESS_KEY`, Value: `...`
   - Name: `AWS_SESSION_TOKEN`, Value: `...`
   - Name: `LAB_ROLE_ARN`, Value: `arn:aws:iam::123456789012:role/LabRole`
   - Name: `GH_PAT`, Value: `ghp_...`

✅ **Verify:** Go to Settings → Secrets and variables → Actions - you should see all 5 secrets

---

## 🏗️ Part 3: Deploy Infrastructure with Terraform

### Step 3.1: Configure AWS CLI Locally

```bash
# Set environment variables (valid for current terminal session)
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
export AWS_REGION="us-east-1"

# Verify it works
aws sts get-caller-identity
```

You should see your account ID and role information.

### Step 3.2: Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

Save this number (e.g., `123456789012`)

### Step 3.3: Create terraform.tfvars

```bash
cd app/infra/terraform

# Create the file
nano terraform.tfvars
```

**Paste this content** (replace with YOUR values):

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Lab Role ARN - REPLACE WITH YOUR ARN
lab_role_arn = "arn:aws:iam::123456789012:role/LabRole"

# Lambda Configuration (if you've deployed the Lambda Docker image)
# If not deployed yet, comment out this line
# lambda_image_uri = "123456789012.dkr.ecr.us-east-1.amazonaws.com/lambda-iot-handler:latest"

# Cognito Configuration
cognito_user_pool_name = "merida-smart-grow-users"
cognito_domain_prefix  = ""  # Leave empty for now
cognito_callback_urls  = ["http://localhost:3000", "http://localhost:3000/"]
cognito_logout_urls    = ["http://localhost:3000", "http://localhost:3000/"]

# Amplify Configuration
enable_amplify         = true
amplify_app_name       = "merida-smart-grow-frontend"

# REPLACE with your GitHub repository URL
amplify_repository_url = "https://github.com/YOUR_USERNAME/MERIDA"

# REPLACE with your GitHub Personal Access Token
github_access_token    = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

amplify_main_branch          = "main"
amplify_enable_pr_previews   = false
amplify_enable_auto_build    = true

# API Configuration (update later when you have API Gateway)
api_base_url = "http://localhost:8000"

# Tags
tags = {
  Environment = "dev"
  Project     = "Merida"
  Team        = "Your Team Name"
}
```

**Save the file:** Press `Ctrl+X`, then `Y`, then `Enter`

### Step 3.4: Initialize Terraform

```bash
cd app/infra/terraform
terraform init
```

You should see: **"Terraform has been successfully initialized!"**

### Step 3.5: Review the Plan

```bash
terraform plan
```

Review the output. You should see it will create:
- 1 Cognito User Pool
- 1 Cognito User Pool Client
- 1 Amplify App
- 1 Amplify Branch
- Plus existing resources (DynamoDB, Lambda, IoT)

### Step 3.6: Apply the Infrastructure

```bash
terraform apply
```

When prompted:
1. Review the changes
2. Type **`yes`**
3. Press Enter

⏱️ **This will take 2-5 minutes**

✅ **Success looks like:**
```
Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:

cognito_user_pool_id = "us-east-1_AbC123"
cognito_client_id = "abc123def456..."
amplify_app_url = "https://main.d1234abcd.amplifyapp.com"
...
```

### Step 3.7: Save the Outputs

```bash
# Save all outputs to a file for reference
terraform output > ../../../terraform-outputs.txt

# Display Cognito credentials (you'll need these)
terraform output cognito_user_pool_id
terraform output cognito_client_id
```

📝 **Copy these values** - you'll need them next!

---

## 🎨 Part 4: Configure Frontend

### Step 4.1: Navigate to Frontend Directory

```bash
cd ../../web
```

### Step 4.2: Create .env File

```bash
# Copy the example
cp .env.example .env

# Edit the file
nano .env
```

### Step 4.3: Update .env with Terraform Outputs

Replace the values with YOUR Terraform outputs:

```env
# API Configuration
VITE_API_BASE_URL=http://localhost:8000

# AWS Cognito Configuration
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_AbC123     # FROM TERRAFORM OUTPUT
VITE_COGNITO_CLIENT_ID=abc123def456...          # FROM TERRAFORM OUTPUT

# Application Configuration
VITE_APP_NAME=MERIDA Smart Grow
VITE_APP_VERSION=1.0.0
```

**Save the file:** Press `Ctrl+X`, then `Y`, then `Enter`

### Step 4.4: Install Dependencies

```bash
npm install
```

⏱️ **This will take 1-2 minutes**

### Step 4.5: Test Frontend Locally

```bash
npm run dev
```

You should see:
```
  VITE v7.x.x  ready in XXX ms

  ➜  Local:   http://localhost:3000/
  ➜  Network: use --host to expose
```

✅ **Open http://localhost:3000 in your browser**

You should see the login page!

**Stop the dev server:** Press `Ctrl+C`

---

## 👤 Part 5: Create Your First User

### Step 5.1: Create a Cognito User

**Option A: Using AWS Console**

1. Go to AWS Console → Cognito
2. Click on your User Pool: **"merida-smart-grow-users"**
3. Click **"Users"** → **"Create user"**
4. Fill in:
   - Username: Your email
   - Email: Same email
   - Temporary password: Choose a strong password
   - Uncheck "Send invitation"
5. Click **"Create user"**

**Option B: Using AWS CLI**

```bash
# Replace with your email
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_AbC123 \
  --username your.email@example.com \
  --user-attributes Name=email,Value=your.email@example.com Name=email_verified,Value=true \
  --temporary-password "TempPassword123!" \
  --message-action SUPPRESS

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_AbC123 \
  --username your.email@example.com \
  --password "YourPassword123!" \
  --permanent
```

### Step 5.2: Test Login Locally

```bash
# Start the dev server
npm run dev
```

1. Open http://localhost:3000
2. You'll be redirected to login
3. Enter:
   - **Username:** your.email@example.com
   - **Password:** YourPassword123!
4. You should see the Dashboard!

🎉 **Success!** Your frontend is working with Cognito authentication!

---

## 🌐 Part 6: Deploy Frontend to AWS Amplify

### Step 6.1: Commit and Push Your Code

```bash
# Go to project root
cd ../../../

# Check status
git status

# Add all new files
git add .

# Commit
git commit -m "Add Cognito auth and Amplify infrastructure"

# Push to GitHub
git push origin main
```

### Step 6.2: Watch GitHub Actions

1. Go to your GitHub repository
2. Click **"Actions"** tab
3. You should see a workflow running: **"Deploy Frontend to AWS Amplify"**
4. Click on it to watch progress

### Step 6.3: Approve Deployment

1. Wait for the "Build Frontend" job to complete (2-3 minutes)
2. The "Deploy to AWS Amplify" job will show **"Waiting"**
3. Click **"Review deployments"**
4. Check **"production"**
5. Click **"Approve and deploy"**

⏱️ **Deployment will take 3-5 minutes**

### Step 6.4: Get Your Live URL

After deployment completes:

1. Check the Actions log for the deployed URL
2. OR run:
   ```bash
   cd app/infra/terraform
   terraform output amplify_app_url
   ```
3. OR go to AWS Amplify Console

✅ **Open the URL** - your app is now live!

---

## 🔄 Part 7: Updating Callback URLs (Important!)

Now that you have a live URL, update Cognito callbacks:

### Step 7.1: Update terraform.tfvars

```bash
cd app/infra/terraform
nano terraform.tfvars
```

Update these lines with your Amplify URL:

```hcl
cognito_callback_urls  = [
  "http://localhost:3000",
  "http://localhost:3000/",
  "https://main.d1234abcd.amplifyapp.com",        # ADD YOUR URL
  "https://main.d1234abcd.amplifyapp.com/"        # ADD YOUR URL
]

cognito_logout_urls    = [
  "http://localhost:3000",
  "http://localhost:3000/",
  "https://main.d1234abcd.amplifyapp.com",        # ADD YOUR URL
  "https://main.d1234abcd.amplifyapp.com/"        # ADD YOUR URL
]
```

### Step 7.2: Apply Changes

```bash
terraform apply
```

Type **`yes`** when prompted.

### Step 7.3: Test Live App

1. Open your Amplify URL
2. Try logging in with your Cognito user
3. You should be able to access the Dashboard!

---

## 🎯 Part 8: Everyday Workflow

### When You Start a New AWS Academy Lab Session

**AWS Academy credentials expire when you stop the lab!**

Every time you start a new lab session:

```bash
# 1. Start your AWS Academy Lab

# 2. Download new credentials

# 3. Update GitHub Secrets
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv

# 4. Update local environment
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# 5. Continue working!
```

### Making Changes to Frontend

```bash
# 1. Make your changes in app/web/src/

# 2. Test locally
cd app/web
npm run dev

# 3. Commit and push
git add .
git commit -m "Your changes"
git push origin main

# 4. GitHub Actions will auto-deploy!
# 5. Approve the deployment in GitHub Actions
```

### Making Infrastructure Changes

```bash
# 1. Edit Terraform files in app/infra/terraform/

# 2. Review changes
cd app/infra/terraform
terraform plan

# 3. Apply changes
terraform apply

# 4. If Cognito outputs changed, update frontend .env
```

---

## ❗ Troubleshooting

### Issue: Terraform fails with "Error: Unauthorized"

**Solution:**
```bash
# Your AWS session expired
# Update credentials:
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Then try again
terraform apply
```

### Issue: Amplify creation fails with "AccessDenied"

**AWS Academy might block Amplify creation.**

**Solution 1:** Use Amplify Console UI
```bash
# 1. Disable in terraform.tfvars
enable_amplify = false

# 2. Apply
terraform apply

# 3. Create app manually:
# - Go to AWS Amplify Console
# - Click "New app" → "Host web app"
# - Connect GitHub repo
# - Amplify will auto-detect build settings
```

**Solution 2:** Deploy to S3 instead (contact me if needed)

### Issue: GitHub Actions fails with authentication error

**Solution:**
```bash
# Update GitHub secrets (they expired)
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv
```

### Issue: Cannot login to frontend

**Solutions:**

1. **Check Cognito user exists:**
   ```bash
   aws cognito-idp list-users --user-pool-id us-east-1_AbC123
   ```

2. **Check callback URLs are correct:**
   - Must match exactly with your Amplify URL
   - Update in terraform.tfvars and run `terraform apply`

3. **Check .env file:**
   ```bash
   cat app/web/.env
   # Verify User Pool ID and Client ID match Terraform outputs
   ```

### Issue: "Module not found" in frontend

**Solution:**
```bash
cd app/web
rm -rf node_modules package-lock.json
npm install
```

---

## 📞 Getting Help

1. **Check logs:**
   - GitHub Actions logs in "Actions" tab
   - Terraform errors in terminal
   - Browser console (F12) for frontend errors

2. **Verify setup:**
   ```bash
   # Check Terraform state
   cd app/infra/terraform
   terraform show

   # Check GitHub secrets
   gh secret list

   # Check AWS credentials
   aws sts get-caller-identity
   ```

3. **Common commands:**
   ```bash
   # Re-initialize Terraform
   cd app/infra/terraform
   rm -rf .terraform .terraform.lock.hcl
   terraform init

   # Rebuild frontend
   cd app/web
   rm -rf node_modules dist
   npm install
   npm run build

   # Check Amplify app status
   aws amplify list-apps
   ```

---

## ✅ Checklist: Are You Done?

- [ ] GitHub secrets configured
- [ ] Terraform deployed successfully
- [ ] Cognito User Pool created
- [ ] Cognito user created
- [ ] Frontend works locally (http://localhost:3000)
- [ ] Frontend deployed to Amplify
- [ ] Can login to live app
- [ ] Callback URLs updated with Amplify URL

If all checked: **🎉 Congratulations! Your deployment is complete!**

---

## 📚 Quick Reference

### Important Files
- `app/infra/terraform/terraform.tfvars` - Terraform configuration
- `app/web/.env` - Frontend environment variables
- `.github/workflows/deploy-frontend.yml` - Deployment workflow

### Important Commands
```bash
# Update AWS credentials
./scripts/update-github-secrets.sh

# Deploy infrastructure
cd app/infra/terraform && terraform apply

# Start frontend locally
cd app/web && npm run dev

# Get Terraform outputs
cd app/infra/terraform && terraform output
```

### Important URLs
- GitHub Actions: `https://github.com/YOUR_USERNAME/MERIDA/actions`
- AWS Amplify Console: https://console.aws.amazon.com/amplify/
- AWS Cognito Console: https://console.aws.amazon.com/cognito/

---

## 🎓 Next Steps

Once everything is working:

1. **Connect backend:** Update `VITE_API_BASE_URL` when backend is deployed
2. **Add more users:** Create additional Cognito users
3. **Customize:** Modify frontend components in `app/web/src/`
4. **Add features:** Implement additional pages and functionality
5. **Monitor:** Check CloudWatch logs for Lambda and Amplify

**Happy coding! 🚀**
