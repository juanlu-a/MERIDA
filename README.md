# Merida - Smart Grow IoT Platform

Sistema de IoT para gestión inteligente de cultivos utilizando AWS IoT Core, Lambda, DynamoDB y Terraform.

## Arquitectura

```
Raspberry Pi (Sensores)
    ↓ publish
AWS IoT Core (system/plot/<plot_id>)
    ↓ IoT Rule
Lambda IoT Handler
    ↓ write
DynamoDB (SmartGrowData)
```

## Componentes

### 1. Infrastructure (Terraform)

Infraestructura como código para desplegar todos los recursos AWS:

- **IoT Core**: Policies, Topic Rules, Certificates
- **Lambda**: Function para procesar mensajes IoT (Docker/ECR)
- **DynamoDB**: Base de datos con Single-Table Design
- **IAM**: Permisos y roles

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

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

## Estructura del Proyecto

```
Merida/
├── infrastructure/           # Terraform IaC
│   ├── main.tf              # Configuración principal
│   ├── variables.tf         # Variables de entrada
│   ├── outputs.tf           # Outputs
│   ├── terraform.tfvars     # Valores de variables (no commitear con datos reales)
│   └── modules/             # Módulos Terraform
│       ├── lambda/          # Módulo Lambda (wrapper del oficial)
│       ├── dynamodb/        # Módulo DynamoDB
│       ├── iot/             # Módulo IoT Core
│       └── s3/              # Módulo S3
├── lambdas/                 # Código de las Lambdas
│   └── lambda_iot_handler/  # Lambda para procesar IoT
│       ├── app.py           # Código Python
│       ├── Dockerfile       # Imagen Docker
│       ├── requirements.txt # Dependencias
│       ├── deploy.sh        # Script de deployment
│       └── README.md        # Documentación
├── .env.example             # Template de variables de entorno
├── .gitignore               # Archivos ignorados por git
└── README.md                # Este archivo
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

