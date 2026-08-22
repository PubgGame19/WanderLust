import uuid
from sqlalchemy import Column, String, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class TripLocation(Base):
    __tablename__ = "trip_locations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    trip_id = Column(String(36), ForeignKey("trips.id", ondelete="CASCADE"), nullable=False, index=True)
    location_id = Column(String(36), ForeignKey("locations.id", ondelete="RESTRICT"), nullable=False, index=True)
    visit_order = Column(Integer, default=1, nullable=False)

    # Relationships
    trip = relationship("Trip", back_populates="trip_locations")
    location = relationship("Location", back_populates="trip_locations")
