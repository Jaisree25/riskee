# Redis Tutorial - Developer Gym

**What is it?** In-memory data store (think: super-fast dictionary in RAM)
**Why we use it?** Cache expensive calculations, store temporary data
**In this project:** Feature caching, session storage, rate limiting

---

## 🎯 Quick Concept

Redis = Dictionary that lives in RAM (Memory)

**Why use Redis?**
- Database query: 10-100ms
- Redis query: 0.1-1ms (100x faster!)
- Perfect for frequently accessed data

**Trade-off:**
- RAM is expensive (limited size)
- Data can be lost if server crashes (we use AOF persistence to prevent this)

---

## 🏗️ Core Concepts

### 1. Data Structures

Redis is more than key-value storage. It has 5 main data types:

```
STRING  → "key": "value"
HASH    → "user:1": {"name": "John", "age": 30}
LIST    → "queue": [item1, item2, item3]
SET     → "tags": {python, redis, docker}
ZSET    → "scores": {player1: 100, player2: 95}
```

### 2. Keys

Keys are like file paths - use colons for namespacing:

```
user:1001
user:1001:sessions
prediction:AAPL:latest
features:AAPL:20251217
cache:model:v1:AAPL
```

### 3. Expiration (TTL)

Data can automatically expire:

```bash
# Store for 5 minutes
SET session:abc123 "user_data" EX 300

# After 300 seconds, key disappears automatically
```

---

## 💻 Hands-On Examples

### Connect to Redis

```bash
# Using Docker
docker exec -it riskee_redis redis-cli

# From host (if redis-cli installed)
redis-cli -h localhost -p 6379
```

### Example 1: Strings (Simple Key-Value)

```bash
# Set a value
SET prediction:AAPL:latest "155.50"

# Get a value
GET prediction:AAPL:latest
# Returns: "155.50"

# Set with expiration (5 minutes)
SETEX cache:model:AAPL 300 "cached_prediction_data"

# Check time to live
TTL cache:model:AAPL
# Returns: 295 (seconds remaining)

# Increment a counter
INCR api:requests:count
# Returns: 1
INCR api:requests:count
# Returns: 2
```

**Use Cases:**
- Cache expensive calculations
- Store session tokens
- Rate limiting counters
- Feature flags

### Example 2: Hashes (Objects/Dictionaries)

```bash
# Store AAPL features
HSET features:AAPL:latest open 154.20 high 156.10 low 153.90 close 155.50 volume 50000000

# Get one field
HGET features:AAPL:latest close
# Returns: "155.50"

# Get all fields
HGETALL features:AAPL:latest
# Returns:
# 1) "open"
# 2) "154.20"
# 3) "high"
# 4) "156.10"
# ...

# Get multiple fields
HMGET features:AAPL:latest open close
# Returns:
# 1) "154.20"
# 2) "155.50"

# Check if field exists
HEXISTS features:AAPL:latest volume
# Returns: 1 (true)

# Delete a field
HDEL features:AAPL:latest volume
```

**Use Cases:**
- Store structured data (user profiles, features)
- Faster than JSON strings
- Can update individual fields

### Example 3: Lists (Queues/Stacks)

```bash
# Push to queue (right side)
RPUSH prediction:queue AAPL GOOGL MSFT
# Returns: 3

# Pop from queue (left side) - FIFO
LPOP prediction:queue
# Returns: "AAPL"

# View queue without removing
LRANGE prediction:queue 0 -1
# Returns:
# 1) "GOOGL"
# 2) "MSFT"

# Get queue length
LLEN prediction:queue
# Returns: 2

# Push to left (stack behavior)
LPUSH recent:predictions "AAPL:155.50"
LPUSH recent:predictions "GOOGL:2850.00"

# Pop from left - LIFO (stack)
LPOP recent:predictions
# Returns: "GOOGL:2850.00"
```

**Use Cases:**
- Task queues (background jobs)
- Recent items lists
- Activity feeds
- Message queues

### Example 4: Sets (Unique Collections)

