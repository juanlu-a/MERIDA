#!/bin/bash

# ============================================================================
# Update GitHub Secrets with AWS Academy Credentials
# ============================================================================
# This script helps you update GitHub repository secrets with your current
# AWS Academy session credentials. You need to run this every time you start
# a new AWS Academy lab session.
#
# Prerequisites:
# - GitHub CLI (gh) installed: https://cli.github.com/
# - Logged into GitHub CLI: gh auth login
# - AWS Academy lab started and credentials file downloaded
#
# Usage:
#   ./scripts/update-github-secrets.sh [path-to-credentials-file]
#
# Example:
#   ./scripts/update-github-secrets.sh ~/Downloads/credentials.csv
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  AWS Academy GitHub Secrets Updater${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo -e "${YELLOW}   Install it from: https://cli.github.com/${NC}"
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI is not authenticated.${NC}"
    echo -e "${YELLOW}   Run: gh auth login${NC}"
    exit 1
fi

# Determine credentials source
if [ -z "$1" ]; then
    echo -e "${YELLOW}ℹ️  No credentials file provided. Trying to read from AWS CLI config...${NC}\n"

    # Try to read from AWS CLI
    if [ -f ~/.aws/credentials ]; then
        AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
        AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
        AWS_SESSION_TOKEN=$(aws configure get aws_session_token)
    else
        echo -e "${RED}❌ No AWS credentials found.${NC}"
        echo -e "${YELLOW}   Please provide the path to your credentials file:${NC}"
        echo -e "${YELLOW}   ./scripts/update-github-secrets.sh ~/Downloads/credentials.csv${NC}"
        exit 1
    fi
else
    CREDENTIALS_FILE="$1"

    # Check if credentials file exists
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        echo -e "${RED}❌ Credentials file not found: $CREDENTIALS_FILE${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Reading credentials from: $CREDENTIALS_FILE${NC}\n"

    # Parse credentials from CSV file (AWS Academy format)
    # Skip header line and read the data
    CREDENTIALS=$(tail -n 1 "$CREDENTIALS_FILE")

    # Extract credentials (format: aws_access_key_id,aws_secret_access_key,aws_session_token)
    AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | cut -d',' -f1)
    AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | cut -d',' -f2)
    AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | cut -d',' -f3)
fi

# Validate credentials are not empty
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
    echo -e "${RED}❌ Failed to extract AWS credentials.${NC}"
    echo -e "${YELLOW}   Please check your credentials file format.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Credentials Summary:${NC}"
echo -e "   Access Key ID: ${AWS_ACCESS_KEY_ID:0:10}..."
echo -e "   Secret Key: ********"
echo -e "   Session Token: ${AWS_SESSION_TOKEN:0:20}..."
echo ""

# Update GitHub secrets
echo -e "${BLUE}🔐 Updating GitHub secrets...${NC}\n"

gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
echo -e "${GREEN}✅ Updated: AWS_ACCESS_KEY_ID${NC}"

gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
echo -e "${GREEN}✅ Updated: AWS_SECRET_ACCESS_KEY${NC}"

gh secret set AWS_SESSION_TOKEN --body "$AWS_SESSION_TOKEN"
echo -e "${GREEN}✅ Updated: AWS_SESSION_TOKEN${NC}"

# Optional: Update LAB_ROLE_ARN if provided
read -p $'\n'"Enter Lab Role ARN (or press Enter to skip): " LAB_ROLE_ARN
if [ -n "$LAB_ROLE_ARN" ]; then
    gh secret set LAB_ROLE_ARN --body "$LAB_ROLE_ARN"
    echo -e "${GREEN}✅ Updated: LAB_ROLE_ARN${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅ GitHub secrets updated successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  Remember:${NC}"
echo -e "   - These credentials are session-based and will expire"
echo -e "   - Update them each time you start a new AWS Academy lab"
echo -e "   - Keep your credentials file secure and never commit it to Git"
echo ""
