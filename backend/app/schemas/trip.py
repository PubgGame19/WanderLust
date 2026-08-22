from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.user import UserAuthorOut
from app.schemas.location import LocationOut
from app.schemas.review import ReviewFeedItem

class TripPlaceExperienceCreate(BaseModel):
    # Existing location ID or new location creation data
    location_id: Optional[str] = None
    new_location_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    country: Optional[str] = "India"
    state_region: Optional[str] = None
    city: Optional[str] = None
    place_type: Optional[str] = "place"
    description: Optional[str] = None
    
    # Location-specific experience data
    rating: Optional[int] = Field(5, ge=1, le=5)
    raw_text: Optional[str] = None
    expense_amount: Optional[float] = None
    currency: Optional[str] = "INR"
    transport_mode: Optional[str] = None
    tips: Optional[str] = None
    visit_date: Optional[date] = None
    visit_order: Optional[int] = 1
    photo_urls: List[str] = Field(default_factory=list)

class TripCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=255)
    start_date: date
    end_date: date
    description: Optional[str] = None
    total_expense: Optional[float] = None
    currency: Optional[str] = "INR"
    transport_mode: Optional[str] = None
    rating: Optional[int] = Field(None, ge=1, le=5)
    photo_urls: List[str] = Field(default_factory=list)
    places: List[TripPlaceExperienceCreate] = Field(default_factory=list)

class TripPlaceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    location: LocationOut
    visit_order: int
    experience: Optional[ReviewFeedItem] = None

class TripOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    start_date: date
    end_date: date
    description: Optional[str] = None
    total_expense: Optional[float] = None
    currency: str = "INR"
    transport_mode: Optional[str] = None
    rating: Optional[int] = None
    author: UserAuthorOut
    places: List[TripPlaceOut] = []
    places_count: int = 0
    created_at: datetime

class TripListItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    start_date: date
    end_date: date
    description: Optional[str] = None
    total_expense: Optional[float] = None
    currency: str = "INR"
    transport_mode: Optional[str] = None
    rating: Optional[int] = None
    author: UserAuthorOut
    places_count: int = 0
    visited_place_names: List[str] = []
    created_at: datetime
