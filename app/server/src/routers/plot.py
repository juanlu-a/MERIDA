from fastapi import APIRouter, Depends, HTTPException
from boto3.dynamodb.conditions import Key, Attr
from src.schemas.facilities import FacilityBase, FacilityCreate, FacilityRead, FacilityUpdate
from src.schemas.plot import PlotBase, PlotCreate, PlotUpdate
from src.dal.database import table
from uuid import uuid4
from botocore.exceptions import ClientError
from decimal import Decimal


def convert_decimals(obj):
    """Convierte Decimal a float/int recursivamente para serialización JSON"""
    if isinstance(obj, list):
        return [convert_decimals(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_decimals(value) for key, value in obj.items()}
    elif isinstance(obj, Decimal):
        # Convertir a int si es un número entero, sino a float
        return int(obj) if obj % 1 == 0 else float(obj)
    else:
        return obj

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


def _create_default_thresholds(plot_id: str, facility_id: str, species_id: str):
    """
    Crea umbrales por defecto para un plot desde los umbrales de la especie.
    Si la especie no tiene umbrales configurados, crea umbrales genéricos por defecto.
    Los umbrales se crean con umbral_enabled=False (desactivados).
    """
    # Buscar umbrales de la especie (primero facility-specific, luego global)
    species_thresholds = None
    
    # 1. Intentar facility-specific
    try:
        response = table.get_item(
            Key={
                "pk": f"FACILITY#{facility_id}",
                "sk": f"SPECIES#{species_id}"
            }
        )
        if "Item" in response:
            species_thresholds = response["Item"]
    except ClientError:
        pass
    
    # 2. Si no hay facility-specific, intentar global
    if not species_thresholds:
        try:
            response = table.get_item(
                Key={
                    "pk": f"SPECIES#{species_id}",
                    "sk": "PROFILE"
                }
            )
            if "Item" in response:
                species_thresholds = response["Item"]
        except ClientError:
            pass
    
    # Crear umbrales del plot con umbral_enabled=False
    plot_thresholds = {
        "pk": f"PLOT#{plot_id}",
        "sk": "THRESHOLDS",
        "plot_id": plot_id,
        "facility_id": facility_id,
        "species_id": species_id,
        "type": "PLOT_THRESHOLDS",
        "umbral_enabled": False,  # Desactivado por defecto
    }
    
    # Copiar umbrales de la especie si existen
    threshold_fields = [
        "MinTemperature", "MaxTemperature",
        "MinHumidity", "MaxHumidity",
        "MinLight", "MaxLight",
        "MinIrrigation", "MaxIrrigation"
    ]
    
    if species_thresholds:
        # Copiar umbrales de la especie
        for field in threshold_fields:
            if field in species_thresholds:
                plot_thresholds[field] = species_thresholds[field]
        print(f"Created default thresholds for plot {plot_id} from species {species_id} (umbral_enabled=False)")
    else:
        # Crear umbrales genéricos por defecto
        plot_thresholds.update({
            "MinTemperature": Decimal("15.0"),
            "MaxTemperature": Decimal("30.0"),
            "MinHumidity": Decimal("40.0"),
            "MaxHumidity": Decimal("80.0"),
            "MinLight": Decimal("3000.0"),
            "MaxLight": Decimal("20000.0"),
            "MinIrrigation": Decimal("0.0"),
            "MaxIrrigation": Decimal("100.0"),
        })
        print(f"No thresholds found for species {species_id}, created generic default thresholds for plot {plot_id} (umbral_enabled=False)")
    
    # Guardar en DynamoDB
    table.put_item(Item=plot_thresholds)

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

        # Convertir Decimals a float/int para JSON
        plots_converted = convert_decimals(plots)

        return {"count": len(plots_converted), "plots": plots_converted}

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

        # Convertir Decimals a float/int para JSON
        plots_converted = convert_decimals(plots)

        return {
            "facility_id": facility_id,
            "count": len(plots_converted),
            "plots": plots_converted
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
        
        # Add optional fields if provided
        if plot.area is not None:
            item["area"] = Decimal(str(plot.area))

        table.put_item(Item=item)
        
        # SIEMPRE crear umbrales por defecto (desde la especie o genéricos)
        try:
            species_for_thresholds = plot.species if plot.species else "generic"
            _create_default_thresholds(plot_id, plot.facility_id, species_for_thresholds)
        except Exception as e:
            # No fallar la creación del plot si falla la creación de thresholds
            print(f"Warning: Could not create default thresholds: {e}")
        
        # Convertir Decimals a float/int para JSON
        item_converted = convert_decimals(item)
        
        return {
            "message": "Plot created successfully",
            "created_plot": item_converted
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
    
    # Convertir Decimals a float/int para JSON
    item = convert_decimals(response.get("Item"))
    
    return item

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

@router.get("/{plot_id}/thresholds", description="Obtener umbrales del plot")
async def get_plot_thresholds(plot_id: str):
    """
    Obtiene los umbrales configurados para un plot específico.
    Devuelve los umbrales del plot con su estado umbral_enabled.
    """
    try:
        # Obtener umbrales del plot
        response = table.get_item(
            Key={
                "pk": f"PLOT#{plot_id}",
                "sk": "THRESHOLDS"
            }
        )
        
        if "Item" not in response:
            raise HTTPException(
                status_code=404,
                detail="No thresholds configured for this plot"
            )
        
        thresholds = response["Item"]
        
        # Convertir Decimal a float para JSON
        for key, value in thresholds.items():
            if isinstance(value, Decimal):
                thresholds[key] = float(value)
        
        return thresholds
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching plot thresholds: {e}")


@router.put("/{plot_id}/thresholds", description="Actualizar umbrales del plot")
async def update_plot_thresholds(plot_id: str, thresholds: dict):
    """
    Actualiza los umbrales de un plot y opcionalmente los activa.
    
    Body ejemplo:
    {
      "MinTemperature": 18.0,
      "MaxTemperature": 28.0,
      "MinHumidity": 60.0,
      "MaxHumidity": 80.0,
      "MinLight": 5000.0,
      "MaxLight": 15000.0,
      "umbral_enabled": true
    }
    """
    try:
        # Verificar que el plot existe
        plot_response = table.get_item(
            Key={
                "pk": f"PLOT#{plot_id}",
                "sk": "THRESHOLDS"
            }
        )
        
        if "Item" not in plot_response:
            raise HTTPException(
                status_code=404,
                detail="Plot thresholds not found. Create the plot first."
            )
        
        existing_thresholds = plot_response["Item"]
        
        # Campos permitidos para actualizar
        allowed_fields = [
            "MinTemperature", "MaxTemperature",
            "MinHumidity", "MaxHumidity",
            "MinLight", "MaxLight",
            "MinIrrigation", "MaxIrrigation",
            "umbral_enabled"
        ]
        
        # Actualizar solo los campos proporcionados
        for field in allowed_fields:
            if field in thresholds:
                value = thresholds[field]
                # Convertir a Decimal si es número
                if isinstance(value, (int, float)) and field != "umbral_enabled":
                    existing_thresholds[field] = Decimal(str(value))
                else:
                    existing_thresholds[field] = value
        
        # Guardar
        table.put_item(Item=existing_thresholds)
        
        # Convertir Decimal a float para respuesta
        response_data = dict(existing_thresholds)
        for key, value in response_data.items():
            if isinstance(value, Decimal):
                response_data[key] = float(value)
        
        return {
            "message": "Thresholds updated successfully",
            "thresholds": response_data
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating plot thresholds: {e}")


@router.get("/{plot_id}/state", description="Obtener el estado actual (más reciente) de un plot")
async def get_plot_state(plot_id: str):
    """
    Devuelve el estado más reciente de sensores de un plot.
    """
    try:
        response = table.query(
            KeyConditionExpression=Key("pk").eq(f"PLOT#{plot_id}") & Key("sk").begins_with("STATE#"),
            ScanIndexForward=False,  # Más recientes primero
            Limit=1  # Solo el más reciente
        )
        
        items = response.get("Items", [])
        
        if not items:
            raise HTTPException(status_code=404, detail="No sensor data found for this plot")
        
        # Retornar el estado más reciente
        state = items[0]
        
        # Convertir a formato esperado por el frontend
        return {
            "plot_id": plot_id,
            "timestamp": state.get("Timestamp"),
            "temperature": float(state.get("temperature", 0)) if state.get("temperature") is not None else None,
            "humidity": float(state.get("humidity", 0)) if state.get("humidity") is not None else None,
            "soil_moisture": float(state.get("soil_moisture", 0)) if state.get("soil_moisture") is not None else None,
            "light": float(state.get("light", 0)) if state.get("light") is not None else None,
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obtaining plot state: {e}")


@router.get("/{plot_id}/history", description="Obtener historial de estados de un plot")
async def get_plot_history(plot_id: str, start_date: str = None, end_date: str = None, limit: int = 100):
    """
    Devuelve el historial de estados de sensores de un plot.
    
    Parámetros:
    - start_date: Fecha inicio en formato ISO (opcional)
    - end_date: Fecha fin en formato ISO (opcional)
    - limit: Número máximo de registros (default: 100, max: 1000)
    """
    try:
        # Limitar el limit para evitar consultas muy grandes
        limit = min(limit, 1000)
        
        # Construir la consulta
        key_condition = Key("pk").eq(f"PLOT#{plot_id}") & Key("sk").begins_with("STATE#")
        
        query_params = {
            "KeyConditionExpression": key_condition,
            "ScanIndexForward": False,  # Más recientes primero
            "Limit": limit
        }
        
        # TODO: Implementar filtro por fechas si es necesario
        # Por ahora solo devolvemos los últimos N registros
        
        response = table.query(**query_params)
        items = response.get("Items", [])
        
        if not items:
            raise HTTPException(status_code=404, detail="No historical data found for this plot")
        
        # Convertir a formato esperado por el frontend
        history = []
        for item in items:
            history.append({
                "timestamp": item.get("Timestamp"),
                "temperature": float(item.get("temperature", 0)) if item.get("temperature") is not None else None,
                "humidity": float(item.get("humidity", 0)) if item.get("humidity") is not None else None,
                "soil_moisture": float(item.get("soil_moisture", 0)) if item.get("soil_moisture") is not None else None,
                "light": float(item.get("light", 0)) if item.get("light") is not None else None,
            })
        
        return history
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error obtaining plot history: {e}")