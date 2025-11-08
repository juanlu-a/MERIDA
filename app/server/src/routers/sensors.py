from fastapi import APIRouter, Depends, HTTPException

"""
📊 Sensores
GET /plots/{plot_id}/sensor-values
GET /species/{species_id}/sensor-values
"""

router = APIRouter(prefix="/sensors", tags=["Sensores"])

@router.get("/plot/{plot_id}/sensor-values", description="Obtener valores de sensores de una parcela")
async def get_sensor_values_by_plot(plot_id: str):
    #TODO
    return {"message": f"Sensor values for plot {plot_id}"}

@router.get("/species/{species_id}/sensor-values", description="Obtener valores de sensores de una especie")
async def get_sensor_values_by_species(species_id: str):
    #TODO
    return {"message": f"Sensor values for species {species_id}"}
