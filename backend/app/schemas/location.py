from typing import Optional, List, Any
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class LocationBase(BaseModel):
    name: str = Field(..., max_length=255)
    slug: str = Field(..., max_length=255)
    continent: str = Field(..., max_length=50)
    country: str = Field(..., max_length=100)
    state_region: Optional[str] = None
    city: Optional[str] = None
    place_type: str = Field(..., max_length=50) # 'mountain', 'beach', 'fort', 'monument', 'cafe'
    latitude: float
    longitude: float
    cover_image_url: Optional[str] = None
    description: Optional[str] = None

class LocationCreate(LocationBase):
    pass

class LocationOut(LocationBase):
    model_config = ConfigDict(from_attributes=True)

    id: str
    verified: bool
    created_at: datetime
    distance_km: Optional[float] = None
    average_rating: Optional[float] = None
    review_count: Optional[int] = 0

class LocationAutocompleteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    city: Optional[str] = None
    state_region: Optional[str] = None
    country: str
    dominant_currency: str = "USD"
    place_type: Optional[str] = None
    cover_image_url: Optional[str] = None
    display_label: str

class LocationAIInsightsOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    location_id: str
    aggregated_positives: List[str] = []
    aggregated_challenges: List[str] = []
    expense_range_min: Optional[float] = None
    expense_range_max: Optional[float] = None
    dominant_currency: str = "USD"
    best_visit_times: List[str] = []
    sample_size: int = 0
    updated_at: Optional[datetime] = None

class LocationFeedResponse(BaseModel):
    location: LocationOut
    insights: Optional[LocationAIInsightsOut] = None
    total_reviews: int
    reviews: List[Any] # Will be ReviewFeedItem
