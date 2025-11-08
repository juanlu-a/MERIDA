from fastapi import APIRouter, Depends, HTTPException

"""
🌿 Especies
GET /species
GET /plots/{plot_id}/species
POST /species
PUT /species/{species_id}
DELETE /species/{species_id}
"""

router = APIRouter(prefix="/species", tags=["Especies"])

@router.get("/", description="Obtener todas las especies")
async def get_species():
    #TODO
    return {"message": "List of species"}

@router.get("/plot/{plot_id}/species", description="Obtener especies de una parcela")
async def get_species_by_plot(plot_id: str):
    #TODO
    return {"message": f"Species for plot {plot_id}"}

@router.post("/", description="Crear una nueva especie")
async def create_species():
    #TODO
    return {"message": "Species created"}

@router.put("/{species_id}", description="Actualizar una especie")
async def update_species(species_id: str):
    #TODO
    return {"message": f"Species {species_id} updated"}

@router.delete("/{species_id}", description="Eliminar una especie")
async def delete_species(species_id: str):
    #TODO
    return {"message": f"Species {species_id} deleted"}

