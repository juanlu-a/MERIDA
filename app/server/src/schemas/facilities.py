from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional

class FacilityBase(BaseModel):
    name: str
    location: str

class FacilityCreate(FacilityBase):
    """Modelo usado para crear una instalación (sin ID, lo genera el sistema)."""
    pass

class FacilityRead(FacilityBase):
    facility_id: UUID = Field(..., description="Identificador único de la instalación")

class FacilityUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None