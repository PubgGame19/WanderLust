import os
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

# Set test environment
os.environ["DATABASE_URL"] = "sqlite:///./test_wanderlust.db"
os.environ["SECRET_KEY"] = "test_secret_jwt_key_12345"

import app.core.database as db_module
import app.services.queue_service as qs_module
from app.core.database import Base, get_db
from app.main import app

test_engine = create_engine(
    "sqlite:///./test_wanderlust.db",
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

# Override engine and session
db_module.engine = test_engine
db_module.SessionLocal = TestingSessionLocal

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="session", autouse=True)
def setup_test_suite():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)
    if os.path.exists("./test_wanderlust.db"):
        try:
            os.remove("./test_wanderlust.db")
        except Exception:
            pass

@pytest.fixture(autouse=True)
def clear_queue_before_test():
    qs_module._IN_MEMORY_QUEUE.clear()
    yield
    qs_module._IN_MEMORY_QUEUE.clear()

@pytest.fixture
def client():
    return TestClient(app)
