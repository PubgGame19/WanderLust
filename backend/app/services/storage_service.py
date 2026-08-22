import os
import io
import uuid
import logging
from typing import Tuple, Dict, Any, Optional
from datetime import datetime
from PIL import Image, ExifTags
from app.core.config import settings

logger = logging.getLogger("wanderlust.storage")

class StorageService:
    def __init__(self):
        # Base directory for local uploads
        self.upload_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "uploads")
        os.makedirs(self.upload_dir, exist_ok=True)

    def _extract_exif_metadata(self, file_bytes: bytes) -> Dict[str, Any]:
        """
        Parses JPEG/TIFF EXIF data to extract camera model, timestamp, and GPS coordinates
        to verify that the photo was captured by a physical device (anti-fake review mechanism).
        """
        metadata: Dict[str, Any] = {
            "camera_model": None,
            "taken_at": None,
            "gps_latitude": None,
            "gps_longitude": None,
            "is_verified_authentic": False
        }
        try:
            image = Image.open(io.BytesIO(file_bytes))
            exif = image.getexif()
            if not exif:
                return metadata

            # Extract Make & Model
            make = exif.get(271) # Make tag ID
            model = exif.get(272) # Model tag ID
            if model:
                model_str = str(model).strip()
                if make and str(make).strip() not in model_str:
                    metadata["camera_model"] = f"{str(make).strip()} {model_str}"
                else:
                    metadata["camera_model"] = model_str

            # Extract DateTime (Tag 306 or Tag 36867 in Exif IFD)
            date_str = exif.get(306)
            if not date_str:
                try:
                    exif_ifd = exif.get_ifd(ExifTags.IFD.Exif)
                    date_str = exif_ifd.get(36867) or exif_ifd.get(36868)
                except Exception:
                    pass

            if date_str:
                try:
                    metadata["taken_at"] = datetime.strptime(str(date_str).strip(), "%Y:%m:%d %H:%M:%S")
                except Exception:
                    pass

            # Extract GPS Info
            try:
                gps_ifd = exif.get_ifd(ExifTags.IFD.GPSInfo)
                if gps_ifd:
                    # Latitude (Tag 2), Ref (Tag 1)
                    lat_data = gps_ifd.get(2)
                    lat_ref = gps_ifd.get(1)
                    # Longitude (Tag 4), Ref (Tag 3)
                    lon_data = gps_ifd.get(4)
                    lon_ref = gps_ifd.get(3)

                    def _convert_dms(dms_tuple):
                        if not dms_tuple or len(dms_tuple) < 3:
                            return None
                        d = float(dms_tuple[0])
                        m = float(dms_tuple[1])
                        s = float(dms_tuple[2])
                        return d + (m / 60.0) + (s / 3600.0)

                    if lat_data and lon_data:
                        lat_val = _convert_dms(lat_data)
                        lon_val = _convert_dms(lon_data)
                        if lat_val is not None and lon_val is not None:
                            if lat_ref == 'S':
                                lat_val = -lat_val
                            if lon_ref == 'W':
                                lon_val = -lon_val
                            metadata["gps_latitude"] = round(lat_val, 6)
                            metadata["gps_longitude"] = round(lon_val, 6)
            except Exception as e:
                logger.debug("GPS extraction note: %s", e)

            # Verification rule: Authentic if camera model or valid capture timestamp or GPS is present
            if metadata["camera_model"] or metadata["taken_at"] or metadata["gps_latitude"]:
                metadata["is_verified_authentic"] = True

        except Exception as e:
            logger.debug("EXIF parsing error (non-fatal): %s", e)

        return metadata

    def save_file(self, file_bytes: bytes, original_filename: str, content_type: str) -> Dict[str, Any]:
        """
        Saves uploaded media to local storage with EXIF physical verification.
        """
        ext = os.path.splitext(original_filename)[1].lower()
        if not ext:
            if "png" in content_type:
                ext = ".png"
            elif "webp" in content_type:
                ext = ".webp"
            else:
                ext = ".jpg"

        file_id = str(uuid.uuid4())
        unique_filename = f"{file_id}{ext}"
        file_path = os.path.join(self.upload_dir, unique_filename)

        with open(file_path, "wb") as f:
            f.write(file_bytes)

        # Extract EXIF metadata
        exif_info = self._extract_exif_metadata(file_bytes)

        # Generate access URL
        public_url = f"/api/v1/media/{unique_filename}"
        
        return {
            "image_url": public_url,
            "filename": unique_filename,
            "camera_model": exif_info["camera_model"],
            "taken_at": exif_info["taken_at"],
            "gps_latitude": exif_info["gps_latitude"],
            "gps_longitude": exif_info["gps_longitude"],
            "is_verified_authentic": exif_info["is_verified_authentic"]
        }

    def delete_file(self, filename: str) -> bool:
        """Deletes a file from the local upload directory."""
        try:
            path = os.path.join(self.upload_dir, filename)
            if os.path.exists(path):
                os.remove(path)
                return True
        except Exception as e:
            logger.error("Failed to delete local file %s: %s", filename, e)
        return False

storage_service = StorageService()
