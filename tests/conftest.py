"""
Pytest configuration and shared fixtures
"""
import asyncio
import os
from typing import AsyncGenerator, Generator

import pytest
import pytest_asyncio
from redis import Redis
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

# Set test environment
os.environ["ENVIRONMENT"] = "test"


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
def db_url() -> str:
    """Database URL for testing."""
    return os.getenv(
        "TEST_DATABASE_URL",
        "postgresql://postgres:riskee123@localhost:5432/riskee_test"
    )


@pytest.fixture(scope="session")
def redis_url() -> str:
    """Redis URL for testing."""
    return os.getenv("TEST_REDIS_URL", "redis://localhost:6379/1")


@pytest.fixture(scope="function")
def db_session(db_url: str) -> Generator[Session, None, None]:
    """Create a database session for testing."""
    engine = create_engine(db_url)
    SessionLocal = sessionmaker(bind=engine)
    session = SessionLocal()

    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture(scope="function")
def redis_client(redis_url: str) -> Generator[Redis, None, None]:
    """Create a Redis client for testing."""
    client = Redis.from_url(redis_url, decode_responses=True)

    try:
        yield client
    finally:
        # Clean up test keys
        client.flushdb()
        client.close()


@pytest_asyncio.fixture
async def nats_client():
    """Create a NATS client for testing."""
    from nats.aio.client import Client as NATS

    nc = NATS()
    await nc.connect("nats://localhost:4222")

    try:
        yield nc
    finally:
        await nc.close()


@pytest.fixture
def qdrant_client():
    """Create a Qdrant client for testing."""
    from qdrant_client import QdrantClient

    client = QdrantClient(host="localhost", port=6333)

    try:
        yield client
    finally:
        # Clean up test collections
        collections = client.get_collections().collections
        for collection in collections:
            if collection.name.startswith("test_"):
                client.delete_collection(collection.name)


@pytest.fixture
def sample_prediction():
    """Sample prediction data for testing."""
    return {
        "ticker": "AAPL",
        "prediction_time": "2025-12-19T10:00:00Z",
        "predicted_price": 155.50,
        "current_price": 154.20,
        "change_percent": 0.84,
        "confidence": 0.87,
        "model_type": "normal",
        "model_version": "v1.0.0",
    }


@pytest.fixture
def sample_market_data():
    """Sample market data for testing."""
    return {
        "ticker": "AAPL",
        "timestamp": "2025-12-19T09:55:00Z",
        "open": 154.00,
        "high": 154.50,
        "low": 153.80,
        "close": 154.20,
        "volume": 1000000,
    }
