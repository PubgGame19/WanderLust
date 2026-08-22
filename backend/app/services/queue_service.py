import json
import logging
from typing import Optional, Dict, Any
import redis
from app.core.config import settings

logger = logging.getLogger("wanderlust.queue")

# In-memory fallback queue for local development / testing without running Redis
_IN_MEMORY_QUEUE = []

class QueueService:
    def __init__(self):
        self._redis_client: Optional[redis.Redis] = None
        self._init_client()

    def _init_client(self):
        try:
            client = redis.from_url(settings.REDIS_URL, decode_responses=True, socket_connect_timeout=2)
            client.ping()
            self._redis_client = client
            logger.info("Connected to Redis successfully.")
        except Exception as e:
            self._redis_client = None
            logger.warning(f"Redis not available ({e}). Using in-memory resilient fallback queue.")

    def enqueue_review_job(self, payload: Dict[str, Any]) -> bool:
        """Pushes review job to Redis queue or in-memory fallback."""
        data_str = json.dumps(payload)
        if self._redis_client:
            try:
                self._redis_client.rpush(settings.REVIEW_QUEUE_NAME, data_str)
                logger.info(f"Enqueued review job to Redis: {payload.get('review_id')}")
                return True
            except Exception as e:
                logger.error(f"Failed to push to Redis ({e}), falling back to in-memory.")
        
        _IN_MEMORY_QUEUE.append(data_str)
        logger.info(f"Enqueued review job to in-memory queue: {payload.get('review_id')}")
        return True

    def dequeue_review_job(self, timeout: int = 2) -> Optional[Dict[str, Any]]:
        """Pops a review job from Redis (blpop) or in-memory fallback."""
        if self._redis_client:
            try:
                item = self._redis_client.blpop(settings.REVIEW_QUEUE_NAME, timeout=timeout)
                if item:
                    _, data_str = item
                    return json.loads(data_str)
            except Exception as e:
                logger.error(f"Error popping from Redis: {e}")
        
        if _IN_MEMORY_QUEUE:
            data_str = _IN_MEMORY_QUEUE.pop(0)
            return json.loads(data_str)
        return None

queue_service = QueueService()
