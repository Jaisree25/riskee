# NATS JetStream Configuration

## Overview
NATS JetStream provides message streaming with persistence for the prediction system. Streams will be created automatically by application services on startup.

## Stream Definitions

### 1. MARKET_DATA
**Purpose:** Ingest real-time market data (OHLCV, news, economic indicators)

```yaml
Name: MARKET_DATA
Subjects:
  - market.data.ohlcv
  - market.data.news
  - market.data.economic
Max Age: 7 days
Max Bytes: 10 GB
Storage: File
Retention: Limits
```

### 2. PREDICTIONS
**Purpose:** ML model predictions from normal and earnings agents

```yaml
Name: PREDICTIONS
Subjects:
  - predictions.normal.*
  - predictions.earnings.*
Max Age: 30 days
Max Bytes: 5 GB
Storage: File
Retention: Limits
```

### 3. EXPLANATIONS
**Purpose:** LLM-generated explanations for predictions

```yaml
Name: EXPLANATIONS
Subjects:
  - explanations.request
  - explanations.response
Max Age: 30 days
Max Bytes: 2 GB
Storage: File
Retention: Limits
```

### 4. MODEL_METRICS
**Purpose:** Model performance metrics and monitoring data

```yaml
Name: MODEL_METRICS
Subjects:
  - metrics.model.normal
  - metrics.model.earnings
  - metrics.model.evaluation
Max Age: 90 days
Max Bytes: 1 GB
Storage: File
Retention: Limits
```

### 5. ROUTING
**Purpose:** Agent routing decisions and events

```yaml
Name: ROUTING
Subjects:
  - routing.decision
  - routing.event
Max Age: 7 days
Max Bytes: 512 MB
Storage: File
Retention: Limits
```

## Message Flow

```
Market Data Ingestion → MARKET_DATA stream
    ↓
Routing Agent → ROUTING stream
    ↓
Prediction Agent → PREDICTIONS stream
    ↓
Explanation Worker → EXPLANATIONS stream
    ↓
API Gateway → Client
```

## Monitoring

Access NATS monitoring at:
- Health: http://localhost:8222/healthz
- Server Stats: http://localhost:8222/varz
- JetStream Stats: http://localhost:8222/jsz
- Connections: http://localhost:8222/connz
- Subscriptions: http://localhost:8222/subsz

## Implementation

Streams are created programmatically by each service using nats-py:

```python
from nats.js.api import StreamConfig, RetentionPolicy, StorageType

js = nc.jetstream()
await js.add_stream(
    StreamConfig(
        name="MARKET_DATA",
        subjects=["market.data.*"],
        max_age=7 * 24 * 60 * 60 * 1_000_000_000,  # 7 days
        max_bytes=10 * 1024 * 1024 * 1024,  # 10GB
        storage=StorageType.FILE,
        retention=RetentionPolicy.LIMITS,
    )
)
```

## Testing

Once services are deployed, verify streams:

```bash
# List all streams
curl -s http://localhost:8222/jsz | jq '.streams'

# Check specific stream
curl -s http://localhost:8222/jsz | jq '.stream_detail'
```
