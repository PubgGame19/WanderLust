import os
from typing import List, Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(case_sensitive=True, env_file=".env", extra="ignore")

    PROJECT_NAME: str = "Wanderlust AI (TravelX)"
    API_V1_STR: str = "/api/v1"
    VERSION: str = "1.0.0"
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "wanderlust_super_secret_jwt_key_2026_change_in_production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 days
    GOOGLE_CLIENT_ID: Optional[str] = os.getenv("GOOGLE_CLIENT_ID", "")
    
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "sqlite:///./wanderlust_local.db"
    )
    
    # Redis Queue
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    REVIEW_QUEUE_NAME: str = "ai_review_processing"
    
    # AI API Keys
    GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY", "")
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY", "")
    AI_MODEL_VERSION: str = "wanderlust-gemini-pro-v1"
    
    # Media & Storage Configuration
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "uploads")
    MAX_IMAGE_COUNT_PER_EXPERIENCE: int = 10
    MAX_IMAGE_FILE_SIZE_MB: int = 10 # 10MB per image
    ALLOWED_IMAGE_EXTENSIONS: List[str] = ["jpg", "jpeg", "png", "webp"]
    ALLOWED_IMAGE_MIMES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    STORAGE_PROVIDER: str = os.getenv("STORAGE_PROVIDER", "local") # 'local', 'cloudinary', 's3'
    CLOUDINARY_URL: Optional[str] = os.getenv("CLOUDINARY_URL", "")
    AWS_S3_BUCKET: Optional[str] = os.getenv("AWS_S3_BUCKET", "")
    
    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

settings = Settings()
