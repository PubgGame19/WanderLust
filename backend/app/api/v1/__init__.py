from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.locations import router as locations_router
from app.api.v1.reviews import router as reviews_router
from app.api.v1.trips import router as trips_router
from app.api.v1.media import router as media_router
from app.api.v1.ai import router as ai_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(locations_router)
api_router.include_router(reviews_router)
api_router.include_router(trips_router)
api_router.include_router(media_router)
api_router.include_router(ai_router)
