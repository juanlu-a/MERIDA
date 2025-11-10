from pydantic import BaseModel
from typing import Optional
from src.schemas.sensor_data import SensorData

class PlotBase(BaseModel):
    facility_id: str
    name: str
    location: str
    mac_address: str

class Plot(PlotBase):
    plot_id: str

class PlotCreate(PlotBase):
    pass

class PlotUpdate(BaseModel):
    name: Optional[str]
    location: Optional[str]
    species: Optional[str]