```bash
# Add items to set
SADD active:tickers AAPL GOOGL MSFT
SADD active:tickers AAPL  # Ignored (already exists)

# Check if member exists
SISMEMBER active:tickers AAPL
# Returns: 1 (true)

# Get all members
SMEMBERS active:tickers
# Returns:
# 1) "AAPL"
# 2) "GOOGL"
# 3) "MSFT"

# Count members
SCARD active:tickers
# Returns: 3

# Remove member
SREM active:tickers MSFT

# Set operations
SADD tech:stocks AAPL GOOGL MSFT
SADD watchlist AAPL TSLA

# Intersection (common items)
SINTER tech:stocks watchlist
# Returns: "AAPL"

# Union (all items)
SUNION tech:stocks watchlist
# Returns: AAPL, GOOGL, MSFT, TSLA
```

**Use Cases:**
- Tags, categories
- Unique visitors
- Real-time analytics
- Deduplication

### Example 5: Sorted Sets (Rankings/Leaderboards)

```bash
# Add items with scores
ZADD model:accuracy 0.87 "model_v1" 0.92 "model_v2" 0.85 "model_v3"

# Get top models (highest score)
ZREVRANGE model:accuracy 0 2 WITHSCORES
# Returns:
# 1) "model_v2"
# 2) "0.92"
# 3) "model_v1"
# 4) "0.87"
# 5) "model_v3"
# 6) "0.85"

# Get rank
ZREVRANK model:accuracy "model_v2"
# Returns: 0 (first place)

# Get score
ZSCORE model:accuracy "model_v1"
# Returns: "0.87"

# Count items in score range
ZCOUNT model:accuracy 0.85 0.90
# Returns: 2
```

**Use Cases:**
- Leaderboards
- Priority queues
- Time-based sorting
- Top-K items

---

## 🎓 Best Practices for Our Project

### 1. Cache Expensive Predictions

```python
import redis
import json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Cache prediction result
def get_prediction(ticker):
    # Check cache first
    cache_key = f"prediction:{ticker}:latest"
    cached = r.get(cache_key)

    if cached:
        print("Cache HIT!")
        return json.loads(cached)

    print("Cache MISS - calculating...")
    # Expensive ML prediction
    prediction = run_ml_model(ticker)

    # Store in cache for 5 minutes
    r.setex(cache_key, 300, json.dumps(prediction))

    return prediction
```

### 2. Store Features as Hash

```python
# Store latest market features
features = {
    'open': 154.20,
    'high': 156.10,
    'low': 153.90,
    'close': 155.50,
    'volume': 50000000
}

r.hset('features:AAPL:latest', mapping=features)

# Retrieve
close_price = r.hget('features:AAPL:latest', 'close')
all_features = r.hgetall('features:AAPL:latest')
```

### 3. Rate Limiting

```python
def check_rate_limit(user_id, limit=100, window=60):
    """Allow 100 requests per minute"""
    key = f"ratelimit:{user_id}"

    # Increment counter
    count = r.incr(key)

    # Set expiration on first request
    if count == 1:
        r.expire(key, window)

    # Check if over limit
    if count > limit:
        return False, f"Rate limit exceeded. Try again in {r.ttl(key)} seconds"

    return True, f"Requests remaining: {limit - count}"
```

### 4. Job Queue

```python
# Producer: Add jobs to queue
def queue_prediction_job(ticker):
    job = json.dumps({'ticker': ticker, 'timestamp': time.time()})
    r.rpush('jobs:predictions', job)
    print(f"Queued: {ticker}")

# Consumer: Process jobs
def process_predictions():
    while True:
        # Block until job available (timeout 1 second)
        job = r.blpop('jobs:predictions', timeout=1)

        if job:
            _, job_data = job
            data = json.loads(job_data)
            process_prediction(data['ticker'])
```

---

## 🔍 Useful Commands

### Management

```bash
# Show all keys (use carefully in production!)
KEYS *

# Find keys by pattern
KEYS prediction:*
KEYS features:AAPL:*

# Get key type
TYPE prediction:AAPL:latest
# Returns: "string" or "hash" or "list" etc.

# Check if key exists
EXISTS prediction:AAPL:latest
# Returns: 1 (exists) or 0 (doesn't exist)

# Delete key
DEL prediction:AAPL:latest

# Delete all keys (DANGEROUS!)
FLUSHDB
```

