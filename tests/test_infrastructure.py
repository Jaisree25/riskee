"""
Infrastructure integration tests
Tests connectivity and basic operations for all services
"""
import pytest
from redis import Redis
from qdrant_client import QdrantClient
from sqlalchemy.orm import Session


@pytest.mark.integration
class TestDatabaseConnectivity:
    """Test TimescaleDB connectivity and basic operations."""

    def test_db_connection(self, db_session: Session):
        """Test database connection."""
        result = db_session.execute("SELECT 1").scalar()
        assert result == 1

    def test_timescaledb_extension(self, db_session: Session):
        """Test TimescaleDB extension is loaded."""
        result = db_session.execute(
            "SELECT extname FROM pg_extension WHERE extname = 'timescaledb'"
        ).scalar()
        assert result == "timescaledb"

    def test_predictions_table_exists(self, db_session: Session):
        """Test predictions table exists."""
        result = db_session.execute(
            """
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = 'predictions'
            )
            """
        ).scalar()
        assert result is True


@pytest.mark.integration
class TestRedisConnectivity:
    """Test Redis connectivity and basic operations."""

    def test_redis_ping(self, redis_client: Redis):
        """Test Redis connection."""
        assert redis_client.ping() is True

    def test_redis_set_get(self, redis_client: Redis):
        """Test Redis SET/GET operations."""
        redis_client.set("test_key", "test_value")
        value = redis_client.get("test_key")
        assert value == "test_value"

    def test_redis_hash_operations(self, redis_client: Redis):
        """Test Redis hash operations."""
        redis_client.hset("test_hash", "field1", "value1")
        redis_client.hset("test_hash", "field2", "value2")

        value1 = redis_client.hget("test_hash", "field1")
        value2 = redis_client.hget("test_hash", "field2")

        assert value1 == "value1"
        assert value2 == "value2"

    def test_redis_ttl(self, redis_client: Redis):
        """Test Redis TTL."""
        redis_client.setex("test_ttl", 60, "value")
        ttl = redis_client.ttl("test_ttl")
        assert ttl > 0 and ttl <= 60


@pytest.mark.integration
@pytest.mark.asyncio
class TestNATSConnectivity:
    """Test NATS connectivity and basic operations."""

    async def test_nats_connection(self, nats_client):
        """Test NATS connection."""
        assert nats_client.is_connected

    async def test_nats_publish_subscribe(self, nats_client):
        """Test NATS publish/subscribe."""
        received_messages = []

        async def message_handler(msg):
            received_messages.append(msg.data.decode())

        # Subscribe
        await nats_client.subscribe("test.subject", cb=message_handler)

        # Publish
        await nats_client.publish("test.subject", b"test message")
        await nats_client.flush()

        # Wait a bit for message delivery
        import asyncio
        await asyncio.sleep(0.1)

        assert len(received_messages) == 1
        assert received_messages[0] == "test message"


@pytest.mark.integration
class TestQdrantConnectivity:
    """Test Qdrant connectivity and basic operations."""

    def test_qdrant_connection(self, qdrant_client: QdrantClient):
        """Test Qdrant connection."""
        collections = qdrant_client.get_collections()
        assert collections is not None

    def test_qdrant_collections_exist(self, qdrant_client: QdrantClient):
        """Test required collections exist."""
        collections = qdrant_client.get_collections()
        collection_names = [c.name for c in collections.collections]

        required_collections = [
            "market_news",
            "earnings_calls",
            "economic_indicators",
            "technical_patterns",
            "prediction_context",
        ]

        for collection in required_collections:
            assert collection in collection_names, f"Collection {collection} not found"


@pytest.mark.unit
class TestSampleData:
    """Test sample data fixtures."""

    def test_sample_prediction_structure(self, sample_prediction):
        """Test sample prediction has required fields."""
        required_fields = [
            "ticker",
            "prediction_time",
            "predicted_price",
            "current_price",
            "confidence",
            "model_type",
        ]

        for field in required_fields:
            assert field in sample_prediction

    def test_sample_market_data_structure(self, sample_market_data):
        """Test sample market data has required fields."""
        required_fields = ["ticker", "timestamp", "open", "high", "low", "close", "volume"]

        for field in required_fields:
            assert field in sample_market_data
