# Merida - Smart Grow IoT Platform

Sistema de IoT para gestión inteligente de cultivos utilizando AWS IoT Core, Lambda, DynamoDB y Terraform.

## Arquitectura

```
Raspberry Pi (Sensores)          Usuario (Web/Mobile)
    ↓ publish (MQTT)                  ↓ https
AWS IoT Core                      AWS Amplify (Frontend)
    ↓ IoT Rule                        ↓ auth
Lambda IoT Handler                AWS Cognito
    ↓ write                           ↓ API calls
DynamoDB (SmartGrowData) ←────────────┘
```

## Componentes

### 1. Infrastructure (Terraform)

Infraestructura como código para desplegar todos los recursos AWS:

- **IoT Core**: Policies, Topic Rules, Certificates
- **Lambda**: Function para procesar mensajes IoT (Docker/ECR)
- **DynamoDB**: Base de datos con Single-Table Design
- **Cognito**: User Pool para autenticación de usuarios
- **Amplify**: Hosting y deployment del frontend React
- **IAM**: Permisos y roles

```bash
cd app/infra/terraform
terraform init
terraform plan
terraform apply
```

Ver documentación completa en [app/infra/terraform/README.md](app/infra/terraform/README.md)

### 2. Lambda IoT Handler

Lambda function que procesa mensajes desde IoT Core y los guarda en DynamoDB.

**Tipos de mensajes soportados:**

#### STATE - Lecturas de sensores
```json
{
  "plot_id": "123",
  "type": "state",
  "timestamp": "2025-01-01T12:00:00Z",
  "sensor_data": {
    "temperature": 25.5,
    "humidity": 60.0,
    "soil_moisture": 45.2,
    "light": 800
  }
}
```

#### EVENT - Eventos de riego
```json
{
  "type": "event",
  "plot_id": "123",
  "timestamp": "2025-01-01T13:00:00Z",
  "irrigation": {
    "milliliters": 100
  }
}
```

**Deployment con Docker:**
```bash
cd lambdas/lambda_iot_handler
./deploy.sh
```

### 3. DynamoDB Table

**Tabla:** SmartGrowData

**Estructura:**
- **PK**: `PLOT#<plot_id>`
- **SK**: `STATE#<timestamp>` o `EVENT#<timestamp>`
- **GSI_PK**: `FACILITY#<facility_id>`
- **GSI_SK**: `TIMESTAMP#<timestamp>`

### 4. Frontend (React + TypeScript + Vite)

Aplicación web para monitoreo y gestión de cultivos:

**Stack:**
- React 18 + TypeScript
- Vite (build tool)
- Tailwind CSS
- React Router
- Zustand (state management)
- React Query (data fetching)
- Recharts (visualización de datos)
- AWS Amplify (authentication)

**Características:**
- Dashboard con visualización en tiempo real de sensores
- Gestión de plots y facilities
- Autenticación con AWS Cognito
- Gráficas históricas de datos de sensores
- Responsive design

```bash
cd app/web
npm install
npm run dev
```

Ver documentación completa en [app/web/README.md](app/web/README.md)

### 5. CI/CD (GitHub Actions)

Workflows automatizados para deployment:

**Workflows:**
- **deploy-frontend.yml**: Deploy del frontend a AWS Amplify
  - Trigger: Push a main (cambios en app/web)
  - Build, test, y deploy automático
  - Requiere aprobación manual (environment: production)

- **terraform-plan.yml**: Plan de cambios en infraestructura
  - Trigger: Pull Request (cambios en app/infra/terraform)
  - Comenta el plan en el PR
  - Apply manual via workflow_dispatch

**Configuración de Secrets (AWS Academy):**

```bash
# Usar el script helper
./scripts/update-github-secrets.sh ~/Downloads/credentials.csv
```

Secrets requeridos:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (AWS Academy)
- `LAB_ROLE_ARN`
- `GH_PAT` (GitHub Personal Access Token)
- `VITE_COGNITO_USER_POOL_ID` (auto-poblado por Terraform)
- `VITE_COGNITO_CLIENT_ID` (auto-poblado por Terraform)

## Estructura del Proyecto

