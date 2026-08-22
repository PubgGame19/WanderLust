import os
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status, Query
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.user import User
from app.models.review_photo import ReviewPhoto
from app.models.review import Review
from app.models.location import Location
from app.models.trip import Trip
from app.schemas.media import MediaUploadOut, PhotoOut, PhotoAttachRequest
from app.services.storage_service import storage_service
from app.api.v1.deps import get_current_user

router = APIRouter(tags=["Media"])

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024 # 10MB
MAX_FILES_PER_REQUEST = 10

@router.post("/media/upload", response_model=List[MediaUploadOut], status_code=status.HTTP_201_CREATED)
async def upload_media(
    files: List[UploadFile] = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Accepts up to 10 photos per request, validates file types/sizes, 
    extracts physical camera EXIF metadata, and saves files.
    """
    if len(files) > MAX_FILES_PER_REQUEST:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Exceeded maximum limit of {MAX_FILES_PER_REQUEST} images per upload request."
        )

    uploaded_results: List[MediaUploadOut] = []

    for file in files:
        ext = os.path.splitext(file.filename or "")[1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported file extension '{ext}'. Allowed extensions: {', '.join(ALLOWED_EXTENSIONS)}"
            )

        if file.content_type and file.content_type not in ALLOWED_MIME_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported MIME type '{file.content_type}'. Allowed types: {', '.join(ALLOWED_MIME_TYPES)}"
            )

        content = await file.read()
        if len(content) > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File '{file.filename}' exceeds maximum allowed size of 10MB."
            )

        upload_data = storage_service.save_file(
            file_bytes=content,
            original_filename=file.filename or "photo.jpg",
            content_type=file.content_type or "image/jpeg"
        )

        uploaded_results.append(MediaUploadOut(
            image_url=upload_data["image_url"],
            filename=upload_data["filename"],
            camera_model=upload_data["camera_model"],
            taken_at=upload_data["taken_at"],
            gps_latitude=upload_data["gps_latitude"],
            gps_longitude=upload_data["gps_longitude"],
            is_verified_authentic=upload_data["is_verified_authentic"]
        ))

    return uploaded_results

@router.get("/media/{filename}")
async def get_media_file(filename: str):
    """Serves locally stored media files."""
    file_path = os.path.join(storage_service.upload_dir, filename)
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Media file not found"
        )
    return FileResponse(file_path)

@router.get("/locations/{location_id}/photos", response_model=List[PhotoOut])
def get_location_photos(
    location_id: str,
    limit: int = Query(30, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db)
):
    """
    Returns aggregated media for a location node across direct reviews and multi-destination trips.
    """
    loc = db.query(Location).filter(Location.id == location_id).first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")

    photos = (
        db.query(ReviewPhoto)
        .join(Review, ReviewPhoto.review_id == Review.id)
        .filter(Review.location_id == location_id)
        .order_by(ReviewPhoto.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    out: List[PhotoOut] = []
    for p in photos:
        r = p.review
        author = r.user.username if (r and r.user) else None
        trip_title = r.trip.title if (r and r.trip) else None
        trip_id = r.trip_id if r else None

        out.append(PhotoOut(
            id=p.id,
            image_url=p.image_url,
            caption=p.caption,
            created_at=p.created_at,
            location_id=location_id,
            location_name=loc.name,
            trip_id=trip_id,
            trip_title=trip_title,
            user_id=r.user_id if r else None,
            author_username=author,
            camera_model=getattr(p, 'camera_model', None),
            taken_at=getattr(p, 'taken_at', None),
            gps_latitude=getattr(p, 'gps_latitude', None),
            gps_longitude=getattr(p, 'gps_longitude', None),
            is_verified_authentic=getattr(p, 'is_verified_authentic', False)
        ))

    return out

@router.post("/trips/{trip_id}/photos", response_model=List[PhotoOut], status_code=status.HTTP_201_CREATED)
def attach_trip_photos(
    trip_id: str,
    req: PhotoAttachRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to modify this trip")

    results = []
    for idx, url in enumerate(req.photo_urls):
        photo = ReviewPhoto(
            user_id=current_user.id,
            trip_id=trip_id,
            image_url=url,
            display_order=idx,
            is_flagged=False
        )
        db.add(photo)
        db.commit()
        db.refresh(photo)
        results.append(PhotoOut(
            id=photo.id,
            image_url=photo.image_url,
            trip_id=trip_id,
            trip_title=trip.title,
            user_id=current_user.id,
            author_username=current_user.username,
            created_at=photo.created_at
        ))
    return results

@router.post("/reviews/{review_id}/photos", response_model=List[PhotoOut], status_code=status.HTTP_201_CREATED)
def attach_review_photos(
    review_id: str,
    req: PhotoAttachRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    if review.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to modify this review")

    results = []
    for idx, url in enumerate(req.photo_urls):
        photo = ReviewPhoto(
            user_id=current_user.id,
            review_id=review_id,
            location_id=review.location_id,
            trip_id=review.trip_id,
            image_url=url,
            display_order=idx,
            is_flagged=False
        )
        db.add(photo)
        db.commit()
        db.refresh(photo)
        results.append(PhotoOut(
            id=photo.id,
            image_url=photo.image_url,
            location_id=review.location_id,
            trip_id=review.trip_id,
            user_id=current_user.id,
            author_username=current_user.username,
            created_at=photo.created_at
        ))
    return results

@router.delete("/photos/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
@router.delete("/media/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_photo(
    photo_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Deletes an uploaded review photo, enforcing user ownership."""
    photo = db.query(ReviewPhoto).filter(ReviewPhoto.id == photo_id).first()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")

    owner_id = photo.user_id or (photo.review.user_id if photo.review else None)
    if owner_id and owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to delete this photo")

    if photo.image_url.startswith("/api/v1/media/"):
        filename = photo.image_url.replace("/api/v1/media/", "")
        storage_service.delete_file(filename)

    db.delete(photo)
    db.commit()
    return None
