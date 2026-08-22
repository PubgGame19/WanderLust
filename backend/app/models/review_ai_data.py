import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Numeric, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base

class ReviewAIData(Base):
    __tablename__ = "review_ai_data"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    review_id = Column(String(36), ForeignKey("reviews.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    ai_summary = Column(Text, nullable=False)
    highlights = Column(JSON, default=list, nullable=False)
    challenges = Column(JSON, default=list, nullable=False)
    extracted_tips = Column(JSON, default=list, nullable=False)
    sentiment = Column(String(20), nullable=False) # 'positive', 'mixed', 'negative', 'neutral'
    extracted_budget_per_person = Column(Numeric(12, 2), nullable=True)
    model_version = Column(String(50), nullable=False, default="wanderlust-gemini-pro-v1")
    processing_status = Column(String(20), default="completed", nullable=False) # 'pending', 'completed', 'failed'
    processed_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    review = relationship("Review", back_populates="ai_data")
