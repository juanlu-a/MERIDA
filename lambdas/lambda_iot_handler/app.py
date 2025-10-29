import json
import boto3
import os
from datetime import datetime
from decimal import Decimal
import re

# Initialize DynamoDB client
# AWS_REGION is automatically available in Lambda environment
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'SmartGrowData')
table = dynamodb.Table(table_name)

# Get AWS region from Lambda environment (automatically set by AWS)
aws_region = os.environ.get('AWS_REGION', 'us-east-1')

def lambda_handler(event, context):
    """
    Lambda handler for IoT messages
    Processes messages from system/plot/+ topics
    Uses single-table design pattern with PK/SK
    """
    print(f"Received event: {json.dumps(event, default=str)}")
    
    try:
        # Extract plot_id from event
        # The event contains the sensor data directly
        plot_id = extract_plot_id_from_event(event)
        
        if not plot_id:
            print(f"Warning: Could not extract plot_id, using UNKNOWN")
            plot_id = "UNKNOWN"
        
        # Format data for DynamoDB (Single-Table Design)
        item = format_for_dynamodb(event, plot_id)
        
        # Save to DynamoDB
        response = table.put_item(Item=item)
        
        print(f"Successfully saved item to DynamoDB: PK={item['PK']}, SK={item['SK']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data saved successfully',
                'PK': item['PK'],
                'SK': item['SK']
            })
        }
        
    except Exception as e:
        print(f"Error processing message: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def extract_plot_id_from_event(event):
    """
    Extract plot_id from event
    Expects: {"plot_id": "123", "sensor_data": {...}}
    """
    return str(event.get('plot_id', 'UNKNOWN'))


def format_for_dynamodb(payload, plot_id):
    """
    Format the payload for DynamoDB using Single-Table Design
    
    Handles two types of messages:
    1. "state" - Sensor data readings
    2. "event" - Events like irrigation
    
    DynamoDB structure:
    - PK: PLOT#<plot_id>
    - SK: STATE#<timestamp> or EVENT#<timestamp>
    - GSI_PK: FACILITY#<facility_id>
    - GSI_SK: TIMESTAMP#<timestamp>
    - Type-specific data as top-level attributes
    """
    # Use provided timestamp or generate new one
    if 'timestamp' in payload and payload['timestamp']:
        timestamp = payload['timestamp']
    else:
        timestamp = datetime.utcnow().isoformat() + 'Z'
    
    # Get message type (default to 'state' for backwards compatibility)
    message_type = payload.get('type', 'state')
    
    # Convert numeric values to Decimal for DynamoDB compatibility
    def convert_to_decimal(obj):
        if isinstance(obj, float):
            return Decimal(str(obj))
        elif isinstance(obj, dict):
            return {k: convert_to_decimal(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [convert_to_decimal(item) for item in obj]
        else:
            return obj
    
    # Create base DynamoDB item
    item = {
        'PK': f'PLOT#{plot_id}',
        'Timestamp': timestamp,
        'GSI_PK': 'FACILITY#1',  # You can make this dynamic based on your logic
        'GSI_SK': f'TIMESTAMP#{timestamp}',
    }
    
    # Process based on message type
    if message_type == 'state':
        # STATE message: sensor readings
        item['SK'] = f'STATE#{timestamp}'
        sensor_data = payload.get('sensor_data', {})
        sensor_data_converted = convert_to_decimal(sensor_data)
        if isinstance(sensor_data_converted, dict):
            item.update(sensor_data_converted)
    
    elif message_type == 'event':
        # EVENT message: irrigation, alerts, etc.
        item['SK'] = f'EVENT#{timestamp}'
        
        # Add irrigation data if present
        if 'irrigation' in payload:
            irrigation_data = convert_to_decimal(payload['irrigation'])
            if isinstance(irrigation_data, dict):
                # Prefix irrigation fields to avoid conflicts
                for key, value in irrigation_data.items():
                    item[f'irrigation_{key}'] = value
        
        # Add any other event data
        for key, value in payload.items():
            if key not in ['type', 'plot_id', 'timestamp', 'irrigation']:
                item[key] = convert_to_decimal(value)
    
    else:
        # Unknown type, use generic SK
        item['SK'] = f'DATA#{timestamp}'
        print(f"Warning: Unknown message type '{message_type}'")
    
    return item

