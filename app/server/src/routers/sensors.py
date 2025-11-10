from fastapi import APIRouter, Depends, HTTPException
from boto3.dynamodb.conditions import Key, Attr
from src.dal.database import table

"""
📊 Sensores
GET /plots/{plot_id}/sensor-values
GET /species/{species_id}/sensor-values
"""

router = APIRouter(prefix="/sensors", tags=["Sensores"])

@router.get("/plot/{plot_id}/sensor-values", description="Obtener valores de sensores de una parcela")
async def get_sensor_values_by_plot(plot_id: str):
    try:
        response = table.query(
            KeyConditionExpression=Key("pk").eq(f"PLOT#{plot_id}") & Key("sk").begins_with("STATE#"),
            ScanIndexForward=False  # opcional: False para más recientes primero
        )
        items = response.get("Items", [])

        return {
            "count": len(items),
            "states": items
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obtaining sensor values: {e}")

@router.get("/species/{species_id}/sensor-values", description="Obtener valores de sensores de una especie")
async def get_sensor_values_by_species(species_id: str):
    try:
        # 1 - Obtener los plots vinculados a la especie
        response = table.query(
            IndexName="GSI_SpeciesPlots",
            KeyConditionExpression=Key("species").eq(f"SPECIES#{species_id}")
        )

        plot_items = response.get("Items", [])
        if not plot_items:
            raise HTTPException(status_code=404, detail=f"No plots found for species {species_id}")

        plots_data = []

        # 2 - Por cada parcela, traer sus valores de sensores
        for plot in plot_items:
            plot_id = plot["pk"].split("#")[-1]

            sensor_response = table.query(
                KeyConditionExpression=Key("pk").eq(f"PLOT#{plot_id}") & Key("sk").begins_with("SENSOR#")
            )

            sensor_values = sensor_response.get("Items", [])
            plots_data.append({
                "plot_id": plot_id,
                "sensor_values": sensor_values
            })

        # 3 - Respuesta final
        return {"species_id": species_id, "plots": plots_data}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
