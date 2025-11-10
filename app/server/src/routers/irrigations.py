from fastapi import APIRouter, Depends, HTTPException
from boto3.dynamodb.conditions import Key, Attr
from src.dal.database import table

"""
💧 Riegos
GET /plots/{plot_id}/last-irrigation
GET /plots/{plot_id}/irrigations
POST /plots/{plot_id}/irrigation
"""

router = APIRouter(prefix="/irrigations", tags=["Riegos"])

@router.get("/plot/{plot_id}/last-irrigation",  description="Obtener el último riego de una parcela")
async def get_last_irrigation(plot_id: str):
    try:
        response = table.query(
            KeyConditionExpression=Key("pk").eq(f"PLOT#{plot_id}") & Key("sk").begins_with("EVENT#"),
            ScanIndexForward=False,  # orden descendente (último primero)
            Limit=1
        )

        items = response.get("Items", [])
        if not items:
            raise HTTPException(status_code=404, detail="No irrigation events found for this plot")

        last_event = items[0] # Se puede devolver solo el cuerpo o el ítem entero
        return {
            "plot_id": plot_id,
            "last_irrigation": last_event.get("timestamp", last_event.get("sk")),
            "details": last_event
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obtaining last irrigation: {e}")
    

@router.get("/plot/{plot_id}/irrigations", description="Obtener todos los riegos de una parcela")
async def get_irrigations(plot_id: str):
    try:
        response = table.query(
            KeyConditionExpression=Key("pk").eq(f"PLOT#{plot_id}") & Key("sk").begins_with("EVENT#"),
            ScanIndexForward=False  # opcional: False para más recientes primero
        )
        items = response.get("Items", [])

        return {
            "count": len(items),
            "irrigations": items
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obtaining irrigations: {e}")
