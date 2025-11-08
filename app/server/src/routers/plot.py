from fastapi import APIRouter, Depends, HTTPException

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
    #TODO
    return {"message": "List of plots"}

@router.get("/facility/{facility_id}", description="Obtener parcelas de una instalación")
async def get_plots_by_facility(facility_id: str):
    #TODO
    return {"message": f"Plots for facility {facility_id}"}

@router.post("/", description="Crear una nueva parcela")
async def create_plot():
    #TODO
    return {"message": "Plot created"}

@router.get("/{plot_id}", description="Obtener detalles de una parcela")
async def get_plot(plot_id: str):
    #TODO
    return {"message": f"Details of plot {plot_id}"}

@router.put("/{plot_id}", description="Actualizar una parcela") #put o patch?
async def update_plot(plot_id: str):
    #TODO
    return {"message": f"Plot {plot_id} updated"}

@router.delete("/{plot_id}", description="Eliminar una parcela")
async def delete_plot(plot_id: str):
    #TODO
    return {"message": f"Plot {plot_id} deleted"}

