# NATS JetStream Tutorial - Developer Gym

**What is it?** High-performance messaging system for microservices
**Why we use it?** Decouple services, async processing, event streaming
**In this project:** Prediction events, market data streams, explanation requests

---

## 🎯 Quick Concept

NATS = Post Office for Microservices

**Without NATS:**
```
Service A → (HTTP) → Service B
Service A → (HTTP) → Service C
Service A → (HTTP) → Service D
```
- A must wait for B, C, D
- If C is down, A fails
- Tight coupling

**With NATS:**
```
Service A → publish("prediction.new") → NATS
                                         ↓
Service B ← subscribe("prediction.*") ←┘
Service C ← subscribe("prediction.*") ←┘
Service D ← subscribe("prediction.new") ←┘
```
- A doesn't wait
- If C is down, message queued
- Loose coupling

---

## 🏗️ Core Concepts

### 1. Subjects (Topics)

Like email addresses - use dots for hierarchy:

```
market.data.ohlcv          → Market OHLCV data
market.data.news           → Market news
predictions.normal.AAPL    → Normal day prediction for AAPL
predictions.earnings.GOOGL → Earnings day prediction for GOOGL
explanations.request       → Request for explanation
explanations.response      → Explanation result
```

**Wildcards:**
```
predictions.*        → All predictions
predictions.*.AAPL   → All AAPL predictions
predictions.>        → All predictions and sub-topics
```

### 2. Pub/Sub Pattern

```python
# Publisher (fire and forget)
await js.publish("predictions.normal.AAPL", data)

# Subscriber (receive messages)
sub = await nc.subscribe("predictions.*")
async for msg in sub.messages:
    print(f"Received: {msg.data}")
```

### 3. JetStream (Persistence)

**Core NATS:**
- Messages disappear if no subscriber
- No message history
- Fire-and-forget

**JetStream:**
- Messages stored on disk
- Subscribers can replay history
- Guaranteed delivery
- Multiple subscribers get same message

### 4. Streams

A "bucket" that stores messages:

```
Stream: PREDICTIONS
  ├─ Subject: predictions.normal.*
  ├─ Subject: predictions.earnings.*
  ├─ Retention: 30 days
  ├─ Max Size: 5 GB
  └─ Storage: File
```

### 5. Consumers

How you read from a stream:

```
Push Consumer: Stream pushes to you
Pull Consumer: You pull when ready (we use this)
```

---

## 💻 Hands-On Examples

### Check NATS Status

```bash
# HTTP monitoring
curl http://localhost:8222/healthz
curl http://localhost:8222/jsz

# PowerShell
Invoke-RestMethod -Uri "http://localhost:8222/healthz"
Invoke-RestMethod -Uri "http://localhost:8222/jsz"
```

### Example 1: Simple Pub/Sub (Python)

```python
import asyncio
from nats.aio.client import Client as NATS

async def example():
    nc = NATS()
    await nc.connect("nats://localhost:4222")

    # Subscribe
    async def message_handler(msg):
        print(f"Received: {msg.data.decode()}")

    await nc.subscribe("predictions.*", cb=message_handler)

    # Publish
    await nc.publish("predictions.normal", b"AAPL:155.50")

    # Wait for messages
    await asyncio.sleep(1)

    await nc.close()

asyncio.run(example())
```

### Example 2: JetStream Publishing

```python
import asyncio
import json
from nats.aio.client import Client as NATS

async def publish_prediction():
    nc = NATS()
    await nc.connect("nats://localhost:4222")

    # Get JetStream context
    js = nc.jetstream()

    # Create message
    prediction = {
        "ticker": "AAPL",
        "predicted_price": 155.50,
        "confidence": 0.87,
        "timestamp": "2025-12-17T10:00:00Z"
    }

    # Publish to JetStream (persisted)
    ack = await js.publish(
        "predictions.normal.AAPL",
        json.dumps(prediction).encode()
    )

    print(f"Published! Stream: {ack.stream}, Sequence: {ack.seq}")

    await nc.close()

asyncio.run(publish_prediction())
```

### Example 3: JetStream Pull Consumer

```python
import asyncio
import json
from nats.aio.client import Client as NATS

async def consume_predictions():
    nc = NATS()
    await nc.connect("nats://localhost:4222")

    js = nc.jetstream()

    # Create pull consumer
    psub = await js.pull_subscribe(
        "predictions.*",
        "prediction-processor"
    )

    print("Waiting for messages...")

    while True:
        try:
            # Fetch batch of messages
            messages = await psub.fetch(batch=10, timeout=5)

            for msg in messages:
                # Process message
                data = json.loads(msg.data.decode())
                print(f"Processing: {data['ticker']} → ${data['predicted_price']}")

                # Acknowledge (message won't be redelivered)
                await msg.ack()

        except TimeoutError:
            print("No messages, waiting...")
            await asyncio.sleep(1)

asyncio.run(consume_predictions())
```

