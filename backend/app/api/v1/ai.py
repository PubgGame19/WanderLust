from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.ai import AIAssistantQueryRequest, AIAssistantResponse
from app.services.rag_service import rag_assistant

router = APIRouter(prefix="/ai", tags=["AI Travel Assistant"])

@router.post("/assistant/query", response_model=AIAssistantResponse)
def query_travel_assistant(
    request: AIAssistantQueryRequest,
    db: Session = Depends(get_db)
):
    """
    RAG Travel Assistant:
    1. Hybrid search on destinations (distance, category, budget constraints).
    2. Vector & text similarity retrieval on community reviews.
    3. Generates grounded advice citing verified traveler submissions.
    """
    try:
        response = rag_assistant.answer_query(db=db, req=request)
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate travel advice: {str(e)}")
