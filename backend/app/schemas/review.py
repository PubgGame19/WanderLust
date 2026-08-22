from typing import Optional, List
from datetime import datetime, date
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.user import UserAuthorOut

class ReviewCreate(BaseModel):
    location_id: str
    trip_id: Optional[str] = None
    rating: int = Field(..., ge=1, le=5)
    original_text: str = Field(..., min_length=5, max_length=5000)
    visit_date: date
    expense_amount: Optional[float] = None
    currency: Optional[str] = "USD"
    group_size: Optional[int] = None
    transport_mode: Optional[str] = None
    starting_location: Optional[str] = None
    photo_urls: Optional[List[str]] = []

class ReviewCreateResponse(BaseModel):
    review_id: str
    location_id: str
    user_id: str
    ai_status: str
    message: str

class ReviewAILayer(BaseModel):
    summary: str
    highlights: List[str] = []
    challenges: List[str] = []
    extracted_tips: List[str] = []
    sentiment: str = "neutral"
    extracted_budget_per_person: Optional[float] = None
    model_version: Optional[str] = None
    processing_status: str = "pending"

class ReviewRawLayer(BaseModel):
    original_text: str
    expense_amount: Optional[float] = None
    currency: str = "USD"
    group_size: Optional[int] = None
    transport_mode: Optional[str] = None
    starting_location: Optional[str] = None
    visit_date: date
    photos: List[str] = []
    is_photo_verified: bool = False
    camera_model: Optional[str] = None

class ReviewFeedItem(BaseModel):
    review_id: str
    location_id: str
    location_name: Optional[str] = None
    trip_id: Optional[str] = None
    trip_title: Optional[str] = None
    author: UserAuthorOut
    rating: int
    created_at: datetime
    ai_layer: ReviewAILayer
    raw_layer: ReviewRawLayer
    is_photo_verified: bool = False
    camera_model: Optional[str] = None
