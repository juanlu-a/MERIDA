#!/bin/bash
# =============================================================================
# Create Cognito Test Users for MERIDA Smart Grow
# =============================================================================
# This script creates test users in AWS Cognito for development/testing
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
USER_POOL_ID="us-east-1_FYMYK5jN1"
REGION="us-east-1"

echo "=========================================="
echo "🔐 MERIDA Cognito User Creation"
echo "=========================================="
echo ""
echo "User Pool ID: $USER_POOL_ID"
echo "Region: $REGION"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials are not configured${NC}"
    echo "Please configure AWS credentials first"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI is configured${NC}"
echo ""

# Function to create user
create_user() {
    local USERNAME=$1
    local PASSWORD=$2
    local NAME=$3
    
    echo -e "${YELLOW}Creating user: $USERNAME${NC}"
    
    # Check if user already exists
    if aws cognito-idp admin-get-user \
        --user-pool-id "$USER_POOL_ID" \
        --username "$USERNAME" \
        --region "$REGION" &> /dev/null; then
        echo -e "${YELLOW}⚠️  User $USERNAME already exists, skipping...${NC}"
        return
    fi
    
    # Create user
    aws cognito-idp admin-create-user \
        --user-pool-id "$USER_POOL_ID" \
        --username "$USERNAME" \
        --user-attributes \
            Name=email,Value="$USERNAME" \
            Name=name,Value="$NAME" \
            Name=email_verified,Value=true \
        --message-action SUPPRESS \
        --region "$REGION" &> /dev/null
    
    # Set permanent password
    aws cognito-idp admin-set-user-password \
        --user-pool-id "$USER_POOL_ID" \
        --username "$USERNAME" \
        --password "$PASSWORD" \
        --permanent \
        --region "$REGION" &> /dev/null
    
    echo -e "${GREEN}✓ Created: $USERNAME${NC}"
    echo "   Password: $PASSWORD"
    echo ""
}

echo "Creating test users..."
echo ""

# Create Admin User
create_user "admin@merida.com" "Admin123!" "Admin User"

# Create Regular Users
create_user "user1@merida.com" "User123!" "User One"
create_user "user2@merida.com" "User123!" "User Two"
create_user "test@merida.com" "Test123!" "Test User"

echo "=========================================="
echo -e "${GREEN}✅ All users created successfully!${NC}"
echo "=========================================="
echo ""
echo "📝 Test Credentials:"
echo "--------------------"
echo "Admin:"
echo "  Email:    admin@merida.com"
echo "  Password: Admin123!"
echo ""
echo "User 1:"
echo "  Email:    user1@merida.com"
echo "  Password: User123!"
echo ""
echo "User 2:"
echo "  Email:    user2@merida.com"
echo "  Password: User123!"
echo ""
echo "Test User:"
echo "  Email:    test@merida.com"
echo "  Password: Test123!"
echo ""
echo "🌐 Login at: http://localhost:5173"
echo ""
echo "To view all users:"
echo "  aws cognito-idp list-users --user-pool-id $USER_POOL_ID --region $REGION"
echo ""
