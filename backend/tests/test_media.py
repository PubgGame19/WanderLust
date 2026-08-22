import io
import pytest
from datetime import date
from fastapi.testclient import TestClient

def _create_mock_image(filename="photo.jpg", content_type="image/jpeg", size_kb=50) -> tuple:
    # Generates a valid mock JPEG/PNG file tuple for multipart upload
    file_bytes = b"\xff\xd8\xff\xe0" + b"\x00" * (size_kb * 1024)
    return (filename, io.BytesIO(file_bytes), content_type)

def test_guest_cannot_upload_photos(client: TestClient):
    # Unauthenticated attempt to upload media must return 401
    file_tuple = _create_mock_image("test.jpg")
    res = client.post("/api/v1/media/upload", files=[("files", file_tuple)])
    assert res.status_code == 401

def test_authenticated_user_can_upload_multiple_photos(client: TestClient):
    # 1. Register User
    reg = client.post("/api/v1/auth/register", json={
        "email": "photographer@test.com",
        "username": "photo_traveler",
        "password": "password123"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Upload 3 valid images
    files = [
        ("files", _create_mock_image("pic1.jpg", "image/jpeg")),
        ("files", _create_mock_image("pic2.png", "image/png")),
        ("files", _create_mock_image("pic3.webp", "image/webp")),
    ]
    res = client.post("/api/v1/media/upload", files=files, headers=headers)
    assert res.status_code == 201
    data = res.json()
    assert len(data) == 3
    assert all("image_url" in item for item in data)
    assert all("filename" in item for item in data)

def test_demo_mode_token_upload_and_trip_creation(client: TestClient):
    # Demo mock token is accepted and injects demo user seamlessly
    demo_headers = {"Authorization": "Bearer demo_jwt_token_2026_wanderlust_active"}
    files = [("files", _create_mock_image("demo_pic.jpg", "image/jpeg"))]
    res_upload = client.post("/api/v1/media/upload", files=files, headers=demo_headers)
    assert res_upload.status_code == 201
    img_url = res_upload.json()[0]["image_url"]

    # Demo trip creation with uploaded photo
    trip_payload = {
        "title": "Demo Weekend Trip",
        "start_date": "2026-08-20",
        "end_date": "2026-08-22",
        "description": "Demo mode trip creation with photos",
        "photo_urls": [img_url],
        "places": [
            {
                "new_location_name": "Demo Sunset Point",
                "city": "Lonavala",
                "rating": 5,
                "raw_text": "Great demo experience at sunset point!",
                "photo_urls": [img_url]
            }
        ]
    }
    res_trip = client.post("/api/v1/trips", json=trip_payload, headers=demo_headers)
    assert res_trip.status_code == 201
    assert res_trip.json()["title"] == "Demo Weekend Trip"

def test_maximum_image_count_enforced(client: TestClient):
    reg = client.post("/api/v1/auth/register", json={
        "email": "limit_test@test.com",
        "username": "limit_tester",
        "password": "password123"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Try uploading 11 images (limit is 10)
    files = [("files", _create_mock_image(f"pic_{i}.jpg")) for i in range(11)]
    res = client.post("/api/v1/media/upload", files=files, headers=headers)
    assert res.status_code == 400
    assert "Exceeded maximum limit of 10 images" in res.json()["detail"]

def test_invalid_file_type_rejected(client: TestClient):
    reg = client.post("/api/v1/auth/register", json={
        "email": "bad_file@test.com",
        "username": "bad_uploader",
        "password": "password123"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Attempt uploading .txt / text/plain file
    bad_file = ("script.txt", io.BytesIO(b"malicious script content"), "text/plain")
    res = client.post("/api/v1/media/upload", files=[("files", bad_file)], headers=headers)
    assert res.status_code == 400
    assert "Unsupported file extension" in res.json()["detail"] or "Unsupported MIME type" in res.json()["detail"]

def test_user_cannot_attach_or_delete_another_users_photos(client: TestClient):
    # User A creates a trip
    reg_a = client.post("/api/v1/auth/register", json={
        "email": "owner_a@test.com",
        "username": "owner_a",
        "password": "password123"
    })
    token_a = reg_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # User B
    reg_b = client.post("/api/v1/auth/register", json={
        "email": "attacker_b@test.com",
        "username": "attacker_b",
        "password": "password123"
    })
    token_b = reg_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # Create location
    loc = client.post("/api/v1/locations", json={
        "name": "Ajanta Caves",
        "slug": "ajanta-caves-aurangabad",
        "continent": "Asia",
        "country": "India",
        "state_region": "Maharashtra",
        "city": "Aurangabad",
        "place_type": "monument",
        "latitude": 20.5519,
        "longitude": 75.7033,
    }).json()

    # User A creates trip with photo
    trip_payload = {
        "title": "Ajanta Heritage Tour",
        "start_date": "2026-08-10",
        "end_date": "2026-08-12",
        "places": [
            {
                "location_id": loc["id"],
                "rating": 5,
                "raw_text": "Ancient rock-cut cave monuments. Stunning frescoes and sculptures.",
                "photo_urls": ["/uploads/2026/08/ajanta_1.jpg", "/uploads/2026/08/ajanta_2.jpg"]
            }
        ]
    }
    trip_a = client.post("/api/v1/trips", json=trip_payload, headers=headers_a).json()

    # User B attempts to attach photos to User A's trip -> 403 Forbidden
    res_b_attach = client.post(
        f"/api/v1/trips/{trip_a['id']}/photos",
        json={"photo_urls": ["/uploads/fake.jpg"]},
        headers=headers_b
    )
    assert res_b_attach.status_code == 403

    # User A attaches valid photo to review
    rev_id = trip_a["places"][0]["experience"]["review_id"]
    res_a_attach = client.post(
        f"/api/v1/reviews/{rev_id}/photos",
        json={"photo_urls": ["/uploads/2026/08/ajanta_3.jpg"]},
        headers=headers_a
    )
    assert res_a_attach.status_code == 201
    photo_id = res_a_attach.json()[0]["id"]

    # User B attempts to delete User A's photo -> 403 Forbidden
    res_b_delete = client.delete(f"/api/v1/photos/{photo_id}", headers=headers_b)
    assert res_b_delete.status_code == 403

    # User A deletes their own photo -> 204 No Content
    res_a_delete = client.delete(f"/api/v1/photos/{photo_id}", headers=headers_a)
    assert res_a_delete.status_code == 204

def test_multiple_photos_appear_in_location_feed_and_trip_detail(client: TestClient):
    reg = client.post("/api/v1/auth/register", json={
        "email": "gallery_user@test.com",
        "username": "gallery_explorer",
        "password": "password123"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create location
    loc = client.post("/api/v1/locations", json={
        "name": "Lonar Crater Lake",
        "slug": "lonar-crater-lake-buldhana",
        "continent": "Asia",
        "country": "India",
        "state_region": "Maharashtra",
        "city": "Buldhana",
        "place_type": "mountain",
        "latitude": 19.9760,
        "longitude": 76.5064,
    }).json()

    # Upload images
    upload_res = client.post(
        "/api/v1/media/upload",
        files=[
            ("files", _create_mock_image("lake1.jpg")),
            ("files", _create_mock_image("lake2.jpg")),
        ],
        headers=headers
    )
    urls = [item["image_url"] for item in upload_res.json()]

    # Create trip with the 2 uploaded photos
    trip_payload = {
        "title": "Meteor Crater Expedition",
        "start_date": "2026-08-01",
        "end_date": "2026-08-03",
        "places": [
            {
                "location_id": loc["id"],
                "rating": 5,
                "raw_text": "Hyper-velocity impact crater formed 50,000 years ago. Unique saline and alkaline water ecology.",
                "photo_urls": urls
            }
        ]
    }
    trip = client.post("/api/v1/trips", json=trip_payload, headers=headers).json()

    # Check Location Feed contains photos in raw layer
    feed_res = client.get(f"/api/v1/locations/{loc['id']}/feed")
    assert feed_res.status_code == 200
    feed_reviews = feed_res.json()["reviews"]
    assert len(feed_reviews) >= 1
    lonar_review = next(r for r in feed_reviews if r["author"]["username"] == "gallery_explorer")
    assert len(lonar_review["raw_layer"]["photos"]) == 2

    # Check Location Photos Gallery Endpoint
    gallery_res = client.get(f"/api/v1/locations/{loc['id']}/photos")
    assert gallery_res.status_code == 200
    assert len(gallery_res.json()) >= 2
    assert gallery_res.json()[0]["location_name"] == "Lonar Crater Lake"
    assert gallery_res.json()[0]["trip_title"] == "Meteor Crater Expedition"

    # Check Trip Detail contains photos
    trip_detail_res = client.get(f"/api/v1/trips/{trip['id']}")
    assert trip_detail_res.status_code == 200
    place_exp = trip_detail_res.json()["places"][0]["experience"]
    assert len(place_exp["raw_layer"]["photos"]) == 2
