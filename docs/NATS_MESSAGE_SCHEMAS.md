# NATS Message Schemas Documentation

**Project:** Riskee - Real-Time Price Prediction System
**Version:** 0.1.0
**Last Updated:** 2025-12-19

---

## Overview

This document defines all message schemas used in the NATS JetStream messaging system. All messages use JSON format and follow a consistent structure for correlation, tracing, and error handling.

**Message Flow:**
```
Market Data → data.market.* → Ingestion Service
                ↓
            Feature Extraction
                ↓
         job.predict.* → ML Service
                ↓
     event.prediction.* → Cache + Database
                ↓
         thought.* → LLM Service
                ↓
       Explanation → Client
```

---

## Common Fields

All messages include these standard fields:

```json
{
  "message_id": "uuid-v4",           // Unique message identifier
  "correlation_id": "uuid-v4",       // Request correlation ID
  "timestamp": "ISO 8601 datetime",  // Message creation time
  "version": "1.0",                  // Schema version
  "source": "service-name",          // Originating service
  "payload": {}                      // Message-specific data
}
```

---

## 1. Market Data Messages

### Subject: `data.market.quote`

**Purpose:** Real-time market quotes

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440001",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440002",
  "timestamp": "2025-12-19T10:30:00.123456Z",
  "version": "1.0",
  "source": "market-ingestion",
  "payload": {
    "ticker": "AAPL",
    "timestamp": "2025-12-19T10:30:00Z",
    "open": 154.00,
    "high": 154.50,
    "low": 153.80,
    "close": 154.20,
    "volume": 1000000,
    "bid": 154.18,
    "ask": 154.22,
    "last_trade_price": 154.20
  }
}
```

**Validation Rules:**
- `ticker`: 1-10 uppercase alphanumeric characters
- `timestamp`: ISO 8601 format
- Prices: Positive decimals with max 4 decimal places
- `volume`: Positive integer

**Example (Python):**
```python
from datetime import datetime, timezone
import uuid
import json

message = {
    "message_id": str(uuid.uuid4()),
    "correlation_id": str(uuid.uuid4()),
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "version": "1.0",
    "source": "market-ingestion",
    "payload": {
        "ticker": "AAPL",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "open": 154.00,
        "high": 154.50,
        "low": 153.80,
        "close": 154.20,
        "volume": 1000000,
        "bid": 154.18,
        "ask": 154.22,
        "last_trade_price": 154.20
    }
}

# Publish to NATS
await nc.publish("data.market.quote", json.dumps(message).encode())
```

---

## 2. Prediction Job Messages

### Subject: `job.predict.normal`

**Purpose:** Request normal (non-earnings) price prediction

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440003",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440004",
  "timestamp": "2025-12-19T10:30:05Z",
  "version": "1.0",
  "source": "api-server",
  "payload": {
    "ticker": "AAPL",
    "model_version": "v1.0.0",
    "features": {
      "price_ma_5": 0.123,
      "volume_ratio": -0.456,
      "rsi_14": 0.789,
      "macd": 0.234,
      "momentum": -0.123
    },
    "priority": "normal"
  }
}
```

**Validation Rules:**
- `ticker`: 1-10 uppercase alphanumeric
- `model_version`: Semantic version (e.g., v1.0.0)
- `features`: Dictionary with numeric values
- `priority`: Enum("low", "normal", "high")

---

### Subject: `job.predict.earnings`

**Purpose:** Request earnings-day price prediction

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440005",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440006",
  "timestamp": "2025-12-19T10:30:05Z",
  "version": "1.0",
  "source": "api-server",
  "payload": {
    "ticker": "AAPL",
    "model_version": "v1.0.0",
    "earnings_date": "2025-12-19",
    "estimated_eps": 1.25,
    "features": {
      "price_ma_5": 0.123,
      "volume_ratio": -0.456,
      "rsi_14": 0.789,
      "macd": 0.234,
      "momentum": -0.123,
      "earnings_surprise_history": [0.05, 0.03, -0.02]
    },
    "priority": "high"
  }
}
```

**Additional Fields:**
- `earnings_date`: Date in YYYY-MM-DD format
- `estimated_eps`: Estimated earnings per share (decimal)

---

## 3. Prediction Event Messages

### Subject: `event.prediction.updated`

**Purpose:** Notify that a prediction has been created or updated

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440007",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440008",
  "timestamp": "2025-12-19T10:30:10Z",
  "version": "1.0",
  "source": "prediction-service",
  "payload": {
    "prediction_id": "pred_12345",
    "ticker": "AAPL",
    "prediction_time": "2025-12-19T10:30:00Z",
    "predicted_price": 155.50,
    "current_price": 154.20,
    "change_percent": 0.84,
    "confidence": 0.87,
    "model_type": "normal",
    "model_version": "v1.0.0",
    "features_used": ["price_ma_5", "volume_ratio", "rsi_14"]
  }
}
```

**Validation Rules:**
- `prediction_id`: Unique identifier (string, prefix "pred_")
- `confidence`: Decimal 0.0 to 1.0
- `model_type`: Enum("normal", "earnings")
- Prices: Positive decimals

---

### Subject: `event.prediction.failed`

