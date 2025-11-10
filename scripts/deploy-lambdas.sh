#!/bin/bash

# Script para deployment manual de lambdas (ZIP deployment)
# Ambas lambdas usan ZIP file deployment (no ECR/Docker)
# Uso: ./scripts/deploy-lambdas.sh [iot-handler|alert-processor|all]

set -e

AWS_REGION="us-east-1"
LAMBDA_IOT_HANDLER="merida-iot-handler"
LAMBDA_ALERT_PROCESSOR="lambda_alert_processor"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

function deploy_iot_handler() {
    print_info "Deploying Lambda IoT Handler..."
    
    cd app/infra/lambdas/lambda_iot_handler
    
    # Create temp directory
    rm -rf package lambda_iot_handler.zip
    mkdir -p package
    
    # Install dependencies
    print_info "Installing dependencies..."
    pip install -r requirements.txt -t package/
    
    # Copy Lambda code
    print_info "Copying Lambda code..."
    cp app.py package/
    
    # Create ZIP
    print_info "Creating deployment package..."
    cd package
    zip -r ../lambda_iot_handler.zip .
    cd ..
    
    # Upload to Lambda
    print_info "Uploading to Lambda..."
    aws lambda update-function-code \
        --function-name $LAMBDA_IOT_HANDLER \
        --zip-file fileb://lambda_iot_handler.zip \
        --region $AWS_REGION
    
    # Wait for update to complete
    print_info "Waiting for Lambda update to complete..."
    aws lambda wait function-updated --function-name $LAMBDA_IOT_HANDLER --region $AWS_REGION
    
    # Publish version
    VERSION=$(aws lambda publish-version --function-name $LAMBDA_IOT_HANDLER --region $AWS_REGION --query 'Version' --output text)
    print_info "Published Lambda version: $VERSION"
    
    # Cleanup
    rm -rf package lambda_iot_handler.zip
    
    cd ../../../../
    print_info "Lambda IoT Handler deployed successfully!"
}

function deploy_alert_processor() {
    print_info "Deploying Lambda Alert Processor..."
    
    cd app/infra/lambdas/lambda_alert_processor
    
    # Create temp directory
    rm -rf package lambda_alert_processor.zip
    mkdir -p package
    
    # Install dependencies
    print_info "Installing dependencies..."
    pip install -r requirements.txt -t package/
    
    # Copy Lambda code
    print_info "Copying Lambda code..."
    cp app.py package/
    
    # Create ZIP
    print_info "Creating deployment package..."
    cd package
    zip -r ../lambda_alert_processor.zip .
    cd ..
    
    # Upload to Lambda
    print_info "Uploading to Lambda..."
    aws lambda update-function-code \
        --function-name $LAMBDA_ALERT_PROCESSOR \
        --zip-file fileb://lambda_alert_processor.zip \
        --region $AWS_REGION
    
    # Wait for update to complete
    print_info "Waiting for Lambda update to complete..."
    aws lambda wait function-updated --function-name $LAMBDA_ALERT_PROCESSOR --region $AWS_REGION
    
    # Publish version
    VERSION=$(aws lambda publish-version --function-name $LAMBDA_ALERT_PROCESSOR --region $AWS_REGION --query 'Version' --output text)
    print_info "Published Lambda version: $VERSION"
    
    # Cleanup
    rm -rf package lambda_alert_processor.zip
    
    cd ../../../../
    print_info "Lambda Alert Processor deployed successfully!"
}

# Main
case "$1" in
    iot-handler)
        deploy_iot_handler
        ;;
    alert-processor)
        deploy_alert_processor
        ;;
    all)
        deploy_iot_handler
        echo ""
        deploy_alert_processor
        ;;
    *)
        print_error "Usage: $0 [iot-handler|alert-processor|all]"
        exit 1
        ;;
esac

print_info "Deployment completed!"