```
MERIDA/
├── .github/
│   └── workflows/           # GitHub Actions CI/CD
│       ├── deploy-frontend.yml    # Deploy frontend a Amplify
│       └── terraform-plan.yml     # Terraform plan en PRs
├── app/
│   ├── web/                 # Frontend React + TypeScript
│   │   ├── src/
│   │   │   ├── components/  # Componentes React
│   │   │   ├── pages/       # Páginas (Dashboard, Plots, Auth)
│   │   │   ├── layouts/     # Layouts (MainLayout, AuthLayout)
│   │   │   ├── hooks/       # Custom hooks (useAuth, useQueries)
│   │   │   ├── services/    # API services (Axios)
│   │   │   ├── store/       # Zustand stores
│   │   │   ├── types/       # TypeScript types
│   │   │   ├── config/      # Configuración (Auth, API)
│   │   │   └── utils/       # Utilidades
│   │   ├── package.json
│   │   ├── vite.config.ts
│   │   ├── amplify.yml      # Configuración AWS Amplify
│   │   └── README.md
│   ├── server/              # Backend FastAPI (Python)
│   │   ├── src/
│   │   │   ├── dal/         # Data Access Layer
│   │   │   ├── routers/     # API endpoints
│   │   │   ├── schemas/     # Pydantic models
│   │   │   └── utils/       # Utilities
│   │   └── requirements.txt
│   └── infra/               # Infraestructura
│       ├── terraform/       # Terraform IaC
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── backend.tf
│       │   ├── terraform.tfvars  # (no commitear)
│       │   ├── README.md
│       │   └── modules/
│       │       ├── cognito/      # User authentication
│       │       ├── amplify/      # Frontend hosting
│       │       ├── dynamodb/     # Database
│       │       ├── lambda/       # Lambda functions
│       │       ├── iot/          # IoT Core rules
│       │       └── s3/           # Storage
│       └── lambdas/
│           └── lambda_iot_handler/
│               ├── app.py
│               ├── Dockerfile
│               ├── requirements.txt
│               ├── deploy.sh
│               └── README.md
├── scripts/
│   └── update-github-secrets.sh  # Helper para actualizar secrets
├── .gitignore
└── README.md
```

## Setup

### Requisitos

- AWS Account (AWS Academy Learner Lab)
- Terraform >= 1.5
- Docker Desktop
- AWS CLI v2
- Python 3.12+

### Configuración inicial

1. **Clonar el repositorio:**
```bash
git clone https://github.com/tu-usuario/merida.git
cd merida
```

2. **Configurar credenciales AWS:**

Crear archivo `.env` con tus credenciales de AWS Academy:
```bash
cp .env.example .env
# Editar .env con tus credenciales
```

Cargar las credenciales:
```bash
source .env
```

3. **Configurar Terraform:**

Editar `infrastructure/terraform.tfvars`:
```hcl
# Obtener ARN del LabRole
lab_role_arn = "arn:aws:iam::ACCOUNT_ID:role/LabRole"

# Configurar región
aws_region = "us-east-1"

# Para deployment con Docker (recomendado)
lambda_image_uri = "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/merida-lambda-iot-handler:latest"
```

4. **Desplegar Lambda con Docker:**
```bash
cd lambdas/lambda_iot_handler
./deploy.sh
# Copiar el URI de la imagen y pegarlo en terraform.tfvars
```

5. **Desplegar infraestructura:**
```bash
cd ../../infrastructure
terraform init
terraform apply
```

## Flujo de Trabajo

### Actualizar código de Lambda

```bash
# 1. Editar código
vim lambdas/lambda_iot_handler/app.py

# 2. Rebuild y push a ECR
cd lambdas/lambda_iot_handler
./deploy.sh

# 3. Actualizar Lambda en AWS
cd ../../infrastructure
terraform apply -replace="module.lambda_iot_handler.module.lambda_function.aws_lambda_function.this[0]"
```

### Actualizar infraestructura

```bash
cd infrastructure

# Ver cambios
terraform plan

# Aplicar cambios
terraform apply
```

### Destruir infraestructura

```bash
cd infrastructure
terraform destroy
```

## Topics MQTT

### Publicación (Raspberry Pi)
- `system/plot/<plot_id>`: Raspberry publica sensores y eventos

### Suscripción (Backend ECS)
- `plot/<plot_id>`: Backend publica comandos y configuraciones

## Seguridad

- Certificados X.509 para cada dispositivo IoT
- Policies de IoT Core con permisos granulares
- ClientId matching con Thing Name
- Aislamiento entre dispositivos por plot_id
- Credenciales en `.env` (no commiteadas)

## Tecnologías

- **IaC**: Terraform
- **Cloud**: AWS (IoT Core, Lambda, DynamoDB, ECR, S3, EventBridge)
- **Runtime**: Python 3.12
- **Container**: Docker
- **IoT Protocol**: MQTT

## Licencia

MIT

## Autor

Camila Ferreira

