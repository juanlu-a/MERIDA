from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timezone
from uuid import uuid4

class SpeciesBase(BaseModel):
    name: str 
    #common_name: Optional[str] = Field(None, description="Common name of the species")
    #family: str = Field(..., description="Taxonomic family of the species")
    #description: Optional[str] = Field(None, description="Description of the species")
    #conservation_status: Optional[str] = Field(None, description="Conservation status of the species")

class Species(SpeciesBase):
    species_id: str
    species: str
    type: str

class SpeciesCreate(SpeciesBase):
    pass