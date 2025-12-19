# Redis Data Structures Documentation

**Project:** Riskee - Real-Time Price Prediction System
**Version:** 0.1.0
**Last Updated:** 2025-12-19

---

## Overview

This document defines all Redis data structures used in the Riskee system. Redis serves as our high-speed cache layer for:
- **Latest predictions** (sub-second access)
- **Feature vectors** (pre-computed ML features)
- **Earnings analysis** (LLM-generated explanations)
- **Prediction explanations** (RAG-enhanced reasoning)

**Key Principles:**
- All keys include TTL (Time To Live) to prevent memory bloat
- Use Redis Hashes for structured data
- Use prefixes for namespacing (`pred:`, `feat:`, etc.)
- Store timestamps in ISO 8601 format

---

## 1. Prediction Cache

### Key Pattern
```
pred:{ticker}
```

### Data Structure
**Type:** Hash

**Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `ticker` | String | Stock ticker symbol | `AAPL` |
| `prediction_time` | ISO 8601 | When prediction was made | `2025-12-19T10:30:00Z` |
| `predicted_price` | Decimal | Predicted price | `155.50` |
| `current_price` | Decimal | Current market price | `154.20` |
| `change_percent` | Decimal | Predicted change % | `0.84` |
| `confidence` | Decimal (0-1) | Model confidence | `0.87` |
| `model_type` | Enum | Model type | `normal` or `earnings` |
| `model_version` | String | Model version | `v1.0.0` |
| `created_at` | ISO 8601 | Cache creation time | `2025-12-19T10:30:05Z` |

**TTL:** 300 seconds (5 minutes)

### Example Commands

**Set prediction:**
```bash
HSET pred:AAPL ticker "AAPL" \
    prediction_time "2025-12-19T10:30:00Z" \
    predicted_price "155.50" \
    current_price "154.20" \
    change_percent "0.84" \
    confidence "0.87" \
    model_type "normal" \
    model_version "v1.0.0" \
    created_at "2025-12-19T10:30:05Z"

EXPIRE pred:AAPL 300
```

**Get prediction:**
```bash
HGETALL pred:AAPL
```

**Get specific field:**
```bash
HGET pred:AAPL predicted_price
```

**Check if exists:**
```bash
EXISTS pred:AAPL
```

### Python Example

```python
import redis
from datetime import datetime, timezone
from decimal import Decimal

redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Store prediction
prediction = {
    "ticker": "AAPL",
    "prediction_time": datetime.now(timezone.utc).isoformat(),
    "predicted_price": "155.50",
    "current_price": "154.20",
    "change_percent": "0.84",
    "confidence": "0.87",
    "model_type": "normal",
    "model_version": "v1.0.0",
    "created_at": datetime.now(timezone.utc).isoformat()
}

redis_client.hset(f"pred:{prediction['ticker']}", mapping=prediction)
redis_client.expire(f"pred:{prediction['ticker']}", 300)

# Retrieve prediction
cached_pred = redis_client.hgetall("pred:AAPL")
print(cached_pred)
```

---

## 2. Feature Vector Cache

### Key Pattern
```
features:{ticker}
```

### Data Structure
**Type:** Hash

**Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `ticker` | String | Stock ticker | `AAPL` |
| `features_json` | JSON String | Feature vector as JSON array | `[0.123, -0.456, ...]` |
| `feature_names` | JSON String | Feature names | `["price_ma_5", "volume_ratio", ...]` |
| `computed_at` | ISO 8601 | When features were computed | `2025-12-19T10:25:00Z` |
| `version` | String | Feature extraction version | `v1.0.0` |

**TTL:** 60 seconds (1 minute) - Features update frequently

### Example Commands

**Set features:**
```bash
HSET features:AAPL ticker "AAPL" \
    features_json "[0.123, -0.456, 0.789, 0.234, -0.123]" \
    feature_names "[\"price_ma_5\", \"volume_ratio\", \"rsi_14\", \"macd\", \"momentum\"]" \
    computed_at "2025-12-19T10:25:00Z" \
    version "v1.0.0"

EXPIRE features:AAPL 60
```

### Python Example

