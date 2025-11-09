#!/bin/bash
# Build & push de la imagen del backend a ECR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REGION=${AWS_REGION:-us-east-1}
IMAGE_NAME=${ECR_REPOSITORY_NAME:-merida-backend}
PLATFORMS=${PLATFORMS:-linux/amd64}

TAG_INPUT=${1:-}
if [[ -n "${TAG_INPUT}" && "${TAG_INPUT}" != latest ]]; then
  CUSTOM_TAG="${TAG_INPUT}"
else
  CUSTOM_TAG="latest"
fi

if [[ "${CUSTOM_TAG}" == "latest" ]]; then
  EXTRA_TAG="$(date +%Y%m%d%H%M%S)"
  TAGS=("${CUSTOM_TAG}" "${EXTRA_TAG}")
else
  TAGS=("${CUSTOM_TAG}")
fi

echo -e "${GREEN}=== Build & Push imagen (${IMAGE_NAME}) ===${NC}"
echo "Región: ${REGION}"
echo "Plataformas: ${PLATFORMS}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "${ACCOUNT_ID}" || "${ACCOUNT_ID}" == "None" ]]; then
  echo -e "${RED}ERROR: No se pudo obtener Account ID${NC}"
  exit 1
fi

ECR_HOST="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
ECR_REPO="${ECR_HOST}/${IMAGE_NAME}"

echo -e "${YELLOW}Login a ECR...${NC}"
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR_HOST}"

echo -e "${YELLOW}Asegurando repositorio ${IMAGE_NAME}...${NC}"
aws ecr describe-repositories --repository-names "${IMAGE_NAME}" --region "${REGION}" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "${IMAGE_NAME}" --region "${REGION}"

echo -e "${YELLOW}Construyendo imagen con buildx...${NC}"
docker buildx inspect >/dev/null 2>&1 || docker buildx create --use

BUILD_TAG_ARGS=()
for tag in "${TAGS[@]}"; do
  BUILD_TAG_ARGS+=(-t "${ECR_REPO}:${tag}")
done

docker buildx build \
  --platform "${PLATFORMS}" \
  "${BUILD_TAG_ARGS[@]}" \
  --push \
  .

echo -e "${GREEN}OK - Imagen publicada:${NC}"
printf '  %s:%s\n' "${ECR_REPO}" "${CUSTOM_TAG}"
if [[ -n "${EXTRA_TAG:-}" ]]; then
  printf '  %s:%s\n' "${ECR_REPO}" "${EXTRA_TAG}"
fi