**Purpose:** Notify that a prediction job failed

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440009",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440010",
  "timestamp": "2025-12-19T10:30:10Z",
  "version": "1.0",
  "source": "prediction-service",
  "payload": {
    "ticker": "AAPL",
    "model_type": "normal",
    "error_code": "INSUFFICIENT_DATA",
    "error_message": "Not enough historical data for prediction",
    "retry_count": 2,
    "max_retries": 3
  }
}
```

**Error Codes:**
- `INSUFFICIENT_DATA` - Not enough historical data
- `MODEL_ERROR` - Model inference failed
- `FEATURE_ERROR` - Feature extraction failed
- `TIMEOUT` - Prediction timed out
- `UNKNOWN` - Unknown error

---

## 4. LLM Thought Messages

### Subject: `thought.prediction.explain`

**Purpose:** Request explanation for a prediction

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440011",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440012",
  "timestamp": "2025-12-19T10:30:15Z",
  "version": "1.0",
  "source": "explanation-service",
  "payload": {
    "prediction_id": "pred_12345",
    "ticker": "AAPL",
    "predicted_price": 155.50,
    "current_price": 154.20,
    "confidence": 0.87,
    "model_factors": {
      "price_ma_5": 0.30,
      "volume_ratio": 0.25,
      "rsi_14": 0.20
    },
    "rag_context": [
      {
        "title": "AAPL beats Q4 estimates",
        "snippet": "Apple exceeded expectations...",
        "relevance": 0.92
      }
    ]
  }
}
```

---

### Subject: `thought.prediction.explained`

**Purpose:** Completed explanation for a prediction

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440013",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440014",
  "timestamp": "2025-12-19T10:30:20Z",
  "version": "1.0",
  "source": "llm-service",
  "payload": {
    "prediction_id": "pred_12345",
    "ticker": "AAPL",
    "explanation_text": "AAPL is predicted to rise 0.84% due to strong technical momentum...",
    "llm_model": "gemma3:4b",
    "generation_time_ms": 21100,
    "confidence_breakdown": {
      "model_confidence": 0.87,
      "rag_relevance": 0.90,
      "overall": 0.87
    }
  }
}
```

---

## 5. Model Metrics Messages

### Subject: `metrics.model.accuracy`

**Purpose:** Report model accuracy metrics

**Message Schema:**
```json
{
  "message_id": "550e8400-e29b-41d4-a716-446655440015",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440016",
  "timestamp": "2025-12-19T11:00:00Z",
  "version": "1.0",
  "source": "monitoring-service",
  "payload": {
    "model_name": "lstm_v1",
    "model_version": "v1.0.0",
    "model_type": "normal",
    "time_window": "1h",
    "metrics": {
      "accuracy": 0.8542,
      "precision": 0.8231,
      "recall": 0.8103,
      "f1_score": 0.8166,
      "mae": 0.0234,
      "rmse": 0.0456
    },
    "sample_count": 1523
  }
}
```

---

## Message Validation

### JSON Schema Example (data.market.quote)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["message_id", "correlation_id", "timestamp", "version", "source", "payload"],
  "properties": {
    "message_id": {
      "type": "string",
      "format": "uuid"
    },
    "correlation_id": {
      "type": "string",
      "format": "uuid"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time"
    },
    "version": {
      "type": "string",
      "pattern": "^[0-9]+\\.[0-9]+$"
    },
    "source": {
      "type": "string",
      "minLength": 1
    },
    "payload": {
      "type": "object",
      "required": ["ticker", "timestamp", "open", "high", "low", "close", "volume"],
      "properties": {
        "ticker": {
          "type": "string",
          "pattern": "^[A-Z0-9]{1,10}$"
        },
        "timestamp": {
          "type": "string",
          "format": "date-time"
        },
        "open": {
          "type": "number",
          "minimum": 0
        },
        "high": {
          "type": "number",
          "minimum": 0
        },
        "low": {
          "type": "number",
          "minimum": 0
        },
        "close": {
          "type": "number",
          "minimum": 0
        },
        "volume": {
          "type": "integer",
          "minimum": 0
        }
      }
    }
  }
}
```

---

## Python Validation Example

```python
from jsonschema import validate, ValidationError
import json

# Load schema
with open("schemas/market_quote.json") as f:
    schema = json.load(f)

# Validate message
try:
    validate(instance=message, schema=schema)
    print("[OK] Message valid")
except ValidationError as e:
    print(f"[ERROR] Validation failed: {e.message}")
```

---

## Testing Messages

### Using NATS CLI Tools

**Publish test message:**
```bash
python scripts/nats_publish.py data.market.quote '{"message_id":"test-123","correlation_id":"test-456","timestamp":"2025-12-19T10:30:00Z","version":"1.0","source":"test","payload":{"ticker":"AAPL","timestamp":"2025-12-19T10:30:00Z","open":154.00,"high":154.50,"low":153.80,"close":154.20,"volume":1000000}}'
```

**Subscribe to messages:**
```bash
python scripts/nats_subscribe.py 'data.market.*'
```

---

## Best Practices

1. **Always include correlation_id** for request tracing
2. **Use ISO 8601 timestamps** in UTC timezone
3. **Validate messages** before publishing
4. **Handle errors gracefully** with proper error codes
5. **Version schemas** and support backward compatibility
6. **Log message IDs** for debugging

---

**End of NATS Message Schemas Documentation**
