from fastapi import APIRouter, Depends, HTTPException
from boto3.dynamodb.conditions import Key, Attr
from src.schemas.facilities import FacilityBase, FacilityCreate, FacilityRead, FacilityUpdate
from src.schemas.plot import PlotBase, PlotCreate, PlotUpdate
from src.dal.database import table
from uuid import uuid4
from botocore.exceptions import ClientError

"""
🪴 Parcelas
GET /facilities/{facility_id}/plots
GET /plots/{plot_id}
POST /plots
PUT /plots/{plot_id}
DELETE /plots/{plot_id}
GET /plots/{plot_id}/location
GET /plots/pending-irrigation
"""

router = APIRouter(prefix="/plots", tags=["Parcelas"])

@router.get("/", description="Obtener todas las parcelas")
async def get_plots():
    try:
        response = table.query(
            IndexName="GSI_TypeIndex",
            KeyConditionExpression=Key("type").eq("PLOT")
        )

        plots = response.get("Items", [])

        # Manejo de paginación si hay más resultados
        while "LastEvaluatedKey" in response:
            response = table.query(
                IndexName="GSI_TypeIndex",
                KeyConditionExpression=Key("type").eq("PLOT"),
                ProjectionExpression="#pk, #sk, #n, #l",
                ExpressionAttributeNames={
                    "#pk": "pk",
                    "#sk": "sk",
                    "#n": "name",
                    "#l": "location"
                }
            )
            plots.extend(response.get("Items", []))
        
        if not plots:
            raise HTTPException(status_code=404, detail="No plots found")

        return {"count": len(plots), "plots": plots}

    except ClientError as e:
        msg = e.response.get("Error", {}).get("Message", str(e))
        raise HTTPException(status_code=500, detail=f"Error consulting DynamoDB: {msg}")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@router.get("/facility/{facility_id}", description="Obtener parcelas de una instalación")
async def get_plots_by_facility(facility_id: str):
    """
    Devuelve todas las parcelas asociadas a una instalación específica.
    """
    try:
        # Query DynamoDB usando pk y sk
        response = table.query(
            KeyConditionExpression=Key("pk").eq(f"FACILITY#{facility_id}") & Key("sk").begins_with("PLOT#")
        )

        plots = response.get("Items", [])

        if not plots:
            raise HTTPException(status_code=404, detail="No se encontraron parcelas para esta instalación")

        return {
            "facility_id": facility_id,
            "count": len(plots),
            "plots": plots
        }

    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Error obtaining plots for the facility: {e}")

@router.post("/", description="Crear una nueva parcela")
async def create_plot(plot: PlotCreate):
    try:
        # Verificar que la instalación exista
        response = table.get_item(
            Key={"pk": f"FACILITY#{plot.facility_id}", "sk": "Metadata"}
        )

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="Facility not found")
    
        plot_id = str(uuid4())

        item = {
            "pk": f"FACILITY#{plot.facility_id}",
            "sk": f"PLOT#{plot_id}",
            "facility_id": plot.facility_id,
            "plot_id": plot_id,
            "type": "PLOT",
            "name": plot.name,
            "location": plot.location,
            "mac_address": plot.mac_address,
            "species": plot.species if plot.species else "unknown",
        }

        table.put_item(Item=item)
        return {
            "message": "Plot created successfully",
            "created_plot": item
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating plot: {e}")

@router.get("/{plot_id}", description="Obtener detalles de una parcela")
async def get_plot(plot_id: str):
    response = table.get_item(
        Key={
            "pk": f"PLOT#{plot_id}",
            "sk": "Metadata"
        }
    )

    if "Item" not in response:
        raise HTTPException(status_code=404, detail="Plot not found")
    
    return response.get("Item")

#@router.put("/{plot_id}", description="Actualizar una parcela") #put o patch?
async def update_plot(plot_id: str):
    #TODO
    return {"message": f"Plot {plot_id} updated"}

@router.delete("/{plot_id}", description="Eliminar una parcela")
async def delete_plot(plot_id: str, facility_id: str):
    try:
        response = table.get_item(
            Key={
                "pk": f"FACILITY#{facility_id}",
                "sk": f"PLOT#{plot_id}"
            }
        )

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="Plot not found")

        table.delete_item(
            Key={
                "pk": f"FACILITY#{facility_id}",
                "sk": f"PLOT#{plot_id}"
            }
        )
    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Error deleting plot: {e}") 
    
    facility_name = response['Item'].get('facility_id', 'unknown facility') if 'Item' in response else "unknown facility"
    return {"message": f"Plot {plot_id} from {facility_name} deleted successfully"}