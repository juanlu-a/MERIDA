import boto3
import os
from uuid import UUID

dynamodb = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION", "us-east-2"))
table = dynamodb.Table(os.getenv("TABLE_NAME", "MeridaMainTable"))

def create_facility(facility_id: UUID, name: str, location: str):
    item = {
        "PK": f"FACILITY#{facility_id}",
        "SK": "Metadata",
        "name": name,
        "location": location,
        "type": "Facility"
    }
    table.put_item(Item=item)
    return item