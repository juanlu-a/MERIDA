#!/bin/bash
# Script para construir y desplegar Lambda IoT Handler con Docker

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Desplegando Lambda IoT Handler con Docker${NC}"
echo ""

# Variables
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REPO_NAME="merida-lambda-iot-handler"
export IMAGE_TAG="latest"

echo -e "${YELLOW}Configuración:${NC}"
echo "  Region: ${AWS_REGION}"
echo "  Account: ${AWS_ACCOUNT_ID}"
echo "  Repository: ${REPO_NAME}"
echo ""

# 1. Crear repositorio ECR si no existe
echo -e "${BLUE}Verificando repositorio ECR...${NC}"
aws ecr describe-repositories --repository-names ${REPO_NAME} --region ${AWS_REGION} 2>/dev/null || \
  aws ecr create-repository --repository-name ${REPO_NAME} --region ${AWS_REGION}

# 2. Login a ECR
echo -e "${BLUE}Login a ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# 3. Construir imagen (manifest Docker v2, sin attestations)
echo -e "${BLUE}Construyendo imagen Docker para amd64...${NC}"
docker buildx build \
  --platform linux/amd64 \
  --provenance=false \
  --sbom=false \
  --load \
  --no-cache \
  -t ${REPO_NAME}:${IMAGE_TAG} .

# 4. Tagear imagen
echo -e "${BLUE}Tageando imagen...${NC}"
docker tag ${REPO_NAME}:${IMAGE_TAG} \
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}

# 5. Push a ECR
echo -e "${BLUE}Pusheando imagen a ECR...${NC}"
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}

# 6. Obtener URI de la imagen
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"

echo ""
echo -e "${GREEN}Imagen desplegada exitosamente!${NC}"
echo ""
echo -e "${YELLOW}URI de la imagen:${NC}"
echo "  ${IMAGE_URI}"
echo ""
echo -e "${YELLOW}Siguiente paso:${NC}"
echo "  Actualiza infrastructure/terraform.tfvars con:"
echo "  lambda_image_uri = \"${IMAGE_URI}\""
echo ""
echo -e "${YELLOW}Luego ejecuta:${NC}"
echo "  cd ../../infrastructure"
echo "  terraform apply"
echo ""

