import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, SmallInteger, Numeric, Date, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Trip(Base):
    __tablename__ = "trips"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False, index=True)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    description = Column(Text, nullable=True)
    total_expense = Column(Numeric(12, 2), nullable=True)
    currency = Column(String(3), default="INR", nullable=True)
    transport_mode = Column(String(50), nullable=True)
    rating = Column(SmallInteger, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    user = relationship("User", back_populates="trips")
    trip_locations = relationship("TripLocation", back_populates="trip", cascade="all, delete-orphan", order_by="TripLocation.visit_order")
    experiences = relationship("Review", back_populates="trip", cascade="all, delete-orphan")
    photos = relationship("ReviewPhoto", back_populates="trip", cascade="all, delete-orphan")
