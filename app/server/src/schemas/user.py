from pydantic import BaseModel, Field
from typing import List, Optional

class User(BaseModel):
    user_id: str  # ID único
    name: str
    email: str

class UserCreate(User):
    password: str  # si corresponde

class UserRead(User):
    facilities: Optional[List[str]] = []  # IDs de instalaciones asignadas