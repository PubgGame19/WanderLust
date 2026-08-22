import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import User
from app.models.location import Location
from app.models.review import Review
from app.models.review_photo import ReviewPhoto
from app.schemas.review import ReviewCreate, ReviewCreatedResponse
from app.api.v1.deps import get_current_user
from app.services.queue_service import queue_service

logger = logging.getLogger("wanderlust.reviews")
router = APIRouter(prefix="/reviews", tags=["Reviews"])

@router.post("", response_model=ReviewCreatedResponse, status_code=status.HTTP_201_CREATED)
def submit_review(
    review_in: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Submits an immutable raw review.
    1. Validates strict foreign key constraint to location_id.
    2. Writes raw review & photos to database.
    3. Enqueues structured AI extraction job to Redis queue.
    4. Immediately returns HTTP 201 with ai_status: 'pending'.
    """
    # 1. Spatial Normalization Invariant Check
    location = db.query(Location).filter(Location.id == review_in.location_id).first()
    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Invalid location_id '{review_in.location_id}'. Target location does not exist."
        )

    # 2. Immutable Raw Data Persistence
    new_review = Review(
        user_id=current_user.id,
        location_id=review_in.location_id,
        trip_id=review_in.trip_id,
        rating=review_in.rating,
        original_text=review_in.original_text,
        visit_date=review_in.visit_date,
        expense_amount=review_in.expense_amount,
        currency=review_in.currency or "USD",
        group_size=review_in.group_size,
        transport_mode=review_in.transport_mode,
        starting_location=review_in.starting_location,
        helpful_count=0
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)

    # Photos persistence
    if review_in.photo_urls:
        for idx, url in enumerate(review_in.photo_urls):
            photo = ReviewPhoto(
                user_id=current_user.id,
                trip_id=new_review.trip_id,
                review_id=new_review.id,
                location_id=location.id,
                image_url=url,
                thumbnail_url=url,
                display_order=idx,
                is_flagged=False
            )
            db.add(photo)
        db.commit()

    # 3. Resilient Asynchronous Task Enqueueing
    job_payload = {
        "review_id": new_review.id,
        "location_id": location.id,
        "text": new_review.original_text,
        "currency": new_review.currency or "USD",
        "created_at": new_review.created_at.isoformat()
    }
    queue_service.enqueue_review_job(job_payload)

    # 4. Return HTTP 201 Response with ai_status: pending
    return ReviewCreatedResponse(
        review_id=new_review.id,
        location_id=new_review.location_id,
        trip_id=new_review.trip_id,
        rating=new_review.rating,
        created_at=new_review.created_at,
        ai_status="pending",
        message="Review recorded successfully. Background AI fact-extraction enqueued."
    )
