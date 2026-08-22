from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, Field
from app.schemas.user import UserAuthorOut

class ReviewCreate(BaseModel):
    location_id: str
    trip_id: Optional[str] = None
    rating: int = Field(..., ge=1, le=5)
    original_text: str = Field(..., min_length=5)
    visit_date: date
    expense_amount: Optional[float] = None
    currency: Optional[str] = "USD"
    group_size: Optional[int] = Field(default=1, ge=1)
    transport_mode: Optional[str] = None
    starting_location: Optional[str] = None
    photo_urls: Optional[List[str]] = Field(default_factory=list)

class ReviewCreatedResponse(BaseModel):
    review_id: str
    location_id: str
    trip_id: Optional[str] = None
    rating: int
    created_at: datetime
    ai_status: str = "pending"
    message: str = "Review recorded. AI extraction job enqueued."

class ReviewAILayer(BaseModel):
    summary: Optional[str] = "AI analysis in progress..."
    highlights: List[str] = []
    challenges: List[str] = []
    extracted_tips: List[str] = []
    sentiment: Optional[str] = "neutral"
    extracted_budget_per_person: Optional[float] = None
    model_version: Optional[str] = None
    processing_status: str = "pending" # 'pending', 'completed', 'failed'

class ReviewRawLayer(BaseModel):
    original_text: str
    expense_amount: Optional[float] = None
    currency: Optional[str] = "USD"
    group_size: Optional[int] = None
    transport_mode: Optional[str] = None
    starting_location: Optional[str] = None
    visit_date: date
    photos: List[str] = []

class ReviewFeedItem(BaseModel):
    review_id: str
    location_id: Optional[str] = None
    location_name: Optional[str] = None
    trip_id: Optional[str] = None
    trip_title: Optional[str] = None
    author: UserAuthorOut
    rating: int
    created_at: datetime
    ai_layer: ReviewAILayer
    raw_layer: ReviewRawLayer
