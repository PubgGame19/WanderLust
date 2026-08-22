import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Numeric, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class Location(Base):
    __tablename__ = "locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False, index=True)
    slug = Column(String(255), unique=True, nullable=False, index=True)
    continent = Column(String(50), nullable=False)
    country = Column(String(100), nullable=False, index=True)
    state_region = Column(String(100), nullable=True)
    city = Column(String(100), nullable=True)
    place_type = Column(String(50), nullable=False, index=True) # 'mountain', 'beach', 'fort', 'monument', 'cafe', etc.
    latitude = Column(Numeric(10, 8), nullable=False)
    longitude = Column(Numeric(11, 8), nullable=False)
    cover_image_url = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    verified = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    reviews = relationship("Review", back_populates="location", cascade="all, delete-orphan")
    ai_insights = relationship("LocationAIInsights", back_populates="location", uselist=False, cascade="all, delete-orphan")
    photos = relationship("ReviewPhoto", back_populates="location", cascade="all, delete-orphan")
    trip_locations = relationship("TripLocation", back_populates="location", cascade="all, delete-orphan")
