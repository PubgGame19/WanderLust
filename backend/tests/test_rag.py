import pytest
from app.models.user import User
from app.models.location import Location
from app.models.review import Review
from app.models.review_ai_data import ReviewAIData
from app.schemas.ai import AIAssistantQueryRequest
from app.services.rag_service import rag_assistant
from tests.conftest import TestingSessionLocal

@pytest.fixture
def setup_rag_data():
    db = TestingSessionLocal()
    user = User(
        id="u-rag-1",
        email="wander_rag@test.com",
        username="mumbai_trekker_rag",
        password_hash="fakehash"
    )
    db.add(user)

    loc = Location(
        id="l-rag-1",
        name="Harishchandragad",
        slug="harishchandragad-fort-rag",
        continent="Asia",
        country="India",
        state_region="Maharashtra",
        city="Ahmednagar",
        place_type="fort",
        latitude=19.3850,
        longitude=73.7770,
        description="Ancient hill fort known for Kokankada cliff."
    )
    db.add(loc)

    rev = Review(
        id="r-rag-1",
        user_id="u-rag-1",
        location_id="l-rag-1",
        rating=5,
        original_text="Spectacular cliff view from Kokankada! ₹900 budget per person.",
        expense_amount=900.0,
        currency="INR"
    )
    db.add(rev)

    ai = ReviewAIData(
        id="ai-rag-1",
        review_id="r-rag-1",
        ai_summary="Kokankada cliff offers spectacular panoramic views on a budget.",
        highlights=["Scenic views", "High value"],
        challenges=[],
        extracted_tips=[],
        sentiment="positive",
        extracted_budget_per_person=900.0,
        model_version="wanderlust-gemini-pro-v1",
        processing_status="completed"
    )
    db.add(ai)

    db.commit()
    yield db
    db.close()

def test_rag_assistant_hybrid_search_and_citations(setup_rag_data):
    db = setup_rag_data
    req = AIAssistantQueryRequest(
        query="scenic fort trek with cliff views",
        budget_max=1500.0,
        currency="INR",
        latitude=19.0760, # Mumbai coordinates
        longitude=72.8777
    )

    response = rag_assistant.answer_query(db=db, req=req)

    assert response.query == req.query
    assert len(response.recommended_locations) >= 1
    assert any(l.name == "Harishchandragad" for l in response.recommended_locations)
    assert len(response.citations) >= 1
    assert any(c.author_username == "mumbai_trekker_rag" for c in response.citations)
    assert "Harishchandragad" in response.answer
