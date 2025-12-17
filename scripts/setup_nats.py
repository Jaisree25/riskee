#!/usr/bin/env python3
"""
Feature 1: NATS JetStream Setup Script
Configures JetStream streams for the prediction system
"""

import asyncio
import sys
from nats.aio.client import Client as NATS
from nats.js.api import StreamConfig, RetentionPolicy, StorageType

async def setup_jetstream():
    """Create NATS JetStream streams for the prediction system"""

    # Connect to NATS
    nc = NATS()
    try:
        await nc.connect("nats://localhost:4222")
        print("✓ Connected to NATS server")

        # Get JetStream context
        js = nc.jetstream()
        print("✓ JetStream context obtained")

        # Stream configurations for the prediction system
        streams = [
            {
                "name": "MARKET_DATA",
                "subjects": ["market.data.*"],
                "description": "Market data ingestion stream (OHLCV, news, etc)",
                "max_age": 7 * 24 * 60 * 60 * 1_000_000_000,  # 7 days in nanoseconds
                "max_bytes": 10 * 1024 * 1024 * 1024,  # 10GB
                "storage": StorageType.FILE,
                "retention": RetentionPolicy.LIMITS,
            },
            {
                "name": "PREDICTIONS",
                "subjects": ["predictions.normal.*", "predictions.earnings.*"],
                "description": "ML prediction events stream",
                "max_age": 30 * 24 * 60 * 60 * 1_000_000_000,  # 30 days
                "max_bytes": 5 * 1024 * 1024 * 1024,  # 5GB
                "storage": StorageType.FILE,
                "retention": RetentionPolicy.LIMITS,
            },
            {
                "name": "EXPLANATIONS",
                "subjects": ["explanations.*"],
                "description": "LLM explanation generation requests and results",
                "max_age": 30 * 24 * 60 * 60 * 1_000_000_000,  # 30 days
                "max_bytes": 2 * 1024 * 1024 * 1024,  # 2GB
                "storage": StorageType.FILE,
                "retention": RetentionPolicy.LIMITS,
            },
            {
                "name": "MODEL_METRICS",
                "subjects": ["metrics.model.*"],
                "description": "Model performance metrics and monitoring",
                "max_age": 90 * 24 * 60 * 60 * 1_000_000_000,  # 90 days
                "max_bytes": 1 * 1024 * 1024 * 1024,  # 1GB
                "storage": StorageType.FILE,
                "retention": RetentionPolicy.LIMITS,
            },
            {
                "name": "ROUTING",
                "subjects": ["routing.*"],
                "description": "Agent routing decisions and events",
                "max_age": 7 * 24 * 60 * 60 * 1_000_000_000,  # 7 days
                "max_bytes": 512 * 1024 * 1024,  # 512MB
                "storage": StorageType.FILE,
                "retention": RetentionPolicy.LIMITS,
            },
        ]

        # Create each stream
        for stream_config in streams:
            try:
                stream = await js.add_stream(
                    StreamConfig(
                        name=stream_config["name"],
                        subjects=stream_config["subjects"],
                        description=stream_config["description"],
                        max_age=stream_config["max_age"],
                        max_bytes=stream_config["max_bytes"],
                        storage=stream_config["storage"],
                        retention=stream_config["retention"],
                    )
                )
                print(f"✓ Created stream: {stream_config['name']}")
                print(f"  Subjects: {', '.join(stream_config['subjects'])}")
                print(f"  Storage: {stream_config['storage'].name}")
                print(f"  Max Age: {stream_config['max_age'] // (24*60*60*1_000_000_000)} days")
                print(f"  Max Size: {stream_config['max_bytes'] // (1024*1024)} MB")
            except Exception as e:
                if "stream name already in use" in str(e):
                    print(f"⚠ Stream {stream_config['name']} already exists, skipping")
                else:
                    print(f"✗ Error creating stream {stream_config['name']}: {e}")
                    raise

        # List all streams
        print("\n" + "="*60)
        print("Current JetStream Streams:")
        print("="*60)
        streams_list = await js.streams_info()
        for stream in streams_list:
            print(f"\n{stream.config.name}:")
            print(f"  Subjects: {', '.join(stream.config.subjects)}")
            print(f"  Messages: {stream.state.messages}")
            print(f"  Bytes: {stream.state.bytes}")
            print(f"  Consumers: {stream.state.consumer_count}")

        print("\n✓ NATS JetStream setup complete!")

    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        await nc.close()

if __name__ == "__main__":
    asyncio.run(setup_jetstream())
