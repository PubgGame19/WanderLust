from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.schemas.user import UserAuthorOut

class MediaUploadOut(BaseModel):
    image_url: str
    url: Optional[str] = None
    media_id: Optional[str] = None
    thumbnail_url: Optional[str] = None
    filename: str
    size_bytes: int
    storage_provider: str = "local"

    def model_post_init(self, __context) -> None:
        if not self.url:
            self.url = self.image_url
        if not self.media_id:
            self.media_id = self.filename

class PhotoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    user_id: str
    trip_id: Optional[str] = None
    trip_title: Optional[str] = None
    review_id: Optional[str] = None
    location_id: str
    location_name: Optional[str] = None
    image_url: str
    thumbnail_url: Optional[str] = None
    display_order: int = 0
    author: UserAuthorOut
    created_at: datetime

class PhotoAttachRequest(BaseModel):
    photo_urls: List[str]