### Monitoring

```bash
# Server info
INFO

# Memory usage
INFO memory

# Connected clients
INFO clients

# Keyspace statistics
INFO keyspace

# Monitor real-time commands (debugging)
MONITOR
```

### Performance

```bash
# Test latency
redis-cli --latency

# Benchmark
redis-benchmark -q -n 10000
```

---

## 🐛 Common Issues & Solutions

### Issue: "Out of Memory"

**Solution:**
```bash
# Check memory usage
INFO memory

# Set max memory (in redis.conf or runtime)
CONFIG SET maxmemory 256mb

# Set eviction policy (remove least recently used)
CONFIG SET maxmemory-policy allkeys-lru
```

### Issue: Keys never expiring

**Solution:**
```bash
# Check TTL
TTL my:key
# -1 = no expiration
# -2 = key doesn't exist
# positive number = seconds until expiration

# Set expiration on existing key
EXPIRE my:key 300
```

### Issue: Slow commands

**Solution:**
```bash
# Check slow log
SLOWLOG GET 10

# Avoid KEYS command in production (use SCAN instead)
# ❌ BAD
KEYS *

# ✅ GOOD
SCAN 0 MATCH prediction:* COUNT 100
```

---

## 🎯 Real-World Example: Feature Store

Complete example using our project's pattern:

```python
import redis
import json
from datetime import datetime, timedelta

class FeatureStore:
    def __init__(self):
        self.redis = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True
        )

    def store_features(self, ticker, features, ttl=300):
        """Store features with 5-minute expiration"""
        key = f"features:{ticker}:latest"
        self.redis.hset(key, mapping=features)
        self.redis.expire(key, ttl)

    def get_features(self, ticker):
        """Get cached features"""
        key = f"features:{ticker}:latest"
        return self.redis.hgetall(key)

    def cache_prediction(self, ticker, prediction, confidence):
        """Cache prediction result"""
        data = {
            'prediction': prediction,
            'confidence': confidence,
            'timestamp': datetime.now().isoformat()
        }
        key = f"prediction:{ticker}:latest"
        self.redis.setex(key, 60, json.dumps(data))

    def get_cached_prediction(self, ticker):
        """Get cached prediction"""
        key = f"prediction:{ticker}:latest"
        data = self.redis.get(key)
        return json.loads(data) if data else None

# Usage
fs = FeatureStore()

# Store features
fs.store_features('AAPL', {
    'open': 154.20,
    'close': 155.50,
    'volume': 50000000
})

# Get features
features = fs.get_features('AAPL')
print(features)  # {'open': '154.20', 'close': '155.50', ...}

# Cache prediction
fs.cache_prediction('AAPL', 156.75, 0.87)

# Get cached prediction
pred = fs.get_cached_prediction('AAPL')
print(pred)  # {'prediction': 156.75, 'confidence': 0.87, ...}
```

---

## 📚 Learn More

**Official Docs:**
- Redis Commands: https://redis.io/commands
- Data Types: https://redis.io/topics/data-types
- redis-py: https://redis-py.readthedocs.io/

**Our Setup:**
- Port: 6379
- Host: localhost (or `redis` in Docker network)
- Persistence: AOF (Append-Only File) enabled

**Practice:**
```bash
# Connect
docker exec -it riskee_redis redis-cli

# Try each data type
SET mykey "hello"
HSET user:1 name "John" age 30
LPUSH mylist item1 item2
SADD myset item1 item2
ZADD scores 100 player1 95 player2
```

---

## ✅ Quick Checklist

- [ ] Understand 5 data types (String, Hash, List, Set, Sorted Set)
- [ ] Know when to use each data type
- [ ] Can set keys with expiration (TTL)
- [ ] Understand caching pattern (check cache → cache miss → compute → store)
- [ ] Know how to use HGETALL for objects
- [ ] Can create simple rate limiter
- [ ] Understand why Redis is fast (in-memory)
- [ ] Know the trade-offs (speed vs persistence)

**Next:** Learn NATS for messaging! → [03_NATS.md](03_NATS.md)
