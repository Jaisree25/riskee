#!/usr/bin/env python3
"""
NATS Message Subscriber - CLI tool to subscribe and view messages
Usage: python scripts/nats_subscribe.py <subject>
"""
import asyncio
import json
import sys
from datetime import datetime, timezone

from nats.aio.client import Client as NATS


async def subscribe_messages(subject: str, nats_url: str = "nats://localhost:4222"):
    """Subscribe to messages on a NATS subject"""
    nc = NATS()
    message_count = 0

    try:
        await nc.connect(nats_url)
        print(f"[OK] Connected to NATS at {nats_url}")
        print(f"[INFO] Subscribing to subject: {subject}")
        print(f"[INFO] Waiting for messages... (Press Ctrl+C to stop)\n")

        async def message_handler(msg):
            nonlocal message_count
            message_count += 1

            print(f"{'=' * 60}")
            print(f"Message #{message_count}")
            print(f"{'=' * 60}")
            print(f"Subject: {msg.subject}")
            print(f"Reply: {msg.reply or 'N/A'}")
            print(f"Size: {len(msg.data)} bytes")
            print(f"Time: {datetime.now(timezone.utc).isoformat()}")
            print(f"\nPayload:")

            # Try to parse as JSON
            try:
                data = json.loads(msg.data.decode())
                print(json.dumps(data, indent=2))
            except (json.JSONDecodeError, UnicodeDecodeError):
                # Print as text
                try:
                    print(msg.data.decode())
                except UnicodeDecodeError:
                    print(f"<binary data: {len(msg.data)} bytes>")

            print()

        # Subscribe to subject
        await nc.subscribe(subject, cb=message_handler)

        # Keep running until interrupted
        try:
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            print(f"\n[INFO] Stopping subscriber...")
            print(f"[INFO] Total messages received: {message_count}")

    except Exception as e:
        print(f"\n[ERROR] Subscription failed: {e}")
        sys.exit(1)
    finally:
        await nc.close()
        print(f"[OK] Disconnected from NATS")


def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/nats_subscribe.py <subject>")
        print("\nExamples:")
        print("  python scripts/nats_subscribe.py data.market.quote")
        print("  python scripts/nats_subscribe.py 'data.market.*'  # Wildcard")
        print("  python scripts/nats_subscribe.py 'event.>'  # All events")
        print("\nSupported subjects:")
        print("  data.market.* - Market data")
        print("  event.prediction.* - Prediction events")
        print("  job.predict.* - Prediction jobs")
        print("  thought.* - LLM explanations")
        print("\nWildcards:")
        print("  * - Matches one token (e.g., 'data.market.*')")
        print("  > - Matches one or more tokens (e.g., 'data.>')")
        sys.exit(1)

    subject = sys.argv[1]

    # Run async function
    asyncio.run(subscribe_messages(subject))


if __name__ == "__main__":
    main()
