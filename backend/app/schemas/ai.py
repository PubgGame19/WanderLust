from typing import Optional, List, Literal
from pydantic import BaseModel, Field
from app.schemas.location import LocationOut

class AIExtractionResult(BaseModel):
    summary: str = Field(..., description="Objective concise summary grounded strictly in provided text.")
    highlights: List[str] = Field(default_factory=list, description="Explicit positive highlights or scenic features.")
    challenges: List[str] = Field(default_factory=list, description="Explicit difficulties, road conditions, bad weather, crowd issues, safety remarks.")
    extracted_tips: List[str] = Field(default_factory=list, description="Concrete tips/recommendations directly given by author.")
    sentiment: Literal["positive", "mixed", "negative", "neutral"] = Field(..., description="Overall review sentiment.")
    extracted_budget_per_person: Optional[float] = Field(default=None, description="Numeric cost per person if explicitly mentioned, otherwise null.")

class AIAssistantQueryRequest(BaseModel):
    query: str = Field(..., min_length=2, description="User travel question or itinerary search")
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    budget_max: Optional[float] = None
    currency: Optional[str] = "USD"
    place_type: Optional[str] = None

class AIAssistantCitation(BaseModel):
    location_name: str
    location_id: str
    review_id: str
    author_username: str
    quote_snippet: str
    rating: int

class AIAssistantResponse(BaseModel):
    query: str
    answer: str
    recommended_locations: List[LocationOut] = []
    citations: List[AIAssistantCitation] = []
    generated_at: str
