import os
import boto3
from dotenv import load_dotenv
load_dotenv()

TABLE_NAME = os.environ.get("DYNAMO_TABLE_NAME", "SmartGrowData")
REGION = os.environ.get("AWS_REGION", "us-east-1")

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)


import boto3
import asyncio
from botocore.exceptions import ClientError
import os

TABLE_NAME = os.getenv("DYNAMO_TABLE_NAME")
REGION = os.getenv("AWS_REGION", "us-east-1")

dynamodb = boto3.client("dynamodb", region_name=REGION)

def _create_table_sync():
    """Función bloqueante que usa boto3 para crear la tabla si no existe."""
    try:
        tables = dynamodb.list_tables()["TableNames"]
        if TABLE_NAME in tables:
            print(f"✅ Tabla '{TABLE_NAME}' ya existe.")
            return

        print(f"⚙️ Creando tabla '{TABLE_NAME}'...")
        dynamodb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[
                {"AttributeName": "pk", "KeyType": "HASH"},
                {"AttributeName": "sk", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "pk", "AttributeType": "S"},
                {"AttributeName": "sk", "AttributeType": "S"},
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        # Espera a que la tabla esté activa
        waiter = dynamodb.get_waiter("table_exists")
        waiter.wait(TableName=TABLE_NAME)
        print(f"✅ Tabla '{TABLE_NAME}' creada correctamente.")

    except ClientError as e:
        print(f"❌ Error al crear/verificar la tabla: {e}")

async def init_db():
    """Versión asíncrona que no bloquea FastAPI."""
    await asyncio.to_thread(_create_table_sync)

