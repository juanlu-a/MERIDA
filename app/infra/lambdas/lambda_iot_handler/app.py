import json
import boto3
import os
from datetime import datetime
from decimal import Decimal
import re

# Initialize DynamoDB client
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
        
        print(f"Successfully saved item to DynamoDB: pk={item['pk']}, sk={item['sk']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Data saved successfully',
                'pk': item['pk'],
                'sk': item['sk']
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


def get_plot_metadata(plot_id):
    """Fetch plot metadata from DynamoDB to get facility_id, species, and name"""
    try:
        print(f"Fetching metadata for plot_id: {plot_id}")
        
        # Method 1: Try GSI_TypeIndex query with filter
        response = table.query(
            IndexName='GSI_TypeIndex',
            KeyConditionExpression='#type = :type',
            FilterExpression='plot_id = :plot_id',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={
                ':type': 'PLOT',
                ':plot_id': plot_id
            },
            Limit=1
        )
        
        items = response.get('Items', [])
        if items:
            plot = items[0]
            metadata = {
                'facility_id': plot.get('facility_id'),
                'species': plot.get('species'),
                'name': plot.get('name')
            }
            print(f"Found metadata via GSI: {metadata}")
            return metadata
        
        # Method 2: Scan with filter (less efficient but works if GSI fails)
        print(f"GSI query returned no results, trying scan...")
        response = table.scan(
            FilterExpression='plot_id = :plot_id AND #type = :type',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={
                ':plot_id': plot_id,
                ':type': 'PLOT'
            },
            Limit=1
        )
        
        items = response.get('Items', [])
        if items:
            plot = items[0]
            metadata = {
                'facility_id': plot.get('facility_id'),
                'species': plot.get('species'),
                'name': plot.get('name')
            }
            print(f"Found metadata via scan: {metadata}")
            return metadata
        
        print(f"No metadata found for plot_id: {plot_id}")
        
    except Exception as e:
        print(f"Error fetching plot metadata for {plot_id}: {e}")
        import traceback
        traceback.print_exc()
    
    return None


def format_for_dynamodb(payload, plot_id):
    """
    Format the payload for DynamoDB using Single-Table Design
    
    Handles two types of messages:
    1. "state" - Sensor data readings (sensor_data field or sensor fields)
    2. "event" - Events like irrigation (event_type or irrigation fields)
    
    DynamoDB structure:
    - pk: PLOT#<plot_id>
    - sk: STATE#<timestamp> or EVENT#<timestamp>
    - GSI_PK: FACILITY#<facility_id>
    - GSI_SK: TIMESTAMP#<timestamp>
    - Type-specific data as top-level attributes
    """
    # Use provided timestamp or generate new one automatically
    if 'timestamp' in payload and payload['timestamp']:
        timestamp = payload['timestamp']
    else:
        timestamp = datetime.utcnow().isoformat() + 'Z'
        print(f"Generated automatic timestamp: {timestamp}")
    
    # Auto-detect message type based on content
    # If it has event_type or irrigation fields, it's an event
    # If it has sensor_data or sensor fields, it's state
    if 'event_type' in payload or 'duration' in payload or 'water_amount' in payload:
        message_type = 'event'
        print(f"Auto-detected message type: event (irrigation)")
    elif 'type' in payload:
        message_type = payload['type']
    else:
        message_type = 'state'  # default for backwards compatibility
    
    # If facility_id is not in payload, fetch it from plot metadata
    if 'facility_id' not in payload or not payload.get('facility_id'):
        print(f"facility_id not in payload, fetching from plot metadata for plot {plot_id}")
        plot_metadata = get_plot_metadata(plot_id)
        if plot_metadata:
            if plot_metadata.get('facility_id'):
                payload['facility_id'] = plot_metadata['facility_id']
                print(f"Found facility_id: {plot_metadata['facility_id']}")
            if plot_metadata.get('species') and 'species_id' not in payload:
                payload['species_id'] = plot_metadata['species']
            if plot_metadata.get('name') and 'plot_name' not in payload:
                payload['plot_name'] = plot_metadata['name']
    
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
    
    # Helper to convert metadata values (including numbers) to DynamoDB-compatible types
    def convert_scalar(value):
        if isinstance(value, float):
            return Decimal(str(value))
        if isinstance(value, dict):
            return convert_to_decimal(value)
        if isinstance(value, list):
            return [convert_scalar(item) for item in value]
        return value

    # Create base DynamoDB item
    item = {
        'pk': f'PLOT#{plot_id}',
        'Timestamp': timestamp,
        'GSI_SK': f'TIMESTAMP#{timestamp}',
    }
    
    # Preserve metadata (Species, Facility, Business, etc.)
    metadata_map = {
        'SpeciesId': 'SpeciesId',
        'species_id': 'SpeciesId',
        'FacilityId': 'FacilityId',
        'facility_id': 'FacilityId',
        'BusinessId': 'BusinessId',
        'business_id': 'BusinessId',
        'PlotName': 'PlotName',
        'plot_name': 'PlotName',
    }

    for source_key, target_key in metadata_map.items():
        if source_key in payload and payload[source_key] not in (None, ''):
            item[target_key] = convert_scalar(payload[source_key])

    # Add plot_id (snake_case) for backend compatibility
    item['plot_id'] = plot_id
    # Also keep PlotId (PascalCase) for backwards compatibility
    item['PlotId'] = plot_id

    # Set facility-based GSI partition key if available
    facility_id = item.get('FacilityId')
    if facility_id:
        item['GSI_PK'] = f'FACILITY#{facility_id}'
    else:
        item['GSI_PK'] = 'FACILITY#UNKNOWN'
    
    # Process based on message type
    if message_type == 'state':
        # STATE message: sensor readings
        item['sk'] = f'STATE#{timestamp}'
        sensor_data = payload.get('sensor_data', {})
        sensor_data_converted = convert_to_decimal(sensor_data)
        if isinstance(sensor_data_converted, dict):
            item.update(sensor_data_converted)
    
    elif message_type == 'event':
        # EVENT message: irrigation, alerts, etc.
        item['sk'] = f'EVENT#{timestamp}'
        
        # Map irrigation fields to DynamoDB format (both snake_case and PascalCase)
        irrigation_field_map = {
            'event_type': 'EventType',
            'duration': 'Duration',
            'water_amount': 'WaterAmount',
            'type': 'IrrigationType',  # Changed from 'type' to avoid conflict
        }
        
        # Add all event fields to the item
        for key, value in payload.items():
            if key not in ['plot_id', 'timestamp', 'facility_id', 'species_id', 'business_id', 'plot_name']:
                # Use mapped name if available, otherwise use original key
                target_key = irrigation_field_map.get(key, key)
                item[target_key] = convert_to_decimal(value)
    
    else:
        # Unknown type, use generic sk
        item['sk'] = f'DATA#{timestamp}'
        print(f"Warning: Unknown message type '{message_type}'")
    
    return item

