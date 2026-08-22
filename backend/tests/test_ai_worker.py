import pytest
from app.services.ai_extractor import ai_extractor
from app.schemas.ai import AIExtractionResult

def test_anti_hallucination_guardrails():
    # Prompt text with specific highlights, challenges, and cost
    text = "Place mast tha, road kharab thi but view worth it. ₹700 per person laga Mumbai se bike pe."
    result = ai_extractor.extract_review_facts(raw_text=text, currency="INR")

    assert isinstance(result, AIExtractionResult)
    assert result.extracted_budget_per_person == 700.0
    assert "Rough road conditions / poor roads" in result.challenges
    assert "Scenic views" in result.highlights or "High value / must visit experience" in result.highlights
    assert result.sentiment in ["positive", "mixed"]

def test_anti_hallucination_unmentioned_facts():
    # Text mentioning ONLY peaceful nature and sunset. No mention of budget, parking, or food.
    text = "Very peaceful place to watch sunset with friends. Completely quiet atmosphere."
    result = ai_extractor.extract_review_facts(raw_text=text, currency="USD")

    # Anti-hallucination mandate: facts NOT mentioned must be empty lists or None
    assert result.extracted_budget_per_person is None
    assert "Limited or problematic parking" not in result.challenges
    assert "Peaceful and serene atmosphere" in result.highlights or "Spectacular sunset/sunrise" in result.highlights
    assert result.sentiment == "positive"