### Example 4: Create Stream

```python
import asyncio
from nats.aio.client import Client as NATS
from nats.js.api import StreamConfig, RetentionPolicy, StorageType

async def create_stream():
    nc = NATS()
    await nc.connect("nats://localhost:4222")

    js = nc.jetstream()

    # Define stream
    stream_config = StreamConfig(
        name="PREDICTIONS",
        subjects=["predictions.normal.*", "predictions.earnings.*"],
        description="ML prediction events",
        max_age=30 * 24 * 60 * 60 * 1_000_000_000,  # 30 days in nanoseconds
        max_bytes=5 * 1024 * 1024 * 1024,  # 5 GB
        storage=StorageType.FILE,
        retention=RetentionPolicy.LIMITS,
    )

    # Create stream
    stream = await js.add_stream(stream_config)
    print(f"Created stream: {stream.config.name}")

    await nc.close()

asyncio.run(create_stream())
```

### Example 5: Request-Reply Pattern

```python
import asyncio
from nats.aio.client import Client as NATS

# Server (responder)
async def explanation_server():
    nc = NATS()
    await nc.connect("nats://localhost:4222")

    async def handle_request(msg):
        request = msg.data.decode()
        print(f"Received request: {request}")

        # Generate explanation
        explanation = f"Explanation for {request}: Market trends indicate..."

        # Reply
        await nc.publish(msg.reply, explanation.encode())

    await nc.subscribe("explanation.request", cb=handle_request)

    # Keep running
    while True:
        await asyncio.sleep(1)

# Client (requester)
async def request_explanation():
    nc = NATS()
    await nc.connect("nats://localhost:4222")

    # Send request and wait for reply
    response = await nc.request(
        "explanation.request",
        b"AAPL prediction",
        timeout=5
    )

    print(f"Got explanation: {response.data.decode()}")

    await nc.close()
```

---

## 🎓 Best Practices for Our Project

### 1. Subject Naming Convention

```python
# Good - hierarchical and descriptive
"market.data.ohlcv.AAPL"
"predictions.normal.AAPL"
"predictions.earnings.GOOGL"
"explanations.request.123"
"metrics.model.accuracy"

# Bad - flat and unclear
"data"
"pred"
"AAPL"
```

### 2. Message Format (JSON)

```python
import json

# Standard message structure
message = {
    "type": "prediction",
    "ticker": "AAPL",
    "data": {
        "predicted_price": 155.50,
        "confidence": 0.87
    },
    "metadata": {
        "model_version": "v1.0",
        "timestamp": "2025-12-17T10:00:00Z"
    }
}

await js.publish(
    "predictions.normal.AAPL",
    json.dumps(message).encode()
)
```

### 3. Error Handling

```python
async def safe_publish(subject, data):
    """Publish with retry logic"""
    max_retries = 3

    for attempt in range(max_retries):
        try:
            ack = await js.publish(subject, data)
            return ack
        except Exception as e:
            if attempt == max_retries - 1:
                print(f"Failed to publish after {max_retries} attempts: {e}")
                raise
            await asyncio.sleep(1)  # Wait before retry
```

### 4. Consumer Acknowledgment

```python
async def process_messages():
    psub = await js.pull_subscribe("predictions.*", "processor")

    while True:
        messages = await psub.fetch(batch=10, timeout=5)

        for msg in messages:
            try:
                # Process message
                process_prediction(msg.data)

                # ✅ Success - acknowledge
                await msg.ack()

            except Exception as e:
                # ❌ Failed - negative ack (will be redelivered)
                await msg.nak()
                print(f"Error processing message: {e}")
```

---

## 🔍 Our Stream Configuration

We have 5 streams in this project:

### 1. MARKET_DATA
```python
Subject: market.data.*
Retention: 7 days
Max Size: 10 GB
Purpose: Real-time market data (OHLCV, news)
```

### 2. PREDICTIONS
```python
Subject: predictions.normal.*, predictions.earnings.*
Retention: 30 days
Max Size: 5 GB
Purpose: ML model predictions
```

### 3. EXPLANATIONS
```python
Subject: explanations.*
Retention: 30 days
Max Size: 2 GB
Purpose: LLM-generated explanations
```

### 4. MODEL_METRICS
```python
Subject: metrics.model.*
Retention: 90 days
Max Size: 1 GB
Purpose: Model performance metrics
```

