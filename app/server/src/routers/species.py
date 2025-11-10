from fastapi import APIRouter, Depends, HTTPException
from boto3.dynamodb.conditions import Key, Attr
from src.schemas.species import SpeciesBase, SpeciesCreate
from src.dal.database import table
from botocore.exceptions import ClientError
from uuid import uuid4

"""
🌿 Especies
GET /species
POST /species
PUT /species/{species_id}
DELETE /species/{species_id}
"""

router = APIRouter(prefix="/species", tags=["Especies"])

@router.get("/", description="Obtener todas las especies")
async def get_species():
    try:
        species = []
        last_evaluated_key = None

        # Manejo de paginación automática
        while True:
            query_params = {
                "IndexName": "GSI_TypeIndex",
                "KeyConditionExpression": Key("type").eq("SPECIES"),
            }

            if last_evaluated_key:
                query_params["ExclusiveStartKey"] = last_evaluated_key

            response = table.query(**query_params)
            species.extend(response.get("Items", []))

            if "LastEvaluatedKey" not in response:
                break
            last_evaluated_key = response["LastEvaluatedKey"]

        # Si no hay especies
        if not species:
            raise HTTPException(status_code=404, detail="No species found")

        return {"count": len(species), "species": species}

    except ClientError as e:
        msg = e.response.get("Error", {}).get("Message", str(e))
        raise HTTPException(status_code=500, detail=f"Error consulting DynamoDB: {msg}")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@router.post("/", description="Crear una nueva especie")
async def create_species(species: SpeciesCreate):
    try:
        species_id = str(uuid4())

        item = {
            "pk": f"SPECIES#{species_id}",
            "sk": "Metadata",
            "name": species.name,
            "type": "SPECIES"
        }

        table.put_item(Item=item)
        return {
            "message": "Species created successfully",
            "created_species": item
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating species: {e}")    

#@router.put("/{species_id}", description="Actualizar una especie")
async def update_species(species_id: str):
    #TODO
    return {"message": f"Species {species_id} updated"}

@router.delete("/{species_id}", description="Eliminar una especie")
async def delete_species(species_id: str):
    try:
        response = table.get_item(
            Key={
                "pk": f"SPECIES#{species_id}",
                "sk": "Metadata"
            }
        )

        if "Item" not in response:
            raise HTTPException(status_code=404, detail="Plot not found")

        table.delete_item(
            Key={
                "pk": f"SPECIES#{species_id}",
                "sk": "Metadata"
            }
        )
    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Error deleting species: {e}") 
    return {"message": f"Species {species_id} deleted successfully"}    

#assing species to existing plot
@router.put("/{species_id}/assign-to-plot/{plot_id}", description="Asignar una especie a una parcela")
async def assign_species_to_plot(species_id: str, facility_id: str, plot_id: str):
    try:
        # Verificar que la especie exista
        species_response = table.get_item(
            Key={"pk": f"SPECIES#{species_id}", "sk": "Metadata"}
        )

        if "Item" not in species_response:
            raise HTTPException(status_code=404, detail="Species not found")

        # Verificar que la parcela exista en la facility
        plot_response = table.query(
            KeyConditionExpression=Key("pk").eq(f"FACILITY#{facility_id}") & Key("sk").eq(f"PLOT#{plot_id}")
        )

        if not plot_response.get("Items"):
            raise HTTPException(status_code=404, detail="Plot not found or does not exist")
        
        item = {
            "pk": f"PLOT#{plot_id}",
            "sk": f"SPECIES#{species_id}",
            "specie": f"SPECIES#{species_id}", # necesario para el GSI, no es duplicado, solo son pocos KB
            "type": "PLOT_SPECIES"
        }

        table.put_item(Item=item)

        return {"message": f"Species {species_id} assigned to plot {plot_id} successfully"}

    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Error assigning species to plot: {e}")