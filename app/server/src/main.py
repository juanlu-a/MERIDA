from dotenv import load_dotenv

load_dotenv()
from fastapi import FastAPI
from fastapi.responses import FileResponse
from pathlib import Path
from contextlib import asynccontextmanager
from fastapi.staticfiles import StaticFiles
import logging
from contextlib import asynccontextmanager
from src.routers import facilities, irrigations, plot, sensors, recommended_irrigation, user, species  
from src.dal.database import table 
import os
from fastapi.middleware.cors import CORSMiddleware
from src.dal.database import init_db

logger = logging.getLogger("uvicorn")
BASE_DIR = Path(__file__).resolve().parent
static_path = BASE_DIR / "static"

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestor de contexto para el ciclo de vida de la aplicación FastAPI."""
    logger.info("🚀 Iniciando API de MERIDA...")
    await init_db()  # crea la tabla si no existe (no bloquea FastAPI)
    yield
    logger.info("🛑 Apagando API de MERIDA...")

app = FastAPI(
    title="FASTAPI - MÉRIDA",
    description="API para monitoreo de parcelas y gestión de riegos con DynamoDB y AWS IoT.",
    version="1.0.0",
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    swagger_favicon_url="src/static/plant.ico",
    lifespan=lifespan
)

origin_env = os.getenv("FRONTEND_ORIGIN", "*")
print(origin_env)
# Permitir varios orígenes separados por comas (si fuera necesario),
# porque CORSMiddleware espera una lista de orígenes
frontend_origins = origin_env.split(",") if origin_env != "*" else ["*"]

app.add_middleware(
    CORSMiddleware,
    #allow_origins=frontend_origins,
    allow_origins=[
        "http://eliseo-app-tic.s3-website.us-east-2.amazonaws.com", "http://localhost:5173"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory=static_path), name="static")

@app.get("/favicon.ico")
async def favicon():
    return FileResponse(static_path / "plant.ico")

# --- Log de inicio ---
logger.info("🚀🪴 API de MERIDA iniciada. DynamoDB listo para recibir consultas.")

app.include_router(facilities.router)
app.include_router(irrigations.router)
app.include_router(plot.router)
#app.include_router(recommended_irrigation.router)
app.include_router(sensors.router)
app.include_router(species.router)
#app.include_router(user.router)

@app.get("/")
def read_root():
    return {"message": "Bienvenido a la API de monitoreo de parcelas y gestión de riegos"}

@app.get("/ping")
def ping():
    return {"status": "OK"}
    
