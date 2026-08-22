from datetime import date
from fastapi.testclient import TestClient

def test_user_registration_and_login(client: TestClient):
    # 1. Register
    reg_payload = {
        "email": "traveler_api@test.com",
        "username": "wanderer_sam_api",
        "password": "password123",
        "full_name": "Sam Explorer"
    }
    res = client.post("/api/v1/auth/register", json=reg_payload)
    assert res.status_code == 201
    data = res.json()
    assert "access_token" in data
    assert data["user"]["username"] == "wanderer_sam_api"

    # 2. Login
    login_payload = {
        "email_or_username": "wanderer_sam_api",
        "password": "password123"
    }
    res_login = client.post("/api/v1/auth/login", json=login_payload)
    assert res_login.status_code == 200
    token = res_login.json()["access_token"]

    # 3. Profile
    res_me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res_me.status_code == 200
    assert res_me.json()["email"] == "traveler_api@test.com"

def test_google_oauth_registration_and_login(client: TestClient):
    # 1. First Google Auth (creates new user)
    google_payload = {
        "id_token": "mock_google_id_token_unique_1"
    }
    res = client.post("/api/v1/auth/google", json=google_payload)
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["user"]["email"] == "google_user@wanderlust.ai"

    token = data["access_token"]
    res_me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res_me.status_code == 200
    assert res_me.json()["email"] == "google_user@wanderlust.ai"

    # 2. Subsequent Google Auth (logs in existing user)
    res_login = client.post("/api/v1/auth/google", json=google_payload)
    assert res_login.status_code == 200
    data_login = res_login.json()
    assert data_login["user"]["email"] == "google_user@wanderlust.ai"

def test_unauthenticated_write_access_rejected(client: TestClient):
    # Unauthenticated attempt to submit review must fail with 401 Unauthorized
    res = client.post("/api/v1/reviews", json={
        "location_id": "test-location-id",
        "rating": 5,
        "original_text": "Unauthenticated user attempting review",
        "visit_date": str(date.today()),
    })
    assert res.status_code == 401

def test_public_read_endpoints_allowed_for_guests(client: TestClient):
    # Locations list is public
    locs_res = client.get("/api/v1/locations")
    assert locs_res.status_code == 200

    # AI chatbot is public
    ai_res = client.post("/api/v1/ai/assistant/query", json={
        "query": "Best beach destinations",
        "budget_max": 2000.0,
    })
    assert ai_res.status_code == 200