### 5. ROUTING
```python
Subject: routing.*
Retention: 7 days
Max Size: 512 MB
Purpose: Agent routing decisions
```

---

## 🐛 Common Issues & Solutions

### Issue: "no response from stream"

**Solution:**
```python
# Stream doesn't exist - create it first
await js.add_stream(stream_config)

# Or check existing streams
streams = await js.streams_info()
for stream in streams:
    print(stream.config.name)
```

### Issue: Messages not persisting

**Solution:**
```bash
# Check if using JetStream (not core NATS)
# ❌ BAD - core NATS (not persisted)
await nc.publish("subject", data)

# ✅ GOOD - JetStream (persisted)
await js.publish("subject", data)
```

### Issue: Consumer not receiving messages

**Solution:**
```python
# Check consumer is subscribed to correct subject
# Wildcards must match:
await js.pull_subscribe("predictions.*", "consumer")

# This will receive:
# predictions.normal.AAPL ✓
# predictions.earnings.GOOGL ✓

# This will NOT receive:
# market.data.AAPL ✗
```

---

## 🎯 Complete Example: Prediction Pipeline

```python
import asyncio
import json
from datetime import datetime
from nats.aio.client import Client as NATS

# Service 1: Ingest market data
async def market_data_publisher():
    nc = NATS()
    await nc.connect("nats://localhost:4222")
    js = nc.jetstream()

    # Simulate market data
    market_data = {
        "ticker": "AAPL",
        "open": 154.20,
        "high": 156.10,
        "low": 153.90,
        "close": 155.50,
        "volume": 50000000,
        "timestamp": datetime.now().isoformat()
    }

    await js.publish(
        "market.data.ohlcv.AAPL",
        json.dumps(market_data).encode()
    )
    print("Published market data")

    await nc.close()

# Service 2: Make prediction
async def prediction_agent():
    nc = NATS()
    await nc.connect("nats://localhost:4222")
    js = nc.jetstream()

    # Subscribe to market data
    psub = await js.pull_subscribe("market.data.ohlcv.*", "predictor")

    messages = await psub.fetch(batch=1, timeout=5)

    for msg in messages:
        market_data = json.loads(msg.data.decode())

        # Make prediction
        prediction = {
            "ticker": market_data["ticker"],
            "predicted_price": market_data["close"] * 1.01,  # Simple prediction
            "confidence": 0.87,
            "timestamp": datetime.now().isoformat()
        }

        # Publish prediction
        await js.publish(
            f"predictions.normal.{market_data['ticker']}",
            json.dumps(prediction).encode()
        )
        print("Published prediction")

        await msg.ack()

    await nc.close()

# Service 3: Generate explanation
async def explanation_worker():
    nc = NATS()
    await nc.connect("nats://localhost:4222")
    js = nc.jetstream()

    # Subscribe to predictions
    psub = await js.pull_subscribe("predictions.*", "explainer")

    messages = await psub.fetch(batch=1, timeout=5)

    for msg in messages:
        prediction = json.loads(msg.data.decode())

        # Generate explanation
        explanation = {
            "ticker": prediction["ticker"],
            "text": f"Price predicted to reach ${prediction['predicted_price']} based on market trends",
            "timestamp": datetime.now().isoformat()
        }

        # Publish explanation
        await js.publish(
            f"explanations.{prediction['ticker']}",
            json.dumps(explanation).encode()
        )
        print("Published explanation")

        await msg.ack()

    await nc.close()

# Run pipeline
async def run_pipeline():
    await market_data_publisher()
    await asyncio.sleep(1)
    await prediction_agent()
    await asyncio.sleep(1)
    await explanation_worker()

asyncio.run(run_pipeline())
```

---

## 📚 Learn More

**Official Docs:**
- NATS Docs: https://docs.nats.io/
- JetStream: https://docs.nats.io/nats-concepts/jetstream
- nats.py: https://github.com/nats-io/nats.py

**Our Configuration:**
- NATS Port: 4222
- Monitoring: http://localhost:8222
- Streams: See `config/nats_streams.md`

**Test Script:**
```bash
# Run our test script
python scripts/test_nats_pubsub.py
```

---

## ✅ Quick Checklist

- [ ] Understand pub/sub pattern
- [ ] Know difference between core NATS and JetStream
- [ ] Can publish messages to subjects
- [ ] Can subscribe with wildcards (predictions.*)
- [ ] Understand streams persist messages
- [ ] Know how to create pull consumer
- [ ] Can acknowledge messages (ack/nak)
- [ ] Understand request-reply pattern
- [ ] Know when to use NATS vs HTTP

**Next:** Learn Qdrant for vector search! → [04_Qdrant.md](04_Qdrant.md)
