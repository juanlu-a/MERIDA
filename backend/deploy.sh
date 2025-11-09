#!/bin/bash
# Build y push SIEMPRE a :latest para ECR (plataforma linux/amd64)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REGION=${AWS_REGION:-us-east-1}
IMAGE_NAME="merida-backend"
PLATFORM="linux/amd64"

echo -e "${GREEN}=== Build & Push a :latest (platform=${PLATFORM}) ===${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "${ACCOUNT_ID}" ] || [ "${ACCOUNT_ID}" = "None" ]; then
  echo -e "${RED}ERROR: No se pudo obtener Account ID${NC}"
  exit 1
fi

ECR_HOST="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
ECR_REPO="${ECR_HOST}/${IMAGE_NAME}"

echo -e "${YELLOW}Login a ECR...${NC}"
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR_HOST}"

echo -e "${YELLOW}Asegurando repositorio...${NC}"
aws ecr describe-repositories --repository-names "${IMAGE_NAME}" --region "${REGION}" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "${IMAGE_NAME}" --region "${REGION}"

echo -e "${YELLOW}Construyendo imagen con buildx para ${PLATFORM}...${NC}"
docker buildx inspect >/dev/null 2>&1 || docker buildx create --use
docker buildx build \
  --platform "${PLATFORM}" \
  -t "${ECR_REPO}:latest" \
  --push \
  .

echo -e "${GREEN}OK - Imagen publicada:${NC} ${ECR_REPO}:latest"

