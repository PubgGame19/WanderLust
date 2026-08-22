import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer, Float, Boolean
from sqlalchemy.orm import relationship

from app.core.database import Base

class ReviewPhoto(Base):
    __tablename__ = "review_photos"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    trip_id = Column(String(36), ForeignKey("trips.id", ondelete="CASCADE"), nullable=True, index=True)
    review_id = Column(String(36), ForeignKey("reviews.id", ondelete="CASCADE"), nullable=True, index=True)
    location_id = Column(String(36), ForeignKey("locations.id", ondelete="CASCADE"), nullable=True, index=True)
    image_url = Column(String(1000), nullable=False)
    thumbnail_url = Column(String(1000), nullable=True)
    caption = Column(String(255), nullable=True)
    display_order = Column(Integer, default=0)
    is_flagged = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Physical EXIF Metadata & Device Integrity Verification
    camera_model = Column(String(100), nullable=True)
    taken_at = Column(DateTime, nullable=True)
    gps_latitude = Column(Float, nullable=True)
    gps_longitude = Column(Float, nullable=True)
    is_verified_authentic = Column(Boolean, default=False, nullable=False)

    review = relationship("Review", back_populates="photos")
    location = relationship("Location", back_populates="photos")
    trip = relationship("Trip", back_populates="photos")
