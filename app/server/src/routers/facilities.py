from fastapi import APIRouter, Depends, HTTPException
from boto3.dynamodb.conditions import Key, Attr
from src.schemas.facilities import FacilityBase, FacilityCreate, FacilityRead, FacilityUpdate
from src.dal.database import table
from uuid import uuid4
"""
🏢 Instalaciones
GET /facilities
GET /facilities/{facility_id}
POST /facilities
PUT /facilities/{facility_id}
DELETE /facilities/{facility_id}
"""

router = APIRouter(prefix="/facilities", tags=["Instalaciones"])

@router.get("/", description="Obtener todas las instalaciones")
async def get_facilities():
    try:
        response = table.scan(
            FilterExpression=Attr("pk").begins_with("FACILITY#") & Attr("sk").eq("Metadata")
        )
        facilities = response.get("Items", [])

        return {
            "count": len(facilities),
            "facilities": facilities
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obteniendo las instalaciones: {e}")


@router.post("/", description="Crear una nueva instalación")
async def create_facility(facility: FacilityCreate):
    try:
        facility_id = str(uuid4())

        item = {
            "pk": f"FACILITY#{facility_id}",
            "sk": "Metadata",
            "facility_id": facility_id,
            "name": facility.name,
            "location": facility.location,
        }

        table.put_item(Item=item)

        return {
            "message": "Facility created successfully",
            "facility": item
        } 

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating facility: {e}")
    

@router.get("/{facility_id}", description="Obtener detalles de una instalación")
async def get_facility(facility_id: str):
    response = table.get_item(
        Key={
            "pk": f"FACILITY#{facility_id}",
            "sk": "Metadata"
        }
    )
    
    if "Item" not in response:
        raise HTTPException(status_code=404, detail="Facility not found")
    
    return response.get("Item")

@router.put("/{facility_id}", description="Actualizar una instalación")
async def update_facility(facility_id: str, facility: FacilityUpdate):
    try:
        response = table.get_item(
            Key={"pk": f"FACILITY#{facility_id}", "sk": "Metadata"}
        )

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="Facility not found")

        update_data = facility.model_dump(exclude_unset=True)
        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        expression_attribute_names = {}
        expression_attribute_values = {}
        update_expressions = []

        for i, (key, value) in enumerate(update_data.items(), start=1):
            # Evitar palabras reservadas usando alias con "#attrX"
            attr_name_alias = f"#attr{i}"
            attr_value_alias = f":val{i}"

            expression_attribute_names[attr_name_alias] = key
            expression_attribute_values[attr_value_alias] = value
            update_expressions.append(f"{attr_name_alias} = {attr_value_alias}")

        update_expression = "SET " + ", ".join(update_expressions)

        result = table.update_item(
            Key={"pk": f"FACILITY#{facility_id}", "sk": "Metadata"},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"  # Devuelve el ítem actualizado
        )

        return {
            "message": "Facility updated successfully",
            "updated_facility": result.get("Attributes", {})
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating facility: {e}")



@router.delete("/{facility_id}", description="Eliminar una instalación")
async def delete_facility(facility_id: str):
    #TODO
    return {"message": f"Facility {facility_id} deleted"}


