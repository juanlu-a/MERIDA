# Lambda IoT Handler

Lambda function para procesar mensajes de AWS IoT Core y guardarlos en DynamoDB.

## Descripción

Esta Lambda:
- Recibe mensajes del topic `system/plot/+`
- Procesa **dos tipos** de mensajes: `state` y `event`
- Guarda los datos en DynamoDB usando patrón Single-Table Design

##  Tipos de Mensajes

### 1. **STATE** - Lecturas de Sensores

Mensajes con datos de sensores (temperatura, humedad, etc.)

**Estructura:**
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

**Se guarda en DynamoDB como:**
```json
{
    "PK": "PLOT#123",
    "SK": "STATE#2025-01-01T12:00:00Z",
    "Type": "state",
    "Timestamp": "2025-01-01T12:00:00Z",
    "GSI_PK": "FACILITY#1",
    "GSI_SK": "TIMESTAMP#2025-01-01T12:00:00Z",
    "temperature": 25.5,
    "humidity": 60.0,
    "soil_moisture": 45.2,
    "light": 800
}
```

### 2. **EVENT** - Eventos de Riego

Mensajes de eventos como activación de riego, alertas, etc.

**Estructura:**
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

**Se guarda en DynamoDB como:**
```json
{
    "PK": "PLOT#123",
    "SK": "EVENT#2025-01-01T13:00:00Z",
    "Type": "event",
    "Timestamp": "2025-01-01T13:00:00Z",
    "GSI_PK": "FACILITY#1",
    "GSI_SK": "TIMESTAMP#2025-01-01T13:00:00Z",
    "irrigation_milliliters": 100
}
```

## Deployment con Docker

### Build y Push a ECR

```bash
# Ejecutar script de deployment
cd lambdas/lambda_iot_handler
chmod +x deploy.sh
./deploy.sh
```

Este script automáticamente:
- Crea el repositorio ECR si no existe
- Hace login a ECR
- Construye la imagen Docker
- Pushea a ECR
- Muestra el URI de la imagen para Terraform


## Notas

- El campo `type` es opcional, por defecto asume `"state"` para compatibilidad
- Los eventos de irrigation prefijan los campos con `irrigation_` para evitar conflictos
- El `timestamp` se genera automáticamente si no se proporciona
- Todos los datos se almacenan en una sola tabla (SmartGrowData)

