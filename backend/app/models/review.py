import uuid
from datetime import datetime, date, timezone
from sqlalchemy import Column, String, Text, Integer, SmallInteger, Numeric, Date, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base

class Review(Base):
    __tablename__ = "reviews"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    location_id = Column(String(36), ForeignKey("locations.id", ondelete="RESTRICT"), nullable=False, index=True)
    trip_id = Column(String(36), ForeignKey("trips.id", ondelete="CASCADE"), nullable=True, index=True)
    rating = Column(SmallInteger, nullable=False) # 1 to 5
    original_text = Column(Text, nullable=False)
    visit_date = Column(Date, nullable=False, default=date.today)
    expense_amount = Column(Numeric(12, 2), nullable=True)
    currency = Column(String(3), default="USD", nullable=True)
    group_size = Column(Integer, nullable=True)
    transport_mode = Column(String(50), nullable=True)
    starting_location = Column(String(150), nullable=True)
    helpful_count = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    __table_args__ = (
        CheckConstraint("rating >= 1 AND rating <= 5", name="check_rating_range"),
    )

    # Relationships
    user = relationship("User", back_populates="reviews")
    location = relationship("Location", back_populates="reviews")
    trip = relationship("Trip", back_populates="experiences")
    ai_data = relationship("ReviewAIData", back_populates="review", uselist=False, cascade="all, delete-orphan")
    photos = relationship("ReviewPhoto", back_populates="review", cascade="all, delete-orphan")
