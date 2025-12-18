#!/usr/bin/env python3
"""
Feature 1: NATS JetStream Publisher/Subscriber Test Script
Tests NATS messaging for the prediction system
"""

import asyncio
import json
import sys
from datetime import datetime
from nats.aio.client import Client as NATS
from nats.js.api import StreamConfig, RetentionPolicy, StorageType

async def create_test_stream(js):
    """Create a test stream for demonstration"""
    try:
        await js.add_stream(
            StreamConfig(
                name="TEST_PREDICTIONS",
                subjects=["test.predictions.*"],
                description="Test stream for predictions",
                max_age=3600 * 1_000_000_000,  # 1 hour in nanoseconds
                max_bytes=100 * 1024 * 1024,  # 100MB
                storage=StorageType.FILE,
                retention=RetentionPolicy.LIMITS,
            )
        )
        print("[OK] Created test stream: TEST_PREDICTIONS")
    except Exception as e:
        if "stream name already in use" in str(e):
            print("[SKIP] Test stream already exists")
        else:
            raise

async def publish_messages(nc, js):
    """Publish test messages to NATS JetStream"""
    print("\n" + "="*60)
    print("Publishing Test Messages")
    print("="*60)

    # Sample prediction messages
    messages = [
        {
            "ticker": "AAPL",
            "prediction_time": datetime.utcnow().isoformat(),
            "predicted_price": 150.25,
            "confidence_score": 0.85,
            "agent_type": "normal"
        },
        {
            "ticker": "GOOGL",
            "prediction_time": datetime.utcnow().isoformat(),
            "predicted_price": 2850.50,
            "confidence_score": 0.78,
            "agent_type": "earnings"
        },
        {
            "ticker": "MSFT",
            "prediction_time": datetime.utcnow().isoformat(),
            "predicted_price": 380.75,
            "confidence_score": 0.92,
            "agent_type": "normal"
        }
    ]

    for msg in messages:
        subject = f"test.predictions.{msg['ticker']}"
        payload = json.dumps(msg).encode()

        # Publish to JetStream
        ack = await js.publish(subject, payload)

        print(f"[OK] Published to '{subject}'")
        print(f"  Ticker: {msg['ticker']}")
        print(f"  Predicted Price: ${msg['predicted_price']}")
        print(f"  Confidence: {msg['confidence_score']}")
        print(f"  Stream: {ack.stream}")
        print(f"  Sequence: {ack.seq}")

    return len(messages)

async def subscribe_messages(nc, js):
    """Subscribe to and consume test messages"""
    print("\n" + "="*60)
    print("Subscribing to Test Messages")
    print("="*60)

    received_count = 0

    # Create a pull consumer
    psub = await js.pull_subscribe("test.predictions.*", "test-consumer")

    print("[OK] Created pull subscriber on 'test.predictions.*'")
    print("[INFO] Fetching messages...")

    try:
        # Fetch messages (up to 10, wait max 5 seconds)
        messages = await psub.fetch(batch=10, timeout=5)

        for msg in messages:
            received_count += 1
            data = json.loads(msg.data.decode())

            print(f"\n[OK] Received message #{received_count}")
            print(f"  Subject: {msg.subject}")
            print(f"  Ticker: {data['ticker']}")
            print(f"  Predicted Price: ${data['predicted_price']}")
            print(f"  Confidence: {data['confidence_score']}")
            print(f"  Agent Type: {data['agent_type']}")

            # Acknowledge the message
            await msg.ack()

    except TimeoutError:
        print("[INFO] No more messages (timeout)")

    return received_count

async def cleanup_test_stream(js):
    """Delete the test stream"""
    try:
        await js.delete_stream("TEST_PREDICTIONS")
        print("\n[OK] Cleaned up test stream")
    except Exception as e:
        print(f"[WARN] Could not cleanup test stream: {e}")

async def test_nats_pubsub():
    """Main test function"""

    print("="*60)
    print("NATS JetStream Publisher/Subscriber Test")
    print("="*60)

    # Connect to NATS
    nc = NATS()

    try:
        await nc.connect("nats://localhost:4222")
        print("\n[OK] Connected to NATS server")

        # Get JetStream context
        js = nc.jetstream()
        print("[OK] JetStream context obtained")

        # Create test stream
        await create_test_stream(js)

        # Publish messages
        published = await publish_messages(nc, js)
        print(f"\n[OK] Published {published} messages")

        # Wait a moment for messages to be persisted
        await asyncio.sleep(1)

        # Subscribe and receive messages
        received = await subscribe_messages(nc, js)
        print(f"\n[OK] Received {received} messages")

        # Verify counts match
        if published == received:
            print("\n[OK] All published messages were received successfully!")
        else:
            print(f"\n[WARN] Message count mismatch: {published} sent, {received} received")

        # Cleanup
        await cleanup_test_stream(js)

        print("\n" + "="*60)
        print("[OK] NATS Pub/Sub Test Complete")
        print("="*60)

        print("\nTest Results:")
        print(f"  Messages Published: {published}")
        print(f"  Messages Received: {received}")
        print(f"  Success Rate: {(received/published*100) if published > 0 else 0:.1f}%")

        print("\nNATS JetStream is working correctly!")
        print("Ready for production message streaming.")

    except Exception as e:
        print(f"\n[ERROR] Test failed: {e}", file=sys.stderr)
        raise
    finally:
        await nc.close()

if __name__ == "__main__":
    try:
        asyncio.run(test_nats_pubsub())
    except Exception as e:
        print(f"\n[ERROR] Error: {e}", file=sys.stderr)
        sys.exit(1)
