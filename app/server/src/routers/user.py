from fastapi import APIRouter, HTTPException

from src.dal.user import get_user_profile
from fastapi import APIRouter, Depends, HTTPException
from typing import List
from src.schemas.user import User, UserCreate, UserRead
from src.dal.user import get_user_profile

router = APIRouter(prefix="/users", tags=["users"])


"""@router.get("/{user_id}", response_model=UserRead)
async def read_user(user_id: str) -> UserRead:
    user = get_user_profile(user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user"""



"""
👤 Usuarios
GET /users
POST /users
GET /users/{user_id}/facilities
"""
router = APIRouter(prefix="/users", tags=["Usuarios"])

@router.get("/", description="Obtener todos los usuarios")
async def get_users():
    #TODO # get users from database
    return {"message": "List of users"}

@router.post("/", description="Crear un nuevo usuario")
async def create_user(user: UserCreate):
    #TODO create user in database
    return {"message": "User created"}

@router.get("/{user_id}/facilities", description="Obtener instalaciones de un usuario")
async def get_user_facilities(user_id: str):
    #TODO get facilities for user from database
    return {"message": f"Facilities for user {user_id}"}

@router.get("/{user_id}", description="Obtener detalles de un usuario")
async def get_user(user_id: str):
    #TODO get user details from database
    return {"message": f"Details of user {user_id}"}

@router.get("/{user_id}", response_model=UserRead)
async def read_user(user_id: str) -> UserRead:
    user = get_user_profile(user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user