```python
import json

# Store features
features = {
    "ticker": "AAPL",
    "features_json": json.dumps([0.123, -0.456, 0.789, 0.234, -0.123]),
    "feature_names": json.dumps(["price_ma_5", "volume_ratio", "rsi_14", "macd", "momentum"]),
    "computed_at": datetime.now(timezone.utc).isoformat(),
    "version": "v1.0.0"
}

redis_client.hset(f"features:{features['ticker']}", mapping=features)
redis_client.expire(f"features:{features['ticker']}", 60)

# Retrieve and parse
cached_features = redis_client.hgetall("features:AAPL")
feature_vector = json.loads(cached_features["features_json"])
```

---

## 3. Earnings Analysis Cache

### Key Pattern
```
earnings_analysis:{ticker}:{date}
```

### Data Structure
**Type:** Hash

**Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `ticker` | String | Stock ticker | `AAPL` |
| `earnings_date` | Date (YYYY-MM-DD) | Earnings report date | `2025-12-19` |
| `estimated_eps` | Decimal | Estimated EPS | `1.25` |
| `actual_eps` | Decimal | Actual EPS | `1.32` |
| `surprise_percent` | Decimal | Earnings surprise % | `5.60` |
| `sentiment` | String | Sentiment analysis | `positive`, `negative`, `neutral` |
| `key_points` | JSON String | Key talking points | `["Revenue up 15%", "Margin improved"]` |
| `llm_summary` | Text | LLM-generated summary | `Apple exceeded expectations...` |
| `analyzed_at` | ISO 8601 | When analysis was done | `2025-12-19T11:00:00Z` |

**TTL:** 86400 seconds (24 hours) - Earnings don't change

### Example Commands

```bash
HSET earnings_analysis:AAPL:2025-12-19 ticker "AAPL" \
    earnings_date "2025-12-19" \
    estimated_eps "1.25" \
    actual_eps "1.32" \
    surprise_percent "5.60" \
    sentiment "positive" \
    key_points "[\"Revenue up 15%\", \"Margin improved\"]" \
    llm_summary "Apple exceeded expectations with strong iPhone sales..." \
    analyzed_at "2025-12-19T11:00:00Z"

EXPIRE earnings_analysis:AAPL:2025-12-19 86400
```

---

## 4. Prediction Explanation Cache

### Key Pattern
```
explanation:{ticker}:{timestamp}
```

### Data Structure
**Type:** Hash

**Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `ticker` | String | Stock ticker | `AAPL` |
| `prediction_id` | String | Unique prediction ID | `pred_12345` |
| `explanation_text` | Text | Human-readable explanation | `AAPL is predicted to rise due to...` |
| `rag_sources` | JSON String | RAG source documents | `[{"title": "News 1", "score": 0.92}]` |
| `model_factors` | JSON String | Model feature importance | `{"price_ma": 0.3, "volume": 0.2}` |
| `confidence_breakdown` | JSON String | Confidence components | `{"model": 0.85, "rag": 0.89}` |
| `generated_at` | ISO 8601 | When explanation was generated | `2025-12-19T10:35:00Z` |
| `llm_model` | String | LLM model used | `gemma3:4b` |

**TTL:** 600 seconds (10 minutes)

### Python Example

```python
# Store explanation
explanation = {
    "ticker": "AAPL",
    "prediction_id": "pred_12345",
    "explanation_text": "AAPL is predicted to rise 0.84% due to strong technical momentum and positive earnings sentiment.",
    "rag_sources": json.dumps([
        {"title": "AAPL beats Q4 estimates", "score": 0.92},
        {"title": "iPhone demand strong", "score": 0.88}
    ]),
    "model_factors": json.dumps({
        "price_ma_5": 0.30,
        "volume_ratio": 0.25,
        "rsi_14": 0.20
    }),
    "confidence_breakdown": json.dumps({
        "model_confidence": 0.87,
        "rag_relevance": 0.90,
        "overall": 0.87
    }),
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "llm_model": "gemma3:4b"
}

key = f"explanation:{explanation['ticker']}:{int(datetime.now().timestamp())}"
redis_client.hset(key, mapping=explanation)
redis_client.expire(key, 600)
```

---

## 5. Model Metadata Cache

### Key Pattern
```
model:{model_type}:active
```

### Data Structure
**Type:** Hash

**Fields:**
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `model_name` | String | Model identifier | `lstm_v1` |
| `model_version` | String | Version string | `v1.0.0` |
| `model_type` | Enum | Type of model | `normal` or `earnings` |
| `accuracy` | Decimal | Model accuracy | `0.8542` |
| `deployment_date` | ISO 8601 | When deployed | `2025-12-15T00:00:00Z` |
| `is_active` | Boolean | Active status | `true` |

