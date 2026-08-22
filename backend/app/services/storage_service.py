import os
import uuid
import logging
from datetime import datetime
from typing import Dict, Any, List
from fastapi import UploadFile, HTTPException, status
from app.core.config import settings

logger = logging.getLogger("wanderlust.storage")

class StorageService:
    def __init__(self):
        self.upload_dir = os.path.abspath(settings.UPLOAD_DIR)
        os.makedirs(self.upload_dir, exist_ok=True)

    def validate_file(self, file: UploadFile, content: bytes) -> None:
        """Validates MIME type, file extension, and maximum file size."""
        # 1. Check size limit
        max_bytes = settings.MAX_IMAGE_FILE_SIZE_MB * 1024 * 1024
        if len(content) > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File '{file.filename}' exceeds maximum allowed size of {settings.MAX_IMAGE_FILE_SIZE_MB}MB."
            )

        # 2. Check extension
        filename = file.filename or ""
        ext = filename.split(".")[-1].lower() if "." in filename else ""
        if ext not in settings.ALLOWED_IMAGE_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported file extension '.{ext}'. Allowed types: {', '.join(settings.ALLOWED_IMAGE_EXTENSIONS)}"
            )

        # 3. Check MIME type
        content_type = file.content_type or ""
        if content_type.lower() not in settings.ALLOWED_IMAGE_MIMES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported MIME type '{content_type}'. Allowed types: {', '.join(settings.ALLOWED_IMAGE_MIMES)}"
            )

    async def save_file(self, file: UploadFile, subfolder: str = "media") -> Dict[str, Any]:
        """Saves an uploaded file according to configured storage provider (Local, Cloudinary, or S3)."""
        content = await file.read()
        self.validate_file(file, content)

        ext = (file.filename or "image.jpg").split(".")[-1].lower()
        unique_filename = f"{uuid.uuid4().hex}.{ext}"

        if settings.STORAGE_PROVIDER == "cloudinary":
            if not settings.CLOUDINARY_URL:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Cloudinary storage is configured, but CLOUDINARY_URL environment variable is missing on backend."
                )
            try:
                import cloudinary
                import cloudinary.uploader
                upload_result = cloudinary.uploader.upload(content, folder=f"wanderlust/{subfolder}")
                return {
                    "image_url": upload_result.get("secure_url"),
                    "thumbnail_url": upload_result.get("secure_url"),
                    "filename": unique_filename,
                    "size_bytes": len(content),
                    "storage_provider": "cloudinary"
                }
            except Exception as e:
                logger.error(f"Cloudinary upload failed: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Cloudinary upload error: {str(e)}"
                )

        elif settings.STORAGE_PROVIDER == "s3":
            if not settings.AWS_S3_BUCKET:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="AWS S3 storage is configured, but AWS_S3_BUCKET environment variable is missing on backend."
                )
            try:
                import boto3
                s3 = boto3.client("s3")
                s3_key = f"uploads/{subfolder}/{unique_filename}"
                s3.put_object(Bucket=settings.AWS_S3_BUCKET, Key=s3_key, Body=content, ContentType=file.content_type)
                s3_url = f"https://{settings.AWS_S3_BUCKET}.s3.amazonaws.com/{s3_key}"
                return {
                    "image_url": s3_url,
                    "thumbnail_url": s3_url,
                    "filename": unique_filename,
                    "size_bytes": len(content),
                    "storage_provider": "s3"
                }
            except Exception as e:
                logger.error(f"AWS S3 upload failed: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"AWS S3 upload error: {str(e)}"
                )

        else:
            # Default Local Storage
            now = datetime.now()
            rel_dir = os.path.join(now.strftime("%Y"), now.strftime("%m"))
            target_dir = os.path.join(self.upload_dir, rel_dir)
            os.makedirs(target_dir, exist_ok=True)

            target_path = os.path.join(target_dir, unique_filename)
            with open(target_path, "wb") as f:
                f.write(content)

            # Web-accessible URL path
            url_path = f"/uploads/{now.strftime('%Y')}/{now.strftime('%m')}/{unique_filename}"
            return {
                "image_url": url_path,
                "thumbnail_url": url_path,
                "filename": unique_filename,
                "size_bytes": len(content),
                "storage_provider": "local"
            }

    def delete_file(self, image_url: str) -> bool:
        """Safely removes file from local disk if it starts with /uploads."""
        if image_url.startswith("/uploads/"):
            rel_path = image_url.replace("/uploads/", "")
            full_path = os.path.join(self.upload_dir, rel_path.replace("/", os.sep))
            if os.path.exists(full_path):
                try:
                    os.remove(full_path)
                    return True
                except Exception as e:
                    logger.error(f"Error deleting file {full_path}: {e}")
        return False

storage_service = StorageService()
