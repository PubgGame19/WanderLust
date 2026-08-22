import json
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.config import settings
from app.core.database import calculate_haversine_distance_km
from app.models.location import Location
from app.models.review import Review
from app.models.review_ai_data import ReviewAIData
from app.schemas.location import LocationOut
from app.schemas.ai import AIAssistantQueryRequest, AIAssistantCitation, AIAssistantResponse

logger = logging.getLogger("wanderlust.rag_service")

GEMINI_MODEL = "gemini-2.0-flash"  # Correct model name

class RAGTravelAssistantService:
    def answer_query(self, db: Session, req: AIAssistantQueryRequest) -> AIAssistantResponse:
        """Performs hybrid retrieval and generates grounded travel advice with explicit community citations."""
        query_text = req.query.lower()
        
        try:
            # 1. Fetch Candidate Locations
            all_locations = db.query(Location).all()
        except Exception as e:
            logger.error("Failed to query locations in RAG assistant: %s", e)
            all_locations = []

        scored_locations = []

        for loc in all_locations:
            score = 0
            # Distance scoring if user coordinates provided
            dist_km = None
            if req.latitude is not None and req.longitude is not None:
                try:
                    dist_km = calculate_haversine_distance_km(
                        req.latitude, req.longitude,
                        float(loc.latitude), float(loc.longitude)
                    )
                    if dist_km < 300:
                        score += 3
                    elif dist_km < 800:
                        score += 1
                except Exception:
                    dist_km = None

            # Keyword relevance in name, city, state, country, description, place_type + ground truth reviews
            loc_name_lower = loc.name.lower()
            loc_text = f"{loc_name_lower} {loc.city or ''} {loc.state_region or ''} {loc.country} {loc.place_type or ''} {loc.description or ''}".lower()
            
            try:
                review_texts = " ".join([r.original_text.lower() for r in loc.reviews]) if loc.reviews else ""
            except Exception:
                review_texts = ""

            full_search_text = f"{loc_text} {review_texts}"
            keywords = [kw.strip() for kw in query_text.split() if len(kw.strip()) > 2]
            
            # Exact word matches in name get highest weight
            for kw in keywords:
                if kw in loc_name_lower:
                    score += 15
                elif kw in loc_text:
                    score += 6
                elif kw in review_texts:
                    score += 4

            # Place type filter match
            if req.place_type and loc.place_type and req.place_type.lower() in loc.place_type.lower():
                score += 8

            # Budget check if insights exist
            try:
                if loc.ai_insights and req.budget_max is not None:
                    if loc.ai_insights.expense_range_min is not None:
                        if float(loc.ai_insights.expense_range_min) <= req.budget_max:
                            score += 4
                        else:
                            score -= 2
            except Exception:
                pass

            scored_locations.append((score, dist_km, loc))

        # Sort by score descending
        scored_locations.sort(key=lambda x: x[0], reverse=True)
        top_destinations = [item[2] for item in scored_locations[:3]] if scored_locations else []
        
        if not top_destinations and all_locations:
            top_destinations = all_locations[:2]

        # 2. Gather Grounded Community Review Citations
        citations: List[AIAssistantCitation] = []
        context_snippets: List[str] = []
        loc_outputs: List[LocationOut] = []

        for loc in top_destinations:
            # Format location output
            dist = None
            if req.latitude is not None and req.longitude is not None:
                try:
                    dist = calculate_haversine_distance_km(
                        req.latitude, req.longitude,
                        float(loc.latitude), float(loc.longitude)
                    )
                except Exception:
                    dist = None
            
            # Review stats - Safely querying reviews with fallback
            revs: List[Review] = []
            try:
                revs = db.query(Review).filter(Review.location_id == loc.id).all()
            except Exception as r_err:
                logger.warning("Could not query reviews for location %s: %s", loc.id, r_err)
                revs = []

            avg_rating = round(sum(r.rating for r in revs if r.rating is not None) / len(revs), 1) if revs else None
            
            loc_out = LocationOut(
                id=loc.id,
                name=loc.name,
                slug=loc.slug,
                continent=loc.continent,
                country=loc.country,
                state_region=loc.state_region,
                city=loc.city,
                place_type=loc.place_type,
                latitude=float(loc.latitude),
                longitude=float(loc.longitude),
                cover_image_url=loc.cover_image_url,
                description=loc.description,
                verified=loc.verified,
                created_at=loc.created_at,
                distance_km=dist,
                average_rating=avg_rating,
                review_count=len(revs)
            )
            loc_outputs.append(loc_out)

            # Pick top 2 reviews for citations with safe attribute access
            for r in revs[:2]:
                try:
                    author_name = "Verified Traveler"
                    if hasattr(r, 'user') and r.user and hasattr(r.user, 'username'):
                        author_name = r.user.username
                    
                    quote = r.original_text or "Great destination to explore."
                    if len(quote) > 120:
                        quote = quote[:117] + "..."
                    
                    citation = AIAssistantCitation(
                        location_name=loc.name,
                        location_id=loc.id,
                        review_id=r.id,
                        author_username=author_name,
                        quote_snippet=quote,
                        rating=r.rating if r.rating else 5
                    )
                    citations.append(citation)
                    spent_str = f"{r.currency} {r.expense_amount}" if (hasattr(r, 'currency') and r.currency and hasattr(r, 'expense_amount') and r.expense_amount) else "N/A"
                    transport_str = r.transport_mode if (hasattr(r, 'transport_mode') and r.transport_mode) else "N/A"
                    context_snippets.append(
                        f"- [{loc.name}] {author_name} (Rating: {r.rating or 5}/5, Spent: {spent_str}, Transport: {transport_str}): \"{r.original_text}\""
                    )
                except Exception as cit_err:
                    logger.warning("Error processing review citation: %s", cit_err)

        # 3. Generate Grounded AI Response
        answer_text = self._generate_grounded_answer(
            req.query, loc_outputs, context_snippets, req.budget_max, req.currency,
            chat_history=getattr(req, 'chat_history', None)
        )

        return AIAssistantResponse(
            query=req.query,
            answer=answer_text,
            recommended_locations=loc_outputs,
            citations=citations,
            generated_at=datetime.now(timezone.utc).isoformat()
        )

    def _generate_grounded_answer(
        self,
        query: str,
        locations: List[LocationOut],
        context_snippets: List[str],
        budget_max: Optional[float],
        currency: Optional[str],
        chat_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """Creates grounded advice citing real reviews with multi-turn chat history support."""
        if not locations:
            return f"I couldn't find any specific destinations in the database matching '{query}'. Try searching for popular scenic destinations, mountain treks, or coastal retreats!"

        # 1. If Gemini API is available, generate dynamic grounded text
        gemini_key = settings.GEMINI_API_KEY.strip() if settings.GEMINI_API_KEY else ""
        if gemini_key and not gemini_key.startswith("YOUR_") and gemini_key != "mock_key":
            try:
                from google import genai
                from google.genai import types
                client = genai.Client(api_key=gemini_key)

                system_instruction = (
                    "You are the Wanderlust AI Travel Assistant — a friendly, expert travel copilot. "
                    "Answer travel queries using ONLY the provided community review context. "
                    "Cite traveler observations, budgets, and road conditions directly. "
                    "Never fabricate facts not present in the snippets. "
                    "Be concise, warm, and use emojis where appropriate for readability."
                )

                # Build multi-turn conversation contents
                contents = []

                # Add prior chat history turns
                if chat_history:
                    for turn in chat_history:
                        role = turn.get("role", "user")
                        text = turn.get("text", "")
                        if text:
                            contents.append(types.Content(
                                role="user" if role == "user" else "model",
                                parts=[types.Part(text=text)]
                            ))

                # Add current user turn with RAG context
                current_turn = (
                    f"User Query: {query}\n"
                    f"Max Budget: {currency or 'INR'} {budget_max if budget_max else 'Any'}\n\n"
                    f"Community Review Context (ground your answer ONLY in this):\n"
                    + "\n".join(context_snippets)
                )
                contents.append(types.Content(
                    role="user",
                    parts=[types.Part(text=current_turn)]
                ))

                for model_name in ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-2.5-flash"]:
                    try:
                        response = client.models.generate_content(
                            model=model_name,
                            contents=contents,
                            config=types.GenerateContentConfig(
                                system_instruction=system_instruction,
                                temperature=0.3,
                                max_output_tokens=1024,
                            ),
                        )
                        if response.text:
                            return response.text.strip()
                    except Exception as model_err:
                        logger.debug("Gemini model %s attempt: %s", model_name, model_err)
            except Exception as e:
                logger.warning(f"Gemini LLM Generation for RAG query failed: {e}")

        # 2. If OpenAI API is available, generate dynamic grounded text
        openai_key = settings.OPENAI_API_KEY.strip() if settings.OPENAI_API_KEY else ""
        if openai_key and not openai_key.startswith("YOUR_") and openai_key != "mock_key":
            try:
                import openai
                client = openai.OpenAI(api_key=openai_key)
                prompt = (
                    "You are the Wanderlust AI Travel Assistant. Answer the user's travel query using ONLY "
                    "the provided community review context. Cite traveler observations, budgets, and road conditions directly. "
                    "Never fabricate facts not present in the snippets.\n\n"
                    f"User Query: {query}\n"
                    f"Max Budget: {currency or 'INR'} {budget_max if budget_max else 'Any'}\n\n"
                    f"Community Experience Context:\n" + "\n".join(context_snippets)
                )
                messages = [
                    {"role": "system", "content": "You are Wanderlust AI travel assistant. Only use provided context."}
                ]
                if chat_history:
                    for turn in chat_history:
                        messages.append({
                            "role": "user" if turn.get("role") == "user" else "assistant",
                            "content": turn.get("text", "")
                        })
                messages.append({"role": "user", "content": prompt})

                completion = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=messages,
                    temperature=0.2
                )
                if completion.choices and completion.choices[0].message.content:
                    return completion.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"OpenAI LLM Generation for RAG query failed: {e}")

        # Deterministic Structured Grounded Template
        answer_parts = [
            f"Based on real traveler community reviews, here are top recommendations for **\"{query}\"**:\n"
        ]
        
        for loc in locations:
            answer_parts.append(f"### 📍 {loc.name} ({loc.city or loc.state_region}, {loc.country})")
            if loc.average_rating:
                answer_parts.append(f"⭐ **Rating:** {loc.average_rating}/5.0 from verified community visits.")
            if loc.distance_km:
                answer_parts.append(f"🚗 **Distance:** ~{loc.distance_km} km from your specified coordinates.")
            if loc.description:
                answer_parts.append(f"_{loc.description}_")
            answer_parts.append("")

        if context_snippets:
            answer_parts.append("#### 🗣️ Key Verified Traveler Insights:")
            for snippet in context_snippets[:4]:
                answer_parts.append(snippet)

        if budget_max:
            answer_parts.append(f"\n💡 *Budget note:* Evaluated against your target budget of {currency or 'USD'} {budget_max:,.2f}.")

        return "\n".join(answer_parts)

rag_assistant = RAGTravelAssistantService()