**TTL:** 3600 seconds (1 hour)

### Example Commands

```bash
HSET model:normal:active model_name "lstm_v1" \
    model_version "v1.0.0" \
    model_type "normal" \
    accuracy "0.8542" \
    deployment_date "2025-12-15T00:00:00Z" \
    is_active "true"

EXPIRE model:normal:active 3600
```

---

## 6. Cache Statistics

### Key Pattern
```
stats:cache:{metric}
```

### Data Structure
**Type:** String (counter) or Sorted Set (for rankings)

**Metrics:**
- `stats:cache:hits` - Total cache hits (String counter)
- `stats:cache:misses` - Total cache misses (String counter)
- `stats:cache:predictions_count` - Number of cached predictions (String counter)
- `stats:tickers:most_requested` - Most requested tickers (Sorted Set)

**TTL:** 86400 seconds (24 hours) - Reset daily

### Example Commands

```bash
# Increment counters
INCR stats:cache:hits
INCR stats:cache:misses

# Track ticker requests (Sorted Set)
ZINCRBY stats:tickers:most_requested 1 "AAPL"
ZINCRBY stats:tickers:most_requested 1 "GOOGL"

# Get top 10 tickers
ZREVRANGE stats:tickers:most_requested 0 9 WITHSCORES

# Calculate hit rate
hits=$(redis-cli GET stats:cache:hits)
misses=$(redis-cli GET stats:cache:misses)
echo "Hit rate: $(echo "scale=2; $hits / ($hits + $misses) * 100" | bc)%"
```

---

## Best Practices

### 1. Always Set TTL
```python
# ❌ BAD - No TTL, memory leak
redis_client.hset("pred:AAPL", mapping=data)

# ✅ GOOD - With TTL
redis_client.hset("pred:AAPL", mapping=data)
redis_client.expire("pred:AAPL", 300)
```

### 2. Use Pipelines for Batch Operations
```python
# ✅ GOOD - Use pipeline for multiple commands
pipe = redis_client.pipeline()
pipe.hset("pred:AAPL", mapping=prediction)
pipe.expire("pred:AAPL", 300)
pipe.incr("stats:cache:predictions_count")
pipe.execute()
```

### 3. Handle Missing Keys Gracefully
```python
# ✅ GOOD - Check before using
cached = redis_client.hgetall("pred:AAPL")
if cached:
    return cached
else:
    # Fetch from database, then cache
    prediction = fetch_from_db("AAPL")
    redis_client.hset("pred:AAPL", mapping=prediction)
    redis_client.expire("pred:AAPL", 300)
    return prediction
```

### 4. Monitor Memory Usage
```bash
# Check memory info
redis-cli INFO memory

# Check key count
redis-cli DBSIZE

# Find largest keys
redis-cli --bigkeys
```

---

## Migration from Direct Queries

**Before (slow - database query):**
```python
prediction = db.query("SELECT * FROM predictions WHERE ticker = 'AAPL' ORDER BY prediction_time DESC LIMIT 1")
```

**After (fast - Redis cache):**
```python
# Try cache first
prediction = redis_client.hgetall("pred:AAPL")

# Cache miss - fetch from DB and cache
if not prediction:
    prediction = db.query("SELECT * FROM predictions WHERE ticker = 'AAPL' ORDER BY prediction_time DESC LIMIT 1")
    redis_client.hset("pred:AAPL", mapping=prediction)
    redis_client.expire("pred:AAPL", 300)
```

**Performance Improvement:** 100x faster (< 1ms vs 100ms+)

---

## Troubleshooting

### Issue: High Memory Usage

**Check:**
```bash
redis-cli INFO memory
redis-cli --bigkeys
```

**Solution:** Ensure TTLs are set correctly

### Issue: Cache Misses

**Check hit rate:**
```python
hits = int(redis_client.get("stats:cache:hits") or 0)
misses = int(redis_client.get("stats:cache:misses") or 0)
hit_rate = hits / (hits + misses) if (hits + misses) > 0 else 0
print(f"Hit rate: {hit_rate:.2%}")
```

**Target:** > 80% hit rate

---

**End of Redis Data Structures Documentation**
