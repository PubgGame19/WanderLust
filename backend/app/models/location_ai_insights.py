import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Numeric, Integer, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base

class LocationAIInsights(Base):
    __tablename__ = "location_ai_insights"

    location_id = Column(String(36), ForeignKey("locations.id", ondelete="CASCADE"), primary_key=True)
    aggregated_positives = Column(JSON, default=list, nullable=False)
    aggregated_challenges = Column(JSON, default=list, nullable=False)
    expense_range_min = Column(Numeric(12, 2), nullable=True)
    expense_range_max = Column(Numeric(12, 2), nullable=True)
    dominant_currency = Column(String(3), default="USD", nullable=False)
    best_visit_times = Column(JSON, default=list, nullable=False)
    sample_size = Column(Integer, default=0, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    location = relationship("Location", back_populates="ai_insights")
