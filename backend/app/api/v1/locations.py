from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.database import get_db, calculate_haversine_distance_km
from app.models.location import Location
from app.models.review import Review
from app.models.location_ai_insights import LocationAIInsights
from app.schemas.location import LocationCreate, LocationOut, LocationAIInsightsOut, LocationFeedResponse
from app.schemas.review import ReviewFeedItem, ReviewAILayer, ReviewRawLayer
from app.schemas.user import UserAuthorOut

router = APIRouter(prefix="/locations", tags=["Locations"])

def _format_review_feed_item(r: Review) -> ReviewFeedItem:
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
    raw_layer = ReviewRawLayer(
        original_text=r.original_text,
        expense_amount=float(r.expense_amount) if r.expense_amount is not None else None,
        currency=r.currency or "USD",
        group_size=r.group_size,
        transport_mode=r.transport_mode,
        starting_location=r.starting_location,
        visit_date=r.visit_date,
        photos=photo_urls
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
        raw_layer=raw_layer
    )

@router.get("", response_model=List[LocationOut])
def list_locations(
    search: Optional[str] = Query(None, description="Search term for name, city, state, or country"),
    place_type: Optional[str] = Query(None, description="Filter by place type (mountain, beach, fort, cafe, etc.)"),
    country: Optional[str] = Query(None, description="Filter by country"),
    lat: Optional[float] = Query(None, description="User latitude for distance calculation"),
    lng: Optional[float] = Query(None, description="User longitude for distance calculation"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Lists validated location nodes with optional spatial distance calculation and search filtering."""
    query = db.query(Location).filter(Location.verified == True)

    if search:
        term = f"%{search.strip().lower()}%"
        query = query.filter(
            or_(
                Location.name.ilike(term),
                Location.city.ilike(term),
                Location.state_region.ilike(term),
                Location.country.ilike(term),
                Location.description.ilike(term)
            )
        )
    
    if place_type:
        query = query.filter(Location.place_type.ilike(place_type))
        
    if country:
        query = query.filter(Location.country.ilike(country))

    locations = query.offset(offset).limit(limit).all()
    results = []

    for loc in locations:
        dist = None
        if lat is not None and lng is not None:
            dist = calculate_haversine_distance_km(lat, lng, float(loc.latitude), float(loc.longitude))
            
        revs = loc.reviews
        avg_rating = round(sum(r.rating for r in revs) / len(revs), 1) if revs else None
        
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
            distance_km=dist,
            average_rating=avg_rating,
            review_count=len(revs)
        )
        results.append(loc_out)

    if lat is not None and lng is not None:
        results.sort(key=lambda x: x.distance_km if x.distance_km is not None else float('inf'))

    return results

@router.post("", response_model=LocationOut, status_code=status.HTTP_201_CREATED)
def create_location(loc_in: LocationCreate, db: Session = Depends(get_db)):
    """Creates a new hierarchical location node."""
    existing = db.query(Location).filter(Location.slug == loc_in.slug).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Location with slug '{loc_in.slug}' already exists"
        )

    location = Location(
        name=loc_in.name,
        slug=loc_in.slug,
        continent=loc_in.continent,
        country=loc_in.country,
        state_region=loc_in.state_region,
        city=loc_in.city,
        place_type=loc_in.place_type,
        latitude=loc_in.latitude,
        longitude=loc_in.longitude,
        cover_image_url=loc_in.cover_image_url,
        description=loc_in.description,
        verified=True
    )
    db.add(location)
    db.commit()
    db.refresh(location)

    return LocationOut(
        id=location.id,
        name=location.name,
        slug=location.slug,
        continent=location.continent,
        country=location.country,
        state_region=location.state_region,
        city=location.city,
        place_type=location.place_type,
        latitude=float(location.latitude),
        longitude=float(location.longitude),
        cover_image_url=location.cover_image_url,
        description=location.description,
        verified=location.verified,
        created_at=location.created_at,
        distance_km=None,
        average_rating=None,
        review_count=0
    )

@router.get("/{location_id}", response_model=LocationOut)
def get_location(
    location_id: str,
    lat: Optional[float] = Query(None, description="User latitude for distance calculation"),
    lng: Optional[float] = Query(None, description="User longitude for distance calculation"),
    db: Session = Depends(get_db)
):
    """Retrieves a single location node by ID with computed ratings and distance."""
    loc = db.query(Location).filter(Location.id == location_id).first()
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Location '{location_id}' not found"
        )
    
    dist = None
    if lat is not None and lng is not None:
        dist = calculate_haversine_distance_km(lat, lng, float(loc.latitude), float(loc.longitude))
        
    revs = loc.reviews
    avg_rating = round(sum(r.rating for r in revs) / len(revs), 1) if revs else None
    
    return LocationOut(
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
        distance_km=dist,
        average_rating=avg_rating,
        review_count=len(revs)
    )

@router.get("/{location_id}/feed", response_model=LocationFeedResponse)
def get_location_feed(
    location_id: str,
    lat: Optional[float] = Query(None, description="User latitude for distance calculation"),
    lng: Optional[float] = Query(None, description="User longitude for distance calculation"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """
    Returns location metadata, PostGIS distance (if coords provided), 
    location_ai_insights object, and paginated aggregated review list across all direct reviews and trips.
    """
    loc = db.query(Location).filter(Location.id == location_id).first()
    if not loc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Location '{location_id}' not found"
        )

    # Calculate distance
    dist = None
    if lat is not None and lng is not None:
        dist = calculate_haversine_distance_km(lat, lng, float(loc.latitude), float(loc.longitude))

    # Fetch reviews (both direct and trip-embedded)
    reviews_query = db.query(Review).filter(Review.location_id == location_id).order_by(Review.created_at.desc())
    total_reviews = reviews_query.count()
    reviews = reviews_query.offset(offset).limit(limit).all()

    avg_rating = round(sum(r.rating for r in loc.reviews) / len(loc.reviews), 1) if loc.reviews else None

    location_out = LocationOut(
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
        distance_km=dist,
        average_rating=avg_rating,
        review_count=total_reviews
    )

    insights_out = None
    if loc.ai_insights:
        insights_out = LocationAIInsightsOut(
            location_id=loc.ai_insights.location_id,
            aggregated_positives=loc.ai_insights.aggregated_positives or [],
            aggregated_challenges=loc.ai_insights.aggregated_challenges or [],
            expense_range_min=float(loc.ai_insights.expense_range_min) if loc.ai_insights.expense_range_min else None,
            expense_range_max=float(loc.ai_insights.expense_range_max) if loc.ai_insights.expense_range_max else None,
            dominant_currency=loc.ai_insights.dominant_currency or "USD",
            best_visit_times=loc.ai_insights.best_visit_times or [],
            sample_size=loc.ai_insights.sample_size or 0,
            updated_at=loc.ai_insights.updated_at
        )

    review_items = [_format_review_feed_item(r) for r in reviews]

    return LocationFeedResponse(
        location=location_out,
        insights=insights_out,
        total_reviews=total_reviews,
        reviews=review_items
    )

@router.get("/{location_id}/experiences", response_model=List[ReviewFeedItem])
def get_location_experiences(
    location_id: str,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """Returns all experiences for a specific location across all trips and individual reviews."""
    loc = db.query(Location).filter(Location.id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")
        
    reviews = db.query(Review).filter(Review.location_id == location_id).order_by(Review.created_at.desc()).offset(offset).limit(limit).all()
    return [_format_review_feed_item(r) for r in reviews]
