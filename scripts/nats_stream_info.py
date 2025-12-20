#!/usr/bin/env python3
"""
NATS Stream Inspector - View stream status and messages
Usage: python scripts/nats_stream_info.py [stream_name]
"""
import asyncio
import json
import sys
from datetime import datetime, timezone

from nats.aio.client import Client as NATS
from nats.js.errors import NotFoundError


async def inspect_streams(stream_name: str = None, nats_url: str = "nats://localhost:4222"):
    """Inspect NATS JetStream streams"""
    nc = NATS()

    try:
        await nc.connect(nats_url)
        print(f"[OK] Connected to NATS at {nats_url}\n")

        # Get JetStream context
        js = nc.jetstream()

        if stream_name:
            # Show specific stream
            try:
                stream = await js.stream_info(stream_name)
                print_stream_details(stream)
            except NotFoundError:
                print(f"[ERROR] Stream '{stream_name}' not found")
                print("\nAvailable streams:")
                await list_all_streams(js)
        else:
            # List all streams
            await list_all_streams(js)

    except Exception as e:
        print(f"\n[ERROR] Failed to inspect streams: {e}")
        sys.exit(1)
    finally:
        await nc.close()


async def list_all_streams(js):
    """List all JetStream streams"""
    print("=" * 80)
    print("NATS JetStream Streams")
    print("=" * 80)
    print()

    try:
        streams = []
        async for stream in js.streams_info():
            streams.append(stream)

        if not streams:
            print("[INFO] No streams found")
            print("\nCreate streams with:")
            print("  python scripts/nats_stream_create.py")
            return

        # Print summary table
        print(f"{'Stream Name':<25} {'Messages':<12} {'Bytes':<12} {'Consumers':<12}")
        print("-" * 80)

        for stream in streams:
            config = stream.config
            state = stream.state
            print(
                f"{config.name:<25} "
                f"{state.messages:<12} "
                f"{format_bytes(state.bytes):<12} "
                f"{state.num_consumers:<12}"
            )

        print()
        print(f"Total streams: {len(streams)}")
        print("\nUse 'python scripts/nats_stream_info.py <stream_name>' for details")

    except Exception as e:
        print(f"[ERROR] Failed to list streams: {e}")


def print_stream_details(stream):
    """Print detailed stream information"""
    config = stream.config
    state = stream.state

    print("=" * 80)
    print(f"Stream: {config.name}")
    print("=" * 80)
    print()

    # Configuration
    print("Configuration:")
    print(f"  Subjects: {', '.join(config.subjects)}")
    print(f"  Retention: {config.retention}")
    print(f"  Storage: {config.storage}")
    print(f"  Max Messages: {config.max_msgs:,}")
    print(f"  Max Bytes: {format_bytes(config.max_bytes)}")
    print(f"  Max Age: {config.max_age / 1_000_000_000:.0f}s")
    print(f"  Max Message Size: {format_bytes(config.max_msg_size)}")
    print(f"  Replicas: {config.num_replicas}")

    print()

    # Current state
    print("Current State:")
    print(f"  Messages: {state.messages:,}")
    print(f"  Bytes: {format_bytes(state.bytes)}")
    print(f"  First Seq: {state.first_seq}")
    print(f"  Last Seq: {state.last_seq}")
    print(f"  Consumers: {state.num_consumers}")
    print(f"  First Time: {format_timestamp(state.first_ts)}")
    print(f"  Last Time: {format_timestamp(state.last_ts)}")

    print()


def format_bytes(bytes_val):
    """Format bytes to human readable"""
    if bytes_val == 0:
        return "0 B"
    elif bytes_val < 1024:
        return f"{bytes_val} B"
    elif bytes_val < 1024 * 1024:
        return f"{bytes_val / 1024:.2f} KB"
    elif bytes_val < 1024 * 1024 * 1024:
        return f"{bytes_val / (1024 * 1024):.2f} MB"
    else:
        return f"{bytes_val / (1024 * 1024 * 1024):.2f} GB"


def format_timestamp(ts):
    """Format timestamp to human readable"""
    if not ts:
        return "N/A"
    # NATS timestamps are in nanoseconds
    dt = datetime.fromtimestamp(ts / 1_000_000_000, tz=timezone.utc)
    return dt.strftime("%Y-%m-%d %H:%M:%S UTC")


def main():
    stream_name = sys.argv[1] if len(sys.argv) > 1 else None

    if stream_name == "--help" or stream_name == "-h":
        print("Usage: python scripts/nats_stream_info.py [stream_name]")
        print("\nExamples:")
        print("  python scripts/nats_stream_info.py              # List all streams")
        print("  python scripts/nats_stream_info.py PREDICTIONS  # Show stream details")
        print("\nExpected streams:")
        print("  MARKET_DATA - Market data stream")
        print("  PREDICTIONS - Predictions stream")
        print("  EXPLANATIONS - LLM explanations stream")
        print("  MODEL_METRICS - Model metrics stream")
        print("  ROUTING - Agent routing stream")
        sys.exit(0)

    # Run async function
    asyncio.run(inspect_streams(stream_name))


if __name__ == "__main__":
    main()