def test_strict_spatial_normalization_and_review_submission(client: TestClient):
    # 1. Register user
    reg = client.post("/api/v1/auth/register", json={
        "email": "reviewer_norm@test.com",
        "username": "mountain_rider_norm",
        "password": "password123"
    })
    token = reg.json()["access_token"]
    auth_headers = {"Authorization": f"Bearer {token}"}

    # 2. Create Location
    loc_payload = {
        "name": "Kalsubai Peak",
        "slug": "kalsubai-peak-highest-point-maharashtra",
        "continent": "Asia",
        "country": "India",
        "state_region": "Maharashtra",
        "city": "Bhandardara",
        "place_type": "mountain",
        "latitude": 19.6010,
        "longitude": 73.7077,
        "description": "Highest peak in Maharashtra with scenic monsoon trails."
    }
    res_loc = client.post("/api/v1/locations", json=loc_payload)
    assert res_loc.status_code == 201
    location_id = res_loc.json()["id"]

    # 3. Invariant: Review submission to invalid location fails with 404 (FK constraint)
    invalid_review_payload = {
        "location_id": "non-existent-uuid-12345",
        "rating": 5,
        "original_text": "Great place!",
        "visit_date": str(date.today()),
        "expense_amount": 500.0,
        "currency": "INR"
    }
    res_invalid = client.post("/api/v1/reviews", json=invalid_review_payload, headers=auth_headers)
    assert res_invalid.status_code == 404

    # 4. Valid Review Submission: Returns 201 Created and ai_status: 'pending' immediately
    valid_review_payload = {
        "location_id": location_id,
        "rating": 5,
        "original_text": "Place mast tha, road kharab thi but view worth it. ₹700 per person laga Mumbai se bike pe.",
        "visit_date": str(date.today()),
        "expense_amount": 700.0,
        "currency": "INR",
        "group_size": 4,
        "transport_mode": "Motorcycle",
        "starting_location": "Mumbai",
        "photo_urls": ["https://images.unsplash.com/photo-1?w=800"]
    }
    res_review = client.post("/api/v1/reviews", json=valid_review_payload, headers=auth_headers)
    assert res_review.status_code == 201
    review_data = res_review.json()
    assert review_data["ai_status"] == "pending"
    assert review_data["location_id"] == location_id
    assert "review_id" in review_data

    # 5. Fetch Location Feed with 2-Layer Structure
    res_feed = client.get(f"/api/v1/locations/{location_id}/feed")
    assert res_feed.status_code == 200
    feed = res_feed.json()
    assert feed["location"]["name"] == "Kalsubai Peak"
    assert feed["total_reviews"] >= 1
    review_item = feed["reviews"][0]
    
    # Assert 2-Layer schema
    assert "ai_layer" in review_item
    assert "raw_layer" in review_item
    assert review_item["raw_layer"]["original_text"] == valid_review_payload["original_text"]
    assert review_item["raw_layer"]["expense_amount"] == 700.0
    assert review_item["raw_layer"]["currency"] == "INR"
    assert review_item["author"]["username"] == "mountain_rider_norm"

def test_location_autocomplete_country_and_currency(client: TestClient):
    # 1. Create test locations with different countries
    client.post("/api/v1/locations", json={
        "name": "Spiti Valley & Key Monastery",
        "slug": "spiti-valley-key-monastery-test",
        "continent": "Asia",
        "country": "India",
        "state_region": "Himachal Pradesh",
        "city": "Kaza",
        "place_type": "mountain",
        "latitude": 32.2996,
        "longitude": 78.0068,
    })
    client.post("/api/v1/locations", json={
        "name": "Shibuya Crossing",
        "slug": "shibuya-crossing-tokyo-test",
        "continent": "Asia",
        "country": "Japan",
        "state_region": "Tokyo",
        "city": "Tokyo",
        "place_type": "monument",
        "latitude": 35.6595,
        "longitude": 139.7004,
    })

    # 2. Query prefix / substring for India location -> INR
    res_india = client.get("/api/v1/locations/autocomplete?q=spiti")
    assert res_india.status_code == 200
    data_india = res_india.json()
    assert len(data_india) >= 1
    item_in = data_india[0]
    assert "Spiti Valley" in item_in["name"]
    assert item_in["country"] == "India"
    assert item_in["dominant_currency"] == "INR"
    assert "India (INR)" in item_in["display_label"]

    # 3. Query prefix / substring for Japan location -> JPY
    res_jp = client.get("/api/v1/locations/autocomplete?q=shibuya")
    assert res_jp.status_code == 200
    data_jp = res_jp.json()
    assert len(data_jp) >= 1
    item_jp = data_jp[0]
    assert "Shibuya Crossing" in item_jp["name"]
    assert item_jp["country"] == "Japan"
    assert item_jp["dominant_currency"] == "JPY"
    assert "Japan (JPY)" in item_jp["display_label"]

    # 4. Empty query returns locations with dominant currency and display label
    res_all = client.get("/api/v1/locations/autocomplete?limit=10")
    assert res_all.status_code == 200
    assert len(res_all.json()) >= 2
    for loc in res_all.json():
        assert "dominant_currency" in loc
        assert "display_label" in loc
        assert loc["dominant_currency"] in ["INR", "USD", "EUR", "JPY", "GBP"]
