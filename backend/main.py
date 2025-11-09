"""
FastAPI Backend para probar conexiones con AWS
- DynamoDB
- CloudWatch Logs
- IoT Core
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
import boto3
import json
import os
from datetime import datetime
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Merida Backend Test", version="1.0.0")

# Clientes AWS
dynamodb_client = boto3.client("dynamodb", region_name=os.getenv("AWS_REGION", "us-east-1"))
cloudwatch_logs = boto3.client("logs", region_name=os.getenv("AWS_REGION", "us-east-1"))
iot_client = boto3.client("iot-data", region_name=os.getenv("AWS_REGION", "us-east-1"))

# Variables de entorno
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "SmartGrowData")
IOT_ENDPOINT = os.getenv("IOT_ENDPOINT")
LOG_GROUP = os.getenv("LOG_GROUP", "/ecs/merida-backend")


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    services: Dict[str, str]


class DynamoDBWriteRequest(BaseModel):
    plot_id: str
    sensor_data: Dict[str, Any]


class IoTMessageRequest(BaseModel):
    topic: str
    payload: Dict[str, Any]


@app.get("/", response_model=HealthResponse)
async def root():
    """Health check endpoint"""
    services_status = {}
    
    # Verificar DynamoDB
    try:
        dynamodb_client.describe_table(TableName=DYNAMODB_TABLE)
        services_status["dynamodb"] = "connected"
    except Exception as e:
        services_status["dynamodb"] = f"error: {str(e)}"
    
    # Verificar CloudWatch Logs
    try:
        cloudwatch_logs.describe_log_groups(logGroupNamePrefix=LOG_GROUP, limit=1)
        services_status["cloudwatch"] = "connected"
    except Exception as e:
        services_status["cloudwatch"] = f"error: {str(e)}"
    
    # Verificar IoT Core
    try:
        if IOT_ENDPOINT:
            services_status["iot_core"] = f"endpoint: {IOT_ENDPOINT}"
        else:
            services_status["iot_core"] = "endpoint not configured"
    except Exception as e:
        services_status["iot_core"] = f"error: {str(e)}"
    
    return HealthResponse(
        status="ok",
        timestamp=datetime.utcnow().isoformat(),
        services=services_status
    )


@app.get("/health")
async def health():
    """Simple health check"""
    return {"status": "healthy", "service": "merida-backend"}


@app.post("/test/dynamodb")
async def test_dynamodb_write(request: DynamoDBWriteRequest):
    """Test escribir en DynamoDB"""
    try:
        timestamp = datetime.utcnow().isoformat()
        
        item = {
            "PK": {"S": f"PLOT#{request.plot_id}"},
            "SK": {"S": f"STATE#{timestamp}"},
            "plot_id": {"S": request.plot_id},
            "timestamp": {"S": timestamp},
            "type": {"S": "state"},
            "sensor_data": {"S": json.dumps(request.sensor_data)}
        }
        
        # Agregar GSI si existe
        if "facility_id" in request.sensor_data:
            item["GSI_PK"] = {"S": f"FACILITY#{request.sensor_data['facility_id']}"}
            item["GSI_SK"] = {"S": f"TIMESTAMP#{timestamp}"}
        
        response = dynamodb_client.put_item(
            TableName=DYNAMODB_TABLE,
            Item=item
        )
        
        logger.info(f"DynamoDB write successful: {response}")
        
        return {
            "status": "success",
            "table": DYNAMODB_TABLE,
            "plot_id": request.plot_id,
            "timestamp": timestamp,
            "response": "Item written successfully"
        }
    except Exception as e:
        logger.error(f"DynamoDB error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"DynamoDB error: {str(e)}")


@app.get("/test/dynamodb/read/{plot_id}")
async def test_dynamodb_read(plot_id: str):
    """Test leer de DynamoDB"""
    try:
        response = dynamodb_client.query(
            TableName=DYNAMODB_TABLE,
            KeyConditionExpression="PK = :pk",
            ExpressionAttributeValues={
                ":pk": {"S": f"PLOT#{plot_id}"}
            },
            Limit=10
        )
        
        items = []
        for item in response.get("Items", []):
            items.append({
                "PK": item.get("PK", {}).get("S"),
                "SK": item.get("SK", {}).get("S"),
                "timestamp": item.get("timestamp", {}).get("S"),
                "sensor_data": json.loads(item.get("sensor_data", {}).get("S", "{}"))
            })
        
        return {
            "status": "success",
            "plot_id": plot_id,
            "count": len(items),
            "items": items
        }
    except Exception as e:
        logger.error(f"DynamoDB read error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"DynamoDB read error: {str(e)}")


@app.post("/test/cloudwatch")
async def test_cloudwatch_logs(message: Dict[str, Any]):
    """Test escribir logs en CloudWatch"""
    try:
        log_message = json.dumps({
            "timestamp": datetime.utcnow().isoformat(),
            "level": "INFO",
            "message": message.get("message", "Test log message"),
            "data": message.get("data", {})
        })
        
        # Crear log stream si no existe
        stream_name = f"test-{datetime.utcnow().strftime('%Y%m%d')}"
        
        try:
            cloudwatch_logs.create_log_stream(
                logGroupName=LOG_GROUP,
                logStreamName=stream_name
            )
        except cloudwatch_logs.exceptions.ResourceAlreadyExistsException:
            pass
        
        # Escribir log
        response = cloudwatch_logs.put_log_events(
            logGroupName=LOG_GROUP,
            logStreamName=stream_name,
            logEvents=[
                {
                    "timestamp": int(datetime.utcnow().timestamp() * 1000),
                    "message": log_message
                }
            ]
        )
        
        logger.info(f"CloudWatch log written: {response}")
        
        return {
            "status": "success",
            "log_group": LOG_GROUP,
            "log_stream": stream_name,
            "message": "Log written successfully"
        }
    except Exception as e:
        logger.error(f"CloudWatch error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"CloudWatch error: {str(e)}")


@app.post("/test/iot")
async def test_iot_publish(request: IoTMessageRequest):
    """Test publicar mensaje en IoT Core"""
    try:
        if not IOT_ENDPOINT:
            raise HTTPException(
                status_code=500,
                detail="IoT endpoint not configured. Set IOT_ENDPOINT environment variable."
            )
        
        payload = json.dumps(request.payload)
        
        response = iot_client.publish(
            topic=request.topic,
            qos=1,
            payload=payload
        )
        
        logger.info(f"IoT message published: topic={request.topic}, response={response}")
        
        return {
            "status": "success",
            "topic": request.topic,
            "endpoint": IOT_ENDPOINT,
            "payload": request.payload,
            "message": "Message published successfully"
        }
    except Exception as e:
        logger.error(f"IoT Core error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"IoT Core error: {str(e)}")


@app.get("/plot/{plot_id}/status")
async def get_plot_status(plot_id: str):
    """Obtener el estado actual del plot desde DynamoDB"""
    try:
        # Query para obtener el último estado (SK más reciente)
        response = dynamodb_client.query(
            TableName=DYNAMODB_TABLE,
            KeyConditionExpression="PK = :pk AND begins_with(SK, :sk_prefix)",
            ExpressionAttributeValues={
                ":pk": {"S": f"PLOT#{plot_id}"},
                ":sk_prefix": {"S": "STATE#"}
            },
            ScanIndexForward=False,  # Ordenar en orden descendente
            Limit=1  # Solo el más reciente
        )
        
        if not response.get("Items"):
            return {
                "plot_id": plot_id,
                "status": "not_found",
                "message": f"No se encontró estado para plot {plot_id}",
                "timestamp": datetime.utcnow().isoformat()
            }
        
        # Obtener el item más reciente
        item = response["Items"][0]
        
        # Parsear datos
        sensor_data_str = item.get("sensor_data", {}).get("S", "{}")
        sensor_data = json.loads(sensor_data_str) if sensor_data_str else {}
        
        return {
            "plot_id": plot_id,
            "status": "found",
            "timestamp": item.get("timestamp", {}).get("S"),
            "sensor_data": sensor_data,
            "pk": item.get("PK", {}).get("S"),
            "sk": item.get("SK", {}).get("S")
        }
    except Exception as e:
        logger.error(f"Error getting plot status: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting plot status: {str(e)}")


@app.get("/plot/{plot_id}/history")
async def get_plot_history(plot_id: str, limit: int = 10):
    """Obtener historial de estados del plot"""
    try:
        response = dynamodb_client.query(
            TableName=DYNAMODB_TABLE,
            KeyConditionExpression="PK = :pk AND begins_with(SK, :sk_prefix)",
            ExpressionAttributeValues={
                ":pk": {"S": f"PLOT#{plot_id}"},
                ":sk_prefix": {"S": "STATE#"}
            },
            ScanIndexForward=False,  # Más reciente primero
            Limit=limit
        )
        
        history = []
        for item in response.get("Items", []):
            sensor_data_str = item.get("sensor_data", {}).get("S", "{}")
            sensor_data = json.loads(sensor_data_str) if sensor_data_str else {}
            
            history.append({
                "timestamp": item.get("timestamp", {}).get("S"),
                "sensor_data": sensor_data,
                "sk": item.get("SK", {}).get("S")
            })
        
        return {
            "plot_id": plot_id,
            "count": len(history),
            "history": history
        }
    except Exception as e:
        logger.error(f"Error getting plot history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting plot history: {str(e)}")


@app.get("/test/all")
async def test_all_services():
    """Test todas las conexiones"""
    results = {}

    # Test DynamoDB
    try:
        dynamodb_client.describe_table(TableName=DYNAMODB_TABLE)
        results["dynamodb"] = {"status": "connected", "table": DYNAMODB_TABLE}
    except Exception as e:
        results["dynamodb"] = {"status": "error", "error": str(e)}

    # Test CloudWatch
    try:
        cloudwatch_logs.describe_log_groups(logGroupNamePrefix=LOG_GROUP, limit=1)
        results["cloudwatch"] = {"status": "connected", "log_group": LOG_GROUP}
    except Exception as e:
        results["cloudwatch"] = {"status": "error", "error": str(e)}

    # Test IoT Core
    try:
        if IOT_ENDPOINT:
            results["iot_core"] = {"status": "configured", "endpoint": IOT_ENDPOINT}
        else:
            results["iot_core"] = {"status": "not_configured", "error": "IOT_ENDPOINT not set"}
    except Exception as e:
        results["iot_core"] = {"status": "error", "error": str(e)}

    return {
        "timestamp": datetime.utcnow().isoformat(),
        "results": results
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)

