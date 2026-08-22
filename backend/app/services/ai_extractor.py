import json
import logging
import re
from typing import Dict, Any, Optional
from app.core.config import settings
from app.schemas.ai import AIExtractionResult

logger = logging.getLogger("wanderlust.ai_extractor")

SYSTEM_PROMPT = (
    "You are a travel data extraction engine. Extract facts ONLY if explicitly mentioned in raw text. "
    "Do NOT fabricate numbers, safety remarks, or parking facts. If not mentioned, return empty lists or null.\n"
    "You must return ONLY a strict JSON object matching this schema:\n"
    "{\n"
    '  "summary": "String",\n'
    '  "highlights": ["String"],\n'
    '  "challenges": ["String"],\n'
    '  "extracted_tips": ["String"],\n'
    '  "sentiment": "positive | mixed | negative | neutral",\n'
    '  "extracted_budget_per_person": number or null\n'
    "}"
)

class AIExtractorService:
    def __init__(self):
        self.model_version = settings.AI_MODEL_VERSION

    def extract_review_facts(self, raw_text: str, currency: str = "USD") -> AIExtractionResult:
        """Extracts structured facts from raw review text with strict anti-hallucination guardrails."""
        if not raw_text or not raw_text.strip():
            return AIExtractionResult(
                summary="No text provided.",
                highlights=[],
                challenges=[],
                extracted_tips=[],
                sentiment="neutral",
                extracted_budget_per_person=None
            )

        # 1. Attempt Gemini API if configured
        gemini_key = settings.GEMINI_API_KEY.strip() if settings.GEMINI_API_KEY else ""
        if gemini_key and not gemini_key.startswith("YOUR_") and gemini_key != "mock_key":
            try:
                result = self._call_gemini(raw_text, currency)
                if result:
                    return result
            except Exception as e:
                logger.warning(f"Gemini API extraction failed ({e}). Falling back.")

        # 2. Attempt OpenAI API if configured
        openai_key = settings.OPENAI_API_KEY.strip() if settings.OPENAI_API_KEY else ""
        if openai_key and not openai_key.startswith("YOUR_") and openai_key != "mock_key":
            try:
                result = self._call_openai(raw_text, currency)
                if result:
                    return result
            except Exception as e:
                logger.warning(f"OpenAI API extraction failed ({e}). Falling back.")

        # 3. Deterministic NLP / Rule-Based Extractor (Zero hallucination fallback)
        return self._rule_based_fallback(raw_text, currency)

    def _call_gemini(self, raw_text: str, currency: str) -> Optional[AIExtractionResult]:
        from google import genai
        client = genai.Client(api_key=settings.GEMINI_API_KEY)
        prompt = f"{SYSTEM_PROMPT}\n\nReview Text:\n\"\"\"{raw_text}\"\"\"\nCurrency hint: {currency}"
        
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config={
                'response_mime_type': 'application/json',
                'response_schema': AIExtractionResult,
            }
        )
        if response.text:
            data = json.loads(response.text)
            return AIExtractionResult(**data)
        return None

    def _call_openai(self, raw_text: str, currency: str) -> Optional[AIExtractionResult]:
        from openai import OpenAI
        client = OpenAI(api_key=settings.OPENAI_API_KEY)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"Review Text:\n\"\"\"{raw_text}\"\"\"\nCurrency hint: {currency}"}
            ],
            temperature=0.1
        )
        content = response.choices[0].message.content
        if content:
            data = json.loads(content)
            return AIExtractionResult(**data)
        return None

    def _rule_based_fallback(self, raw_text: str, currency: str) -> AIExtractionResult:
        """Deterministic, strictly grounded fallback extractor that never hallucinates facts."""
        text_lower = raw_text.lower()
        
        # 1. Budget extraction via regex
        budget_match = re.search(r'(?:₹|rs\.?|inr|\$|usd|eur|€)?\s*(\d+(?:,\d+)*(?:\.\d+)?)\s*(?:per\s+person|\/person|per\s+head|\/head|each|kharcha|laga)', text_lower)
        extracted_budget = None
        if budget_match:
            try:
                extracted_budget = float(budget_match.group(1).replace(',', ''))
            except ValueError:
                pass
        if extracted_budget is None:
            # Check for general amount mentioned with currency symbol
            amt_match = re.search(r'(?:₹|rs\.?|inr|\$|usd|eur|€)\s*(\d+(?:,\d+)*(?:\.\d+)?)', text_lower)
            if amt_match:
                try:
                    extracted_budget = float(amt_match.group(1).replace(',', ''))
                except ValueError:
                    pass

        # 2. Positive highlights grounded in text
        highlights = []
        positive_patterns = [
            (r'(?:view|scenery|nazaara|views?)\s*(?:is|was|worth|mast|awesome|great|breathtaking|beautiful|khoobsurat)', "Scenic views"),
            (r'(?:worth\s+it|paisa\s+vasool|must\s+visit)', "High value / must visit experience"),
            (r'(?:good|great|mast|delicious|fresh)\s*(?:food|chai|maggi|snacks|breakfast|cafe)', "Good local food/refreshments"),
            (r'(?:peaceful|calm|serene|tranquil|sukoon|quiet)', "Peaceful and serene atmosphere"),
            (r'(?:clean|hygienic|well\s+maintained|neat)', "Clean and well maintained"),
            (r'(?:sunset|sunrise)\s*(?:point|view|was|mast)', "Spectacular sunset/sunrise"),
            (r'(?:budget|cheap|affordable|sasta)', "Budget-friendly experience"),
        ]
        for pattern, label in positive_patterns:
            if re.search(pattern, text_lower):
                if label not in highlights:
                    highlights.append(label)

        # 3. Challenges and alerts grounded in text
        challenges = []
        challenge_patterns = [
            (r'(?:road|roads|rasta)\s*(?:kharab|bad|rough|bumpy|broken|potholes|under\s+construction)', "Rough road conditions / poor roads"),
            (r'(?:crowd|crowded|bheed|rush|lines?|waiting)', "Heavy crowds / long waiting times"),
            (r'(?:parking\s+(?:issue|problem|kharab|full|no\s+parking|naahi))', "Limited or problematic parking"),
            (r'(?:expensive|costly|pricey|mehnga|overpriced)', "High expenses / overpriced commodities"),
            (r'(?:steep|climb|trek|exhausting|slippery|chadhai)', "Steep climb or physically demanding trek"),
            (r'(?:network|signal|no\s+network|connectivity)', "Poor mobile network coverage"),
            (r'(?:heat|hot|rain|heavy\s+rain|fog|cold|chilly)', "Challenging weather conditions"),
        ]
        for pattern, label in challenge_patterns:
            if re.search(pattern, text_lower):
                if label not in challenges:
                    challenges.append(label)

        # 4. Extracted concrete tips
        extracted_tips = []
        tip_patterns = [
            (r'(?:go\s+early|subah\s+jaldi|early\s+morning|reach\s+before)', "Visit early morning to avoid rush"),
            (r'(?:bike|motorcycle|scooter|two\s+wheeler)', "Recommended / doable via two-wheeler"),
            (r'(?:carry\s+water|water\s+bottle|pani|snacks)', "Carry your own water and energy snacks"),
            (r'(?:shoes|trekking\s+shoes|grip)', "Wear proper shoes with good grip"),
            (r'(?:cash|atm|cash\s+carry)', "Carry physical cash as digital payments may fail"),
        ]
        for pattern, label in tip_patterns:
            if re.search(pattern, text_lower):
                if label not in extracted_tips:
                    extracted_tips.append(label)

        # 5. Sentiment derivation
        if len(highlights) > len(challenges) and ("bad" not in text_lower and "worst" not in text_lower):
            sentiment = "positive"
        elif len(challenges) > len(highlights):
            sentiment = "negative"
        elif len(highlights) > 0 and len(challenges) > 0:
            sentiment = "mixed"
        else:
            sentiment = "positive" if any(w in text_lower for w in ["good", "mast", "great", "nice", "worth", "beautiful", "love"]) else "neutral"

        # 6. Grounded Summary
        summary_sentences = [s.strip() for s in re.split(r'[.!?\n]+', raw_text) if len(s.strip()) > 3]
        if summary_sentences:
            summary = summary_sentences[0]
            if len(summary) > 150:
                summary = summary[:147] + "..."
        else:
            summary = "Direct traveler review recorded."

        return AIExtractionResult(
            summary=summary,
            highlights=highlights,
            challenges=challenges,
            extracted_tips=extracted_tips,
            sentiment=sentiment,
            extracted_budget_per_person=extracted_budget
        )

ai_extractor = AIExtractorService()
