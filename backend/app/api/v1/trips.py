import logging
import re
import traceback
from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.database import get_db
from app.models.user import User
from app.models.location import Location
from app.models.trip import Trip
from app.models.trip_location import TripLocation
from app.models.review import Review
from app.models.review_photo import ReviewPhoto
from app.models.review_ai_data import ReviewAIData
from app.schemas.trip import TripCreate, TripOut, TripListItemOut, TripPlaceOut, TripPlaceExperienceCreate
from app.schemas.location import LocationOut
from app.schemas.review import ReviewFeedItem, ReviewAILayer, ReviewRawLayer
from app.schemas.user import UserAuthorOut
from app.api.v1.deps import get_current_user
from app.services.queue_service import queue_service

logger = logging.getLogger("wanderlust.trips")
router = APIRouter(prefix="/trips", tags=["Trips"])

def _slugify(text: str) -> str:
    s = text.lower().strip()
    s = re.sub(r'[^\w\s-]', '', s)
    s = re.sub(r'[\s_-]+', '-', s)
    return s

def _format_feed_item(r: Review) -> ReviewFeedItem:
    ai_layer = ReviewAILayer(
        summary=r.ai_data.ai_summary if r.ai_data else "AI analysis pending...",
        highlights=r.ai_data.highlights if (r.ai_data and r.ai_data.highlights) else [],
        challenges=r.ai_data.challenges if (r.ai_data and r.ai_data.challenges) else [],
        extracted_tips=r.ai_data.extracted_tips if (r.ai_data and r.ai_data.extracted_tips) else [],
        sentiment=r.ai_data.sentiment if r.ai_data else "neutral",
        extracted_budget_per_person=float(r.ai_data.extracted_budget_per_person) if (r.ai_data and r.ai_data.extracted_budget_per_person) else None,
        model_version=r.ai_data.model_version if r.ai_data else None,
        processing_status=r.ai_data.processing_status if r.ai_data else "pending"
    )
    photo_urls = [p.image_url for p in r.photos]
    is_photo_verified = any(getattr(p, 'is_verified_authentic', False) for p in r.photos) if r.photos else False
    camera_model = next((p.camera_model for p in r.photos if getattr(p, 'camera_model', None)), None) if r.photos else None

    raw_layer = ReviewRawLayer(
        original_text=r.original_text,
        expense_amount=float(r.expense_amount) if r.expense_amount is not None else None,
        currency=r.currency or "INR",
        group_size=r.group_size,
        transport_mode=r.transport_mode,
        starting_location=r.starting_location,
        visit_date=r.visit_date,
        photos=photo_urls,
        is_photo_verified=is_photo_verified,
        camera_model=camera_model
    )
    author_out = UserAuthorOut(
        id=r.user.id if r.user else "anonymous",
        username=r.user.username if r.user else "Traveler",
        avatar_url=r.user.avatar_url if r.user else None
    )
    return ReviewFeedItem(
        review_id=r.id,
        location_id=r.location_id,
        location_name=r.location.name if r.location else None,
        trip_id=r.trip_id,
        trip_title=r.trip.title if r.trip else None,
        author=author_out,
        rating=r.rating,
        created_at=r.created_at,
        ai_layer=ai_layer,
        raw_layer=raw_layer,
        is_photo_verified=is_photo_verified,
        camera_model=camera_model
    )

