import math
import logging
from typing import Generator
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

logger = logging.getLogger("wanderlust.db")

# Engine configuration
connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def _auto_sync_sqlite_columns():
    """Auto-migrates missing columns in SQLite database files."""
    if not settings.DATABASE_URL.startswith("sqlite"):
        return
    try:
        inspector = inspect(engine)
        tables = inspector.get_table_names()

        with engine.connect() as conn:
            if "reviews" in tables:
                columns = [col["name"] for col in inspector.get_columns("reviews")]
                if "trip_id" not in columns:
                    logger.info("Auto-syncing SQLite: Adding 'trip_id' to 'reviews'")
                    conn.execute(text("ALTER TABLE reviews ADD COLUMN trip_id VARCHAR;"))
                    conn.commit()

            if "review_photos" in tables:
                columns = [col["name"] for col in inspector.get_columns("review_photos")]
                if "trip_id" not in columns:
                    logger.info("Auto-syncing SQLite: Adding 'trip_id' to 'review_photos'")
                    conn.execute(text("ALTER TABLE review_photos ADD COLUMN trip_id VARCHAR;"))
                    conn.commit()
                if "user_id" not in columns:
                    logger.info("Auto-syncing SQLite: Adding 'user_id' to 'review_photos'")
                    conn.execute(text("ALTER TABLE review_photos ADD COLUMN user_id VARCHAR;"))
                    conn.commit()
                if "display_order" not in columns:
                    logger.info("Auto-syncing SQLite: Adding 'display_order' to 'review_photos'")
                    conn.execute(text("ALTER TABLE review_photos ADD COLUMN display_order INTEGER DEFAULT 0;"))
                    conn.commit()
    except Exception as e:
        logger.warning("SQLite auto-migration check note: %s", e)

def init_db():
    """Initializes database tables and ensures schema consistency."""
    # If using PostgreSQL, create extensions if possible
    if settings.DATABASE_URL.startswith("postgresql"):
        try:
            with engine.connect() as conn:
                conn.execute(text("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"))
                conn.execute(text("CREATE EXTENSION IF NOT EXISTS \"postgis\";"))
                conn.execute(text("CREATE EXTENSION IF NOT EXISTS \"pg_trgm\";"))
                conn.commit()
        except Exception as e:
            logger.warning("[DB] Notice: Extension initialization note: %s", e)
            
    # Create all tables defined in models
    Base.metadata.create_all(bind=engine)

    # Ensure SQLite columns are synchronized
    _auto_sync_sqlite_columns()

def calculate_haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates Haversine distance in kilometers between two coordinates."""
    r = 6371.0 # Earth's radius in kilometers
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(r * c, 2)
