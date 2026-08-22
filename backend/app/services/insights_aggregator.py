import logging
from collections import Counter
from typing import Optional
from sqlalchemy.orm import Session
from app.models.review import Review
from app.models.review_ai_data import ReviewAIData
from app.models.location_ai_insights import LocationAIInsights

logger = logging.getLogger("wanderlust.insights_aggregator")

class InsightsAggregatorService:
    def update_location_insights(self, db: Session, location_id: str) -> Optional[LocationAIInsights]:
        """Recalculates aggregated insights for a specific location across all verified reviews."""
        reviews = db.query(Review).filter(Review.location_id == location_id).all()
        if not reviews:
            return None

        # Fetch AI derivatives
        review_ids = [r.id for r in reviews]
        ai_records = db.query(ReviewAIData).filter(
            ReviewAIData.review_id.in_(review_ids),
            ReviewAIData.processing_status == "completed"
        ).all()

        # Collect highlights, challenges, expenses, currencies
        all_highlights = []
        all_challenges = []
        expenses = []
        currencies = []
        visit_months = []

        for r in reviews:
            if r.expense_amount is not None and float(r.expense_amount) > 0:
                expenses.append(float(r.expense_amount))
            if r.currency:
                currencies.append(r.currency)
            if r.visit_date:
                visit_months.append(r.visit_date.strftime("%B"))

        for ai in ai_records:
            if isinstance(ai.highlights, list):
                all_highlights.extend(ai.highlights)
            if isinstance(ai.challenges, list):
                all_challenges.extend(ai.challenges)

        # Compute frequency rankings
        top_highlights = [item for item, _ in Counter(all_highlights).most_common(5)]
        top_challenges = [item for item, _ in Counter(all_challenges).most_common(5)]
        
        # Best visit times (months with most 4+ star visits)
        top_months = [m for m, _ in Counter(visit_months).most_common(3)]
        if not top_months:
            top_months = ["October - March", "Post-Monsoon"]

        # Dominant currency
        dominant_curr = Counter(currencies).most_common(1)[0][0] if currencies else "USD"

        # Expense min/max
        min_exp = min(expenses) if expenses else None
        max_exp = max(expenses) if expenses else None

        # Upsert into LocationAIInsights
        insight = db.query(LocationAIInsights).filter(LocationAIInsights.location_id == location_id).first()
        if not insight:
            insight = LocationAIInsights(
                location_id=location_id,
                aggregated_positives=top_highlights,
                aggregated_challenges=top_challenges,
                expense_range_min=min_exp,
                expense_range_max=max_exp,
                dominant_currency=dominant_curr,
                best_visit_times=top_months,
                sample_size=len(reviews)
            )
            db.add(insight)
        else:
            insight.aggregated_positives = top_highlights
            insight.aggregated_challenges = top_challenges
            insight.expense_range_min = min_exp
            insight.expense_range_max = max_exp
            insight.dominant_currency = dominant_curr
            insight.best_visit_times = top_months
            insight.sample_size = len(reviews)

        db.commit()
        db.refresh(insight)
        logger.info(f"Updated insights for location {location_id} with sample size {len(reviews)}")
        return insight

insights_aggregator = InsightsAggregatorService()
