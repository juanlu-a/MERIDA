# Infrastructure Deployment Summary

**Date**: November 3, 2025  
**Status**: ✅ Successfully Deployed  
**Resources Created**: 42 AWS Resources

## 📋 Deployed Infrastructure

### **VPC & Networking**
- VPC ID: `vpc-065aa365f6b443fa4`
- CIDR Block: `10.0.0.0/16`
- Availability Zones: `us-east-1a`, `us-east-1b`
- Private Subnets: 
  - Subnet A: `subnet-0ffa315bda519d978` (10.0.1.0/24)
  - Subnet B: `subnet-0d3472789551eed01` (10.0.3.0/24)
- Public Subnets:
  - Subnet A: `subnet-0681c617b39199e50` (10.0.2.0/24)
  - Subnet B: `subnet-0227bd65f2e2b1853` (10.0.4.0/24)
- Internet Gateway: `igw-035b8184327ac017c`
- NAT Gateway: Configured for private subnet outbound access

### **VPC Endpoints** (Private AWS Service Access)
- S3 Gateway Endpoint: `vpce-0d26fd205962ee6e3`
- DynamoDB Gateway Endpoint: `vpce-0fb42b8fe37f014d4`
- ECR API Interface Endpoint: `vpce-09efb2f5f73d1d429`
- ECR DKR Interface Endpoint: `vpce-021082021f92f76b6`
- CloudWatch Logs Interface Endpoint: `vpce-0cf96dd0bdf966e98`

### **Cognito (Authentication)** 🔐
- **User Pool ID**: `us-east-1_FYMYK5jN1`
- **Client ID**: `11plns2dpqj8gpsqirg1plocke`
- **Region**: `us-east-1`
- **User Pool ARN**: `arn:aws:cognito-idp:us-east-1:037689899742:userpool/us-east-1_FYMYK5jN1`
- **Endpoint**: `cognito-idp.us-east-1.amazonaws.com/us-east-1_FYMYK5jN1`

### **ECS Fargate (Backend API)** 🚀
- **Cluster**: `merida-cluster`
- **Service**: `merida-service`
- **Task Definition**: `merida-task:8`
- **Load Balancer DNS**: `merida-alb-95037053.us-east-1.elb.amazonaws.com`
- **API URL**: `http://merida-alb-95037053.us-east-1.elb.amazonaws.com`
- **Container Port**: 80
- **Health Check**: `/` (HTTP 200-399)
- **Log Group**: `/ecs/merida-cluster/merida-task`

### **ECR (Container Registry)** 📦
- **Repository**: `merida-backend`
- **URI**: `037689899742.dkr.ecr.us-east-1.amazonaws.com/merida-backend`
- **Lifecycle Policy**: Keep last 5 images

### **DynamoDB (Database)** 💾
- **Table Name**: `SmartGrowData`
- **Billing Mode**: PAY_PER_REQUEST (On-Demand)
- **ARN**: `arn:aws:dynamodb:us-east-1:037689899742:table/SmartGrowData`
- **Point-in-Time Recovery**: Enabled
- **Global Secondary Index**: GSI

### **Lambda & IoT** ⚡
- **Lambda Function**: `Lambda-IoT-Handler`
- **Runtime**: Python 3.9
- **Memory**: 256 MB
- **Timeout**: 30 seconds
- **Log Group**: `/aws/lambda/Lambda-IoT-Handler` (7 days retention)
- **IoT Rule**: `iot_to_lambda_rule`
- **IoT Topic Pattern**: `system/plot/+`
- **Function ARN**: `arn:aws:lambda:us-east-1:037689899742:function:Lambda-IoT-Handler`

---

## 🔧 Configuration Files Updated

### 1. Frontend Environment (`.env`)
```bash
VITE_API_BASE_URL=http://merida-alb-95037053.us-east-1.elb.amazonaws.com
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_FYMYK5jN1
VITE_COGNITO_CLIENT_ID=11plns2dpqj8gpsqirg1plocke
VITE_APP_NAME=MERIDA Smart Grow
VITE_APP_VERSION=1.0.0
```