@router.get("", response_model=List[TripListItemOut])
def list_trips(
    search: Optional[str] = Query(None, description="Search trip title, description, or visited locations"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Lists published trips with author and summary of visited destinations (Public read for Guests & Users)."""
    query = db.query(Trip).order_by(Trip.created_at.desc())

    if search:
        term = f"%{search.strip().lower()}%"
        query = query.filter(
            or_(
                Trip.title.ilike(term),
                Trip.description.ilike(term)
            )
        )

    trips = query.offset(offset).limit(limit).all()
    results = []

    for t in trips:
        place_names = [tl.location.name for tl in t.trip_locations if tl.location]
        author = UserAuthorOut(
            id=t.user.id if t.user else "anonymous",
            username=t.user.username if t.user else "Explorer",
            avatar_url=t.user.avatar_url if t.user else None
        )
        item = TripListItemOut(
            id=t.id,
            title=t.title,
            start_date=t.start_date,
            end_date=t.end_date,
            description=t.description,
            total_expense=float(t.total_expense) if t.total_expense is not None else None,
            currency=t.currency or "INR",
            transport_mode=t.transport_mode,
            rating=t.rating,
            author=author,
            places_count=len(t.trip_locations),
            visited_place_names=place_names,
            created_at=t.created_at
        )
        results.append(item)

    return results

@router.post("", response_model=TripOut, status_code=status.HTTP_201_CREATED)
def create_trip(
    trip_in: TripCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Creates a new multi-destination Trip with individual location experiences and multiple photos.
    Strictly requires authentication.
    """
    try:
        # 1. Create Trip Record
        new_trip = Trip(
            user_id=current_user.id,
            title=trip_in.title.strip(),
            start_date=trip_in.start_date,
            end_date=trip_in.end_date,
            description=trip_in.description.strip() if trip_in.description else None,
            total_expense=trip_in.total_expense,
            currency=trip_in.currency or "INR",
            transport_mode=trip_in.transport_mode,
            rating=trip_in.rating
        )
        db.add(new_trip)
        db.commit()
        db.refresh(new_trip)

        places_out: List[TripPlaceOut] = []
        created_locations: List[Location] = []

        # 2. Process each visited place & experience
        for idx, place_data in enumerate(trip_in.places):
            loc: Optional[Location] = None

            # A. Resolve or Create Location Node
            if place_data.location_id and place_data.location_id.strip():
                loc = db.query(Location).filter(Location.id == place_data.location_id.strip()).first()
                if not loc:
                    logger.warning("Location ID '%s' not found, searching by name fallback", place_data.location_id)
            
            if not loc and place_data.new_location_name and place_data.new_location_name.strip():
                loc_name = place_data.new_location_name.strip()
                loc_slug = _slugify(f"{loc_name}-{place_data.city or place_data.country or 'place'}")
                
                # Check existing by slug
                loc = db.query(Location).filter(Location.slug == loc_slug).first()
                if not loc:
                    loc = Location(
                        name=loc_name,
                        slug=loc_slug,
                        continent="Asia",
                        country=place_data.country or "India",
                        state_region=place_data.state_region,
                        city=place_data.city,
                        place_type=place_data.place_type or "place",
                        latitude=place_data.latitude if place_data.latitude is not None else 19.0760,
                        longitude=place_data.longitude if place_data.longitude is not None else 72.8777,
                        description=place_data.description or f"Scenic destination visited during {new_trip.title}",
                        verified=True
                    )
                    db.add(loc)
                    db.commit()
                    db.refresh(loc)

            if not loc:
                logger.warning("Skipping place #%d: Could not resolve or create location", idx + 1)
                continue

            created_locations.append(loc)

            # B. Link Location to Trip in Order
            trip_loc = TripLocation(
                trip_id=new_trip.id,
                location_id=loc.id,
                visit_order=place_data.visit_order or (idx + 1)
            )
            db.add(trip_loc)
            db.commit()

            # C. Create Immutable Location Experience Review inside Trip
            review_item_out: Optional[ReviewFeedItem] = None
            raw_text = place_data.raw_text.strip() if place_data.raw_text else ""
            if place_data.tips and place_data.tips.strip():
                if raw_text:
                    raw_text += f"\n\nTip: {place_data.tips.strip()}"
                else:
                    raw_text = f"Tip: {place_data.tips.strip()}"

            # Only create review record if text or photos exist
            if raw_text or place_data.photo_urls:
                if not raw_text:
                    raw_text = f"Visited {loc.name} as part of {new_trip.title}."

                new_review = Review(
                    user_id=current_user.id,
                    location_id=loc.id,
                    trip_id=new_trip.id,
                    rating=place_data.rating or 5,
                    original_text=raw_text,
                    visit_date=place_data.visit_date or trip_in.start_date,
                    expense_amount=place_data.expense_amount,
                    currency=place_data.currency or trip_in.currency or "INR",
                    transport_mode=place_data.transport_mode or trip_in.transport_mode,
                    helpful_count=0
                )
                db.add(new_review)
                db.commit()
                db.refresh(new_review)

                # Persist multiple photos associated with this location experience
                if place_data.photo_urls:
                    for p_idx, p_url in enumerate(place_data.photo_urls):
                        if p_url and p_url.strip():
                            photo_rec = ReviewPhoto(
                                user_id=current_user.id,
                                trip_id=new_trip.id,
                                review_id=new_review.id,
                                location_id=loc.id,
                                image_url=p_url.strip(),
                                display_order=p_idx
                            )
                            db.add(photo_rec)
                    db.commit()
                    db.refresh(new_review)

                # Enqueue asynchronous AI extraction job
                try:
                    queue_service.enqueue_review_job({
                        "review_id": new_review.id,
                        "location_id": loc.id,
                        "text": new_review.original_text,
                        "currency": new_review.currency or "INR",
                        "created_at": new_review.created_at.isoformat()
                    })
                except Exception as q_err:
                    logger.warning("Could not enqueue AI extraction job: %s", q_err)

                review_item_out = _format_feed_item(new_review)

            loc_out = LocationOut(
                id=loc.id,
                name=loc.name,
                slug=loc.slug,
                continent=loc.continent,
                country=loc.country,
                state_region=loc.state_region,
                city=loc.city,
                place_type=loc.place_type,
                latitude=float(loc.latitude),
                longitude=float(loc.longitude),
                cover_image_url=loc.cover_image_url,
                description=loc.description,
                verified=loc.verified,
                created_at=loc.created_at,
                distance_km=None,
                average_rating=None,
                review_count=len(loc.reviews)
            )

            places_out.append(TripPlaceOut(
                location=loc_out,
                visit_order=trip_loc.visit_order,
                experience=review_item_out
            ))

        # 3. Handle any trip-level photos
        if trip_in.photo_urls and created_locations:
            primary_loc_id = created_locations[0].id
            for p_idx, p_url in enumerate(trip_in.photo_urls):
                if p_url and p_url.strip():
                    trip_photo = ReviewPhoto(
                        user_id=current_user.id,
                        trip_id=new_trip.id,
                        review_id=None,
                        location_id=primary_loc_id,
                        image_url=p_url.strip(),
                        display_order=p_idx
                    )
                    db.add(trip_photo)
            db.commit()

        author = UserAuthorOut(
            id=current_user.id,
            username=current_user.username,
            avatar_url=current_user.avatar_url
        )

        return TripOut(
            id=new_trip.id,
            title=new_trip.title,
            start_date=new_trip.start_date,
            end_date=new_trip.end_date,
            description=new_trip.description,
            total_expense=float(new_trip.total_expense) if new_trip.total_expense is not None else None,
            currency=new_trip.currency or "INR",
            transport_mode=new_trip.transport_mode,
            rating=new_trip.rating,
            author=author,
            places=places_out,
            places_count=len(places_out),
            created_at=new_trip.created_at
        )
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        error_trace = traceback.format_exc()
        logger.error("Failed to create trip for user %s:\n%s", current_user.id, error_trace)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Trip creation failed: {str(e)}"
        )

@router.get("/{trip_id}", response_model=TripOut)
def get_trip_detail(trip_id: str, db: Session = Depends(get_db)):
    """Fetches complete trip details with visited locations, photos, and individual experiences (Public read)."""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail=f"Trip '{trip_id}' not found")

    places_out: List[TripPlaceOut] = []
    # Map experiences by location_id for this trip
    exp_by_loc = {r.location_id: r for r in trip.experiences}

    for tl in trip.trip_locations:
        loc = tl.location
        if not loc:
            continue
        
        loc_out = LocationOut(
            id=loc.id,
            name=loc.name,
            slug=loc.slug,
            continent=loc.continent,
            country=loc.country,
            state_region=loc.state_region,
            city=loc.city,
            place_type=loc.place_type,
            latitude=float(loc.latitude),
            longitude=float(loc.longitude),
            cover_image_url=loc.cover_image_url,
            description=loc.description,
            verified=loc.verified,
            created_at=loc.created_at,
            distance_km=None,
            average_rating=None,
            review_count=len(loc.reviews)
        )

        r = exp_by_loc.get(loc.id)
        experience_out = _format_feed_item(r) if r else None

        places_out.append(TripPlaceOut(
            location=loc_out,
            visit_order=tl.visit_order,
            experience=experience_out
        ))

    author = UserAuthorOut(
        id=trip.user.id if trip.user else "anonymous",
        username=trip.user.username if trip.user else "Explorer",
        avatar_url=trip.user.avatar_url if trip.user else None
    )

    return TripOut(
        id=trip.id,
        title=trip.title,
        start_date=trip.start_date,
        end_date=trip.end_date,
        description=trip.description,
        total_expense=float(trip.total_expense) if trip.total_expense is not None else None,
        currency=trip.currency or "INR",
        transport_mode=trip.transport_mode,
        rating=trip.rating,
        author=author,
        places=places_out,
        places_count=len(places_out),
        created_at=trip.created_at
    )

@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_trip(
    trip_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Deletes a trip owned by the authenticated user."""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to delete this trip")

    db.delete(trip)
    db.commit()
    return None
