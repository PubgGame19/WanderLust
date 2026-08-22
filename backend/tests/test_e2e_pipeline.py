from datetime import date
from fastapi.testclient import TestClient
from app.services.queue_service import queue_service
from worker import process_review_job

def test_full_pipeline_ingest_async_ai_and_insights(client: TestClient):
    # 1. Register user
    reg = client.post("/api/v1/auth/register", json={
        "email": "pipeline_e2e@test.com",
        "username": "trail_blazer_e2e",
        "password": "password123"
    })
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create Location
    loc = client.post("/api/v1/locations", json={
        "name": "Sinhagad Fort",
        "slug": "sinhagad-fort-pune-e2e",
        "continent": "Asia",
        "country": "India",
        "state_region": "Maharashtra",
        "city": "Pune",
        "place_type": "fort",
        "latitude": 18.3663,
        "longitude": 73.7559,
        "description": "Historic hill fortress near Pune with scenic views and kanda bhaji."
    })
    location_id = loc.json()["id"]

    # 3. Submit Review (Immediate 201 Created & Enqueued)
    review_res = client.post("/api/v1/reviews", json={
        "location_id": location_id,
        "rating": 5,
        "original_text": "Place mast tha, road kharab thi but view worth it. ₹700 per person laga Mumbai se bike pe.",
        "visit_date": str(date.today()),
        "expense_amount": 700.0,
        "currency": "INR",
        "group_size": 2,
        "transport_mode": "Motorcycle"
    }, headers=headers)
    assert review_res.status_code == 201
    rev_data = review_res.json()
    review_id = rev_data["review_id"]
    assert rev_data["ai_status"] == "pending"

    # 4. Dequeue and Process in Worker
    job = queue_service.dequeue_review_job(timeout=1)
    assert job is not None
    assert job["review_id"] == review_id
    process_review_job(job)

    # 5. Verify Location Feed now contains Completed AI Layer and Aggregated Insights
    feed_res = client.get(f"/api/v1/locations/{location_id}/feed")
    assert feed_res.status_code == 200
    feed = feed_res.json()
    
    assert feed["total_reviews"] == 1
    rev_feed_item = feed["reviews"][0]
    assert rev_feed_item["ai_layer"]["processing_status"] == "completed"
    assert "Rough road conditions / poor roads" in rev_feed_item["ai_layer"]["challenges"]
    assert rev_feed_item["ai_layer"]["extracted_budget_per_person"] == 700.0

    # Verify Location AI Insights Aggregation
    insights = feed["insights"]
    assert insights is not None
    assert insights["sample_size"] == 1
    assert "Rough road conditions / poor roads" in insights["aggregated_challenges"]
    assert insights["expense_range_min"] == 700.0
    assert insights["dominant_currency"] == "INR"

    # 6. Verify RAG Assistant Answers Query using Grounded Community Data
    rag_res = client.post("/api/v1/ai/assistant/query", json={
        "query": "Sinhagad fort bike trip budget",
        "latitude": 18.5204,
        "longitude": 73.8567,
        "budget_max": 1000.0,
        "currency": "INR"
    })
    assert rag_res.status_code == 200
    rag_data = rag_res.json()
    assert len(rag_data["recommended_locations"]) >= 1
    assert any(l["name"] == "Sinhagad Fort" for l in rag_data["recommended_locations"])
    assert len(rag_data["citations"]) >= 1
    assert any(c["author_username"] == "trail_blazer_e2e" for c in rag_data["citations"])
