import time
import logging
import signal
import sys
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import SessionLocal, init_db
from app.models.review import Review
from app.models.review_ai_data import ReviewAIData
from app.services.queue_service import queue_service
from app.services.ai_extractor import ai_extractor
from app.services.insights_aggregator import insights_aggregator

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [AI-Worker]: %(message)s"
)
logger = logging.getLogger("wanderlust.worker")

RUNNING = True

def handle_shutdown(signum, frame):
    global RUNNING
    logger.info("Shutdown signal received. Finishing current job and stopping worker...")
    RUNNING = False

signal.signal(signal.SIGINT, handle_shutdown)
signal.signal(signal.SIGTERM, handle_shutdown)

def process_review_job(job_data: dict):
    """Processes a single review AI extraction and updates community aggregated insights."""
    review_id = job_data.get("review_id")
    location_id = job_data.get("location_id")
    text = job_data.get("text", "")
    currency = job_data.get("currency", "USD")

    logger.info(f"Processing AI extraction for review {review_id} (location {location_id})...")
    
    db: Session = SessionLocal()
    try:
        review = db.query(Review).filter(Review.id == review_id).first()
        if not review:
            logger.error(f"Review {review_id} not found in database.")
            return

        # 1. Run Strict Anti-Hallucination AI Extraction
        extraction_result = ai_extractor.extract_review_facts(raw_text=text, currency=currency)

        # 2. Upsert Versioned AI Review Derivative
        existing_ai_data = db.query(ReviewAIData).filter(ReviewAIData.review_id == review_id).first()
        if not existing_ai_data:
            ai_data = ReviewAIData(
                review_id=review_id,
                ai_summary=extraction_result.summary,
                highlights=extraction_result.highlights,
                challenges=extraction_result.challenges,
                extracted_tips=extraction_result.extracted_tips,
                sentiment=extraction_result.sentiment,
                extracted_budget_per_person=extraction_result.extracted_budget_per_person,
                model_version=settings.AI_MODEL_VERSION,
                processing_status="completed"
            )
            db.add(ai_data)
        else:
            existing_ai_data.ai_summary = extraction_result.summary
            existing_ai_data.highlights = extraction_result.highlights
            existing_ai_data.challenges = extraction_result.challenges
            existing_ai_data.extracted_tips = extraction_result.extracted_tips
            existing_ai_data.sentiment = extraction_result.sentiment
            existing_ai_data.extracted_budget_per_person = extraction_result.extracted_budget_per_person
            existing_ai_data.model_version = settings.AI_MODEL_VERSION
            existing_ai_data.processing_status = "completed"

        db.commit()
        logger.info(f"Saved AI derivative for review {review_id}. Sentiment: {extraction_result.sentiment}")

        # 3. Update Location-Level Community Aggregated Insights
        if location_id or review.location_id:
            loc_id = location_id or review.location_id
            insights_aggregator.update_location_insights(db, loc_id)

    except Exception as e:
        logger.error(f"Failed to process review AI job for {review_id}: {e}", exc_info=True)
        db.rollback()
        # Record failed status in review_ai_data
        try:
            failed_ai = db.query(ReviewAIData).filter(ReviewAIData.review_id == review_id).first()
            if not failed_ai:
                failed_ai = ReviewAIData(
                    review_id=review_id,
                    ai_summary="AI processing temporarily unavailable.",
                    highlights=[],
                    challenges=[],
                    extracted_tips=[],
                    sentiment="neutral",
                    model_version=settings.AI_MODEL_VERSION,
                    processing_status="failed"
                )
                db.add(failed_ai)
            else:
                failed_ai.processing_status = "failed"
            db.commit()
        except Exception:
            db.rollback()
    finally:
        db.close()

def run_worker_loop():
    """Main worker event loop."""
    logger.info("Initializing database and starting AI Worker loop...")
    init_db()
    logger.info(f"Worker listening on queue '{settings.REVIEW_QUEUE_NAME}'...")

    while RUNNING:
        try:
            job = queue_service.dequeue_review_job(timeout=1)
            if job:
                process_review_job(job)
            else:
                time.sleep(0.5)
        except Exception as e:
            logger.error(f"Unexpected error in worker loop: {e}")
            time.sleep(1)

    logger.info("AI Worker stopped cleanly.")

if __name__ == "__main__":
    run_worker_loop()
