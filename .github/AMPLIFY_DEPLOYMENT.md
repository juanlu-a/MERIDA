# GitHub Actions - Amplify Deployment Setup

## 🚀 What's New

Your GitHub Actions workflow has been updated to automatically deploy to AWS Amplify when code is pushed to the `main` branch.

## 📋 Required Setup

### 1. GitHub Secrets

You need to add these secrets to your GitHub repository:

```bash
# Go to: GitHub Repository → Settings → Secrets and variables → Actions
```

**Required Secrets:**

- `AWS_ACCESS_KEY_ID` - Your AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY` - Your AWS Secret Access Key

### 2. Get AWS Credentials

#### Option A: From AWS Academy Lab

```bash
# In your AWS Academy Lab, go to AWS Details → Show → Copy credentials
# Look for:
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."  # Not needed for this workflow
```

#### Option B: From IAM User (if using regular AWS account)

```bash
# Create an IAM user with these permissions:
# - AWSAmplifyFullAccess
# - Or create custom policy with amplify:* permissions
```

### 3. Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add these secrets:

```
Name: AWS_ACCESS_KEY_ID
Value: ASIA... (your access key)

Name: AWS_SECRET_ACCESS_KEY
Value: ... (your secret key)
```

## 🔄 How the New Workflow Works

### On Pull Request:

- ✅ Runs linting and type checking
- ✅ Builds the application
- ✅ Comments on PR with results

### On Push to Main:

- ✅ Runs all the above tests
- ✅ **NEW:** Triggers AWS Amplify deployment
- ✅ **NEW:** Waits for deployment completion
- ✅ **NEW:** Provides deployment status and URL

## 🛠 Workflow Features

### Build & Test Job:

- Uses `pnpm` (faster than npm)
- Caches dependencies for speed
- Runs linting, type checking, and build
- Uploads build artifacts

### Deploy Job (Main branch only):

- Downloads build artifacts
- Configures AWS credentials
- Finds your Amplify app automatically
- Triggers deployment via AWS CLI
- Waits for completion (up to 10 minutes)
- Provides deployment URL and status

## 📁 Files Updated

1. **`.github/workflows/deploy-frontend.yml`** - Enhanced CI/CD workflow
2. **`app/web/amplify.yml`** - Updated to use pnpm instead of npm

## 🔧 Configuration

The workflow uses these environment variables:

```yaml
env:
  NODE_VERSION: "20"
  AWS_REGION: "us-east-1"
  AMPLIFY_APP_NAME: "MERIDA-Smart-Grow" # Make sure this matches your app name
```

**Important:** Make sure `AMPLIFY_APP_NAME` matches the name of your Amplify app in AWS.

## 🚨 Troubleshooting

### If deployment fails:

1. **Check Amplify app name:**

   ```bash
   aws amplify list-apps --query "apps[*].{Name:name,AppId:appId}"
   ```

2. **Verify AWS credentials have Amplify permissions**

3. **Check GitHub Actions logs** for detailed error messages

4. **Manual deployment test:**

   ```bash
   # Test AWS CLI access
   aws amplify list-apps

   # Trigger manual deployment
   aws amplify start-job --app-id YOUR_APP_ID --branch-name main --job-type RELEASE
   ```

## 🎯 Next Steps

1. ✅ Add AWS credentials to GitHub secrets
2. ✅ Verify Amplify app name in workflow
3. ✅ Push to main branch to test deployment
4. ✅ Check Amplify Console for deployment status

## 📞 Support

If you encounter issues:

- Check GitHub Actions logs
- Verify AWS permissions
- Ensure Amplify app exists and is configured
- Check AWS region matches (`us-east-1`)

## 🔗 Useful Links

- [AWS Amplify Console](https://console.aws.amazon.com/amplify)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS CLI Amplify Commands](https://docs.aws.amazon.com/cli/latest/reference/amplify/)