### 2. GitHub Secrets (CI/CD)
- ✅ `AWS_ACCESS_KEY_ID`
- ✅ `AWS_SECRET_ACCESS_KEY`
- ✅ `AWS_SESSION_TOKEN`
- ✅ `LAB_ROLE_ARN`
- ✅ `GH_PAT`
- ✅ `VITE_COGNITO_USER_POOL_ID` (NEW)
- ✅ `VITE_COGNITO_CLIENT_ID` (NEW)
- ✅ `VITE_API_BASE_URL` (NEW)

---

## 📝 Next Steps

### 1. **Build and Deploy Backend Docker Image**

```bash
# Navigate to backend directory
cd app/server

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  037689899742.dkr.ecr.us-east-1.amazonaws.com

# Build the Docker image
docker build -t merida-backend .

# Tag the image
docker tag merida-backend:latest \
  037689899742.dkr.ecr.us-east-1.amazonaws.com/merida-backend:latest

# Push to ECR
docker push 037689899742.dkr.ecr.us-east-1.amazonaws.com/merida-backend:latest

# Force ECS to deploy new image
aws ecs update-service \
  --cluster merida-cluster \
  --service merida-service \
  --force-new-deployment \
  --region us-east-1
```

### 2. **Test Frontend Locally**

```bash
# Navigate to frontend directory
cd app/web

# Install dependencies (if needed)
npm install

# Start development server
npm run dev

# Frontend will be available at http://localhost:5173
```

### 3. **Create Test Cognito User**

```bash
# Create a user
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --user-attributes Name=email,Value=testuser@example.com \
  --temporary-password "TempPass123!" \
  --region us-east-1

# Set permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_FYMYK5jN1 \
  --username testuser@example.com \
  --password "YourSecurePass123!" \
  --permanent \
  --region us-east-1
```

### 4. **Test IoT Data Flow**

```bash
# Publish a test message to IoT Core
aws iot-data publish \
  --topic "system/plot/test-plot-1" \
  --payload '{"temperature":25.5,"humidity":60,"soil_moisture":45}' \
  --region us-east-1

# Check Lambda logs
aws logs tail /aws/lambda/Lambda-IoT-Handler --follow --region us-east-1

# Verify data in DynamoDB
aws dynamodb scan --table-name SmartGrowData --region us-east-1
```

---

## 🔍 Monitoring & Debugging

### Check ECS Service Status
```bash
aws ecs describe-services \
  --cluster merida-cluster \
  --services merida-service \
  --region us-east-1
```

### View ECS Task Logs
```bash
aws logs tail /ecs/merida-cluster/merida-task --follow --region us-east-1
```

### Check ALB Target Health
```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:037689899742:targetgroup/merida-alb-tg/912137c54c9c8590 \
  --region us-east-1
```

### Test API Endpoint
```bash
curl http://merida-alb-95037053.us-east-1.elb.amazonaws.com/
curl http://merida-alb-95037053.us-east-1.elb.amazonaws.com/health
```

---

## ⚠️ Important Notes

1. **AWS Academy Session**: Remember that AWS Academy credentials expire after a few hours. You'll need to update them regularly:
   ```bash
   export AWS_ACCESS_KEY_ID="your-new-key"
   export AWS_SECRET_ACCESS_KEY="your-new-secret"
   export AWS_SESSION_TOKEN="your-new-token"
   ```

2. **Backend Container**: The ECS service is running but needs the Docker image pushed to ECR to function properly.

3. **IoT Core Endpoint Not Created**: The IoT Core VPC Endpoint was disabled because it's not available in all regions. IoT devices will connect through the internet gateway.

4. **Python Version**: Lambda is configured with Python 3.9 for local development compatibility. GitHub Actions uses Python 3.11.

5. **DynamoDB On-Demand**: Using PAY_PER_REQUEST pricing model - only pay for actual reads/writes.

---

## 🧹 Cleanup (When Done)

To destroy all infrastructure:

```bash
cd app/infra/terraform
terraform destroy
```

**Warning**: This will delete all data in DynamoDB and all container images in ECR!

---

## 📚 Additional Resources

- [Terraform Outputs Reference](./app/infra/terraform/outputs.tf)
- [AWS Console - ECS](https://console.aws.amazon.com/ecs/)
- [AWS Console - Cognito](https://console.aws.amazon.com/cognito/)
- [AWS Console - DynamoDB](https://console.aws.amazon.com/dynamodb/)
- [AWS Console - IoT Core](https://console.aws.amazon.com/iot/)
