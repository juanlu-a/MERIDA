from fastapi import APIRouter, Depends, HTTPException

"""
💧 Riegos
GET /plots/{plot_id}/last-irrigation
GET /plots/{plot_id}/irrigations
POST /plots/{plot_id}/irrigation
"""

router = APIRouter(prefix="/irrigations", tags=["Riegos"])

@router.get("/plot/{plot_id}/last-irrigation",  description="Obtener el último riego de una parcela")
async def get_last_irrigation(plot_id: str):
    #TODO
    return {"message": f"Last irrigation for plot {plot_id}"}

@router.get("/plot/{plot_id}/irrigations", description="Obtener todos los riegos de una parcela")
async def get_irrigations(plot_id: str):
    #TODO
    return {"message": f"List of irrigations for plot {plot_id}"}

@router.post("/plot/{plot_id}/irrigation", description="Crear (cargar) un nuevo riego para una parcela")
async def create_irrigation(plot_id: str):
    #TODO
    return {"message": f"Irrigation created for plot {plot_id}"}

