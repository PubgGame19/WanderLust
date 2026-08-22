import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.database import init_db, SessionLocal
from app.api.v1 import api_router
from app.models.location import Location
from app.models.user import User
from app.models.review import Review
from app.models.review_ai_data import ReviewAIData
from app.models.location_ai_insights import LocationAIInsights
from app.api.v1.deps import get_password_hash

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("wanderlust.main")

def seed_initial_data():
    """Seeds rich initial test users, locations, reviews, and trips."""
    try:
        from seed_rich_demo_data import seed_rich_data
        seed_rich_data()
    except Exception as e:
        logger.error(f"Error during initial rich data seeding: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Wanderlust AI API Gateway...")
    init_db()
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    seed_initial_data()
    yield
    # Shutdown
    logger.info("Shutting down Wanderlust AI API Gateway...")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Production-Ready Mobile-First AI Travel Knowledge & Community Platform API",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Routes
app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount Static Uploads Folder
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")

@app.get("/health", tags=["System"])
def health_check():
    """Health check probe."""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION
    }
