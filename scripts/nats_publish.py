#!/usr/bin/env python3
"""
NATS Message Publisher - CLI tool to publish test messages
Usage: python scripts/nats_publish.py <subject> <message>
"""
import asyncio
import json
import sys
from datetime import datetime, timezone

from nats.aio.client import Client as NATS


async def publish_message(subject: str, message: str, nats_url: str = "nats://localhost:4222"):
    """Publish a message to NATS"""
    nc = NATS()

    try:
        await nc.connect(nats_url)
        print(f"[OK] Connected to NATS at {nats_url}")

        # If message looks like JSON, parse and pretty print
        try:
            msg_data = json.loads(message)
            message_bytes = json.dumps(msg_data).encode()
            print(f"\n[INFO] Publishing JSON message to '{subject}':")
            print(json.dumps(msg_data, indent=2))
        except json.JSONDecodeError:
            message_bytes = message.encode()
            print(f"\n[INFO] Publishing text message to '{subject}':")
            print(f"  {message}")

        # Publish message
        await nc.publish(subject, message_bytes)
        await nc.flush()

        print(f"\n[OK] Message published successfully")
        print(f"  Subject: {subject}")
        print(f"  Size: {len(message_bytes)} bytes")
        print(f"  Time: {datetime.now(timezone.utc).isoformat()}")

    except Exception as e:
        print(f"\n[ERROR] Failed to publish message: {e}")
        sys.exit(1)
    finally:
        await nc.close()


def main():
    if len(sys.argv) < 3:
        print("Usage: python scripts/nats_publish.py <subject> <message>")
        print("\nExamples:")
        print('  python scripts/nats_publish.py data.market.quote \'{"ticker":"AAPL","price":155.50}\'')
        print('  python scripts/nats_publish.py event.prediction.updated "Prediction updated"')
        print("\nSupported subjects:")
        print("  data.market.* - Market data")
        print("  event.prediction.* - Prediction events")
        print("  job.predict.* - Prediction jobs")
        print("  thought.* - LLM explanations")
        sys.exit(1)

    subject = sys.argv[1]
    message = sys.argv[2]

    # Run async function
    asyncio.run(publish_message(subject, message))


if __name__ == "__main__":
    main()
