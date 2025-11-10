# GitHub Actions Workflows

## Frontend CI/CD (`deploy-frontend.yml`)

### Purpose

Validates frontend code quality and build integrity. AWS Amplify handles the actual deployment automatically when changes are pushed to `main`.

### Workflow Triggers

- **Pull Requests** to `main` branch (validates code)
- **Pushes** to `main` branch (validates and lets Amplify auto-deploy)
- **Manual** via workflow_dispatch

### What it does

1. ✅ Runs ESLint checks
2. ✅ Runs TypeScript type checking
3. ✅ Builds the application
4. 💬 Comments on PRs with validation results
5. 🚀 Amplify auto-deploys after merge to `main`

### Amplify Configuration

Make sure in your AWS Amplify Console:

- App is connected to the GitHub repository
- `main` branch has auto-build enabled
- Build settings use `app/web/amplify.yml`

### No AWS Credentials Needed

Since Amplify auto-deploys from GitHub, this workflow doesn't need AWS credentials. It only validates code quality.

---

## Backend CI/CD (`deploy-backend.yml`)

Handles ECS backend deployments.

## Lambda Deployments

- `deploy-lambda-alert-processor.yml`
- `deploy-lambda-iot-handler.yml`

## Terraform (`terraform-plan.yml`)

Infrastructure as Code validation and planning.
