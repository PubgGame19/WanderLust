from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class PhotoAttachRequest(BaseModel):
    photo_urls: List[str]

class MediaUploadOut(BaseModel):
    image_url: str
    filename: str
    camera_model: Optional[str] = None
    taken_at: Optional[datetime] = None
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None
    is_verified_authentic: bool = False

class PhotoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    image_url: str
    caption: Optional[str] = None
    created_at: datetime
    location_id: Optional[str] = None
    location_name: Optional[str] = None
    trip_id: Optional[str] = None
    trip_title: Optional[str] = None
    user_id: Optional[str] = None
    author_username: Optional[str] = None
    camera_model: Optional[str] = None
    taken_at: Optional[datetime] = None
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None
    is_verified_authentic: bool = False
