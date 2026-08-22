import pytest
from datetime import date
from fastapi.testclient import TestClient
from app.services.queue_service import queue_service
from worker import process_review_job

def test_guest_cannot_create_trip(client: TestClient):
    # Unauthenticated attempt to create a trip must fail with 401
    res = client.post("/api/v1/trips", json={
        "title": "Unauthorized Trip",
        "start_date": str(date.today()),
        "end_date": str(date.today()),
        "places": []
    })
    assert res.status_code == 401

def test_guest_cannot_submit_experience(client: TestClient):
    # Unauthenticated attempt to submit review/experience must fail with 401
    res = client.post("/api/v1/reviews", json={
        "location_id": "any-id",
        "rating": 5,
        "original_text": "Unauthorized experience submission",
        "visit_date": str(date.today()),
    })
    assert res.status_code == 401

def test_create_multidestination_trip_and_location_aggregation(client: TestClient):
    # 1. Register User A
    reg_a = client.post("/api/v1/auth/register", json={
        "email": "user_a@trips.com",
        "username": "explorer_a",
        "password": "password123",
        "full_name": "Explorer A"
    })
    token_a = reg_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # 2. Register User B
    reg_b = client.post("/api/v1/auth/register", json={
        "email": "user_b@trips.com",
        "username": "explorer_b",
        "password": "password123",
        "full_name": "Explorer B"
    })
    token_b = reg_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 3. Create Shared Destination: Shirdi
    loc_shirdi = client.post("/api/v1/locations", json={
        "name": "Shirdi Temple",
        "slug": "shirdi-temple-maharashtra",
        "continent": "Asia",
        "country": "India",
        "state_region": "Maharashtra",
        "city": "Shirdi",
        "place_type": "monument",
        "latitude": 19.7645,
        "longitude": 74.4762,
        "description": "Spiritual shrine and temple town in Maharashtra."
    })
    shirdi_id = loc_shirdi.json()["id"]

    # 4. User A Creates Trip 1: "Maharashtra Temple Trip" (Shirdi + Nashik)
    trip_1_payload = {
        "title": "Maharashtra Temple Trip",
        "start_date": "2026-08-10",
        "end_date": "2026-08-13",
        "description": "Peaceful 3-day spiritual pilgrimage across Maharashtra.",
        "total_expense": 4500.0,
        "currency": "INR",
        "transport_mode": "Car / Cab",
        "rating": 5,
        "places": [
            {
                "location_id": shirdi_id,
                "rating": 5,
                "raw_text": "Darshan ke liye approx 2 hours lage. Peaceful darshan early morning, road was great. INR 800 per person.",
                "expense_amount": 800.0,
                "currency": "INR",
                "transport_mode": "Car",
                "tips": "Book VIP pass online if traveling with family.",
                "visit_order": 1
            },
            {
                "new_location_name": "Nashik Panchavati",
                "city": "Nashik",
                "state_region": "Maharashtra",
                "country": "India",
                "place_type": "monument",
                "latitude": 19.9975,
                "longitude": 73.7898,
                "rating": 4,
                "raw_text": "Visited Godavari river ghats and temples. Street food was delicious. INR 400 per person.",
                "expense_amount": 400.0,
                "currency": "INR",
                "visit_order": 2
            }
        ]
    }
    res_trip_1 = client.post("/api/v1/trips", json=trip_1_payload, headers=headers_a)
    assert res_trip_1.status_code == 201
    trip_1_data = res_trip_1.json()
    assert trip_1_data["title"] == "Maharashtra Temple Trip"
    assert trip_1_data["places_count"] == 2
    assert len(trip_1_data["places"]) == 2
    assert trip_1_data["places"][0]["experience"]["trip_title"] == "Maharashtra Temple Trip"

    # 5. User B Creates Trip 2: "Shirdi Weekend Trip" (Visiting Shirdi as well)
    trip_2_payload = {
        "title": "Shirdi Weekend Trip",
        "start_date": "2026-08-15",
        "end_date": "2026-08-16",
        "description": "Quick weekend road trip on motorcycle.",
        "total_expense": 1800.0,
        "currency": "INR",
        "transport_mode": "Motorcycle",
        "rating": 5,
        "places": [
            {
                "location_id": shirdi_id,
                "rating": 4,
                "raw_text": "Heavy rush in evening, but night aarti was surreal. INR 600 per person.",
                "expense_amount": 600.0,
                "currency": "INR",
                "transport_mode": "Motorcycle",
                "visit_order": 1
            }
        ]
    }
    res_trip_2 = client.post("/api/v1/trips", json=trip_2_payload, headers=headers_b)
    assert res_trip_2.status_code == 201

    # 6. Process enqueued AI jobs for both trip experiences in Worker
    while True:
        job = queue_service.dequeue_review_job(timeout=1)
        if not job:
            break
        process_review_job(job)

    # 7. LOCATION AGGREGATION PROOF: Shirdi feed aggregates experiences from BOTH Trip 1 and Trip 2!
    shirdi_feed_res = client.get(f"/api/v1/locations/{shirdi_id}/feed")
    assert shirdi_feed_res.status_code == 200
    feed = shirdi_feed_res.json()

    assert feed["total_reviews"] == 2
    reviews = feed["reviews"]
    
    authors = [r["author"]["username"] for r in reviews]
    trip_titles = [r["trip_title"] for r in reviews]

    assert "explorer_a" in authors
    assert "explorer_b" in authors
    assert "Maharashtra Temple Trip" in trip_titles
    assert "Shirdi Weekend Trip" in trip_titles

    # 8. RAW EXPERIENCE IMMUTABILITY PROOF:
    review_a = next(r for r in reviews if r["author"]["username"] == "explorer_a")
    assert "Darshan ke liye approx 2 hours lage" in review_a["raw_layer"]["original_text"]
    assert review_a["ai_layer"]["processing_status"] == "completed"
    assert review_a["raw_layer"]["expense_amount"] == 800.0

    # 9. GET /trips and GET /trips/{id}
    trips_list_res = client.get("/api/v1/trips")
    assert trips_list_res.status_code == 200
    assert len(trips_list_res.json()) >= 2

    trip_detail_res = client.get(f"/api/v1/trips/{trip_1_data['id']}")
    assert trip_detail_res.status_code == 200
    assert trip_detail_res.json()["title"] == "Maharashtra Temple Trip"
