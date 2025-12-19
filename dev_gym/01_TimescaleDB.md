# TimescaleDB Tutorial - Developer Gym

**What is it?** PostgreSQL extension optimized for time-series data
**Why we use it?** Store predictions, metrics, and market data efficiently
**In this project:** 4 tables, 3 hypertables, automatic compression/retention

---

## 🎯 Quick Concept

TimescaleDB = PostgreSQL + Time-Series Superpowers

**Normal PostgreSQL:**
- Stores data in regular tables
- Queries slow as data grows
- No automatic data lifecycle

**TimescaleDB:**
- Automatically partitions data by time (chunks)
- Compresses old data automatically
- Deletes very old data automatically
- Query performance stays fast even with billions of rows

---

## 🏗️ Core Concepts

### 1. Hypertable
A "super table" that looks like one table but is automatically split into chunks.

```sql
-- Create regular table
CREATE TABLE predictions (
    time TIMESTAMPTZ NOT NULL,
    ticker VARCHAR(10),
    price DECIMAL(15,4)
);

-- Convert to hypertable (magic happens!)
SELECT create_hypertable('predictions', 'time');

-- Now it automatically creates chunks:
-- predictions_chunk_1 (data from Jan 1-2)
-- predictions_chunk_2 (data from Jan 3-4)
-- predictions_chunk_3 (data from Jan 5-6)
-- ... and so on
```

**Benefits:**
- Old chunks get compressed (90% size reduction)
- Very old chunks get deleted automatically
- Queries only scan relevant chunks (fast!)

### 2. Compression
Automatically compress old data to save 90% disk space.

```sql
-- Enable compression
ALTER TABLE predictions SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'ticker'
);

-- Compress chunks older than 7 days
SELECT add_compression_policy('predictions', INTERVAL '7 days');
```

**Result:**
- 7 days of data: 10 GB (uncompressed)
- After 7 days: 1 GB (compressed)
- Queries still work normally!

### 3. Retention
Automatically delete very old data.

```sql
-- Delete chunks older than 90 days
SELECT add_retention_policy('predictions', INTERVAL '90 days');
```

**Result:**
- Data older than 90 days automatically deleted
- No manual cleanup needed
- Disk space stays constant

---

## 💻 Hands-On Examples

### Connect to Database

```bash
# Using Docker
docker exec -it riskee_timescaledb psql -U postgres -d riskee

# From host (if psql installed)
psql -h localhost -U postgres -d riskee
# Password: riskee123
```

### Example 1: Insert Predictions

```sql
-- Insert a prediction
INSERT INTO predictions (
    ticker,
    prediction_time,
    target_time,
    predicted_price,
    confidence_score,
    current_price,
    model_version,
    agent_type
) VALUES (
    'AAPL',
    NOW(),
    NOW() + INTERVAL '1 day',
    155.50,
    0.87,
    154.20,
    'v1.0',
    'normal'
);

-- Insert multiple predictions
INSERT INTO predictions (ticker, prediction_time, target_time, predicted_price, confidence_score, current_price, model_version, agent_type)
VALUES
    ('GOOGL', NOW(), NOW() + INTERVAL '1 day', 2850.00, 0.82, 2845.30, 'v1.0', 'normal'),
    ('MSFT', NOW(), NOW() + INTERVAL '1 day', 380.75, 0.91, 378.50, 'v1.0', 'normal'),
    ('TSLA', NOW(), NOW() + INTERVAL '1 day', 245.30, 0.78, 242.10, 'v1.0', 'earnings');
```

### Example 2: Query Recent Predictions

```sql
-- Get today's predictions
SELECT
    ticker,
    predicted_price,
    confidence_score,
    prediction_time
FROM predictions
WHERE prediction_time >= NOW() - INTERVAL '1 day'
ORDER BY prediction_time DESC;

-- Get predictions for specific ticker
SELECT *
FROM predictions
WHERE ticker = 'AAPL'
  AND prediction_time >= NOW() - INTERVAL '7 days'
ORDER BY prediction_time DESC
LIMIT 10;
```

### Example 3: Time-Series Analysis

```sql
-- Average prediction by hour (last 24 hours)
SELECT
    time_bucket('1 hour', prediction_time) AS hour,
    ticker,
    AVG(predicted_price) as avg_predicted_price,
    AVG(confidence_score) as avg_confidence
FROM predictions
WHERE prediction_time >= NOW() - INTERVAL '24 hours'
GROUP BY hour, ticker
ORDER BY hour DESC, ticker;

-- Count predictions per ticker per day
SELECT
    time_bucket('1 day', prediction_time) AS day,
    ticker,
    COUNT(*) as prediction_count,
    AVG(confidence_score) as avg_confidence
FROM predictions
WHERE prediction_time >= NOW() - INTERVAL '30 days'
GROUP BY day, ticker
ORDER BY day DESC, ticker;
```

### Example 4: Using Materialized View

```sql
-- Our pre-created view: latest_predictions
-- Shows the most recent prediction for each ticker

SELECT * FROM latest_predictions;

-- Result:
-- ticker | prediction_time | predicted_price | confidence_score
-- AAPL   | 2025-12-17 ...  | 155.50         | 0.87
-- GOOGL  | 2025-12-17 ...  | 2850.00        | 0.82
-- MSFT   | 2025-12-17 ...  | 380.75         | 0.91

-- Refresh the view (if needed)
REFRESH MATERIALIZED VIEW latest_predictions;
```

### Example 5: Continuous Aggregates

```sql
-- Our pre-created hourly aggregate: prediction_summary_hourly
-- Automatically maintained by TimescaleDB

SELECT
    bucket,
    ticker,
    prediction_count,
    avg_confidence,
    avg_price_change_pct
FROM prediction_summary_hourly
WHERE bucket >= NOW() - INTERVAL '24 hours'
ORDER BY bucket DESC;

-- This query is FAST because data is pre-aggregated!
```

---

## 🔍 Useful Queries

### Check Hypertables

```sql
-- List all hypertables
SELECT * FROM timescaledb_information.hypertables;

-- View hypertable details
SELECT * FROM timescaledb_information.hypertables
WHERE hypertable_name = 'predictions';
```

### Check Chunks

```sql
-- List all chunks for a hypertable
SELECT
    chunk_name,
    range_start,
    range_end,
    is_compressed
FROM timescaledb_information.chunks
WHERE hypertable_name = 'predictions'
ORDER BY range_start DESC
LIMIT 10;
```

### Check Compression

```sql
-- Compression stats
SELECT
    hypertable_name,
    compression_enabled,
    compress_interval
FROM timescaledb_information.compression_settings;

-- See compression ratio
SELECT
    pg_size_pretty(before_compression_total_bytes) as before,
    pg_size_pretty(after_compression_total_bytes) as after,
    100 - (after_compression_total_bytes::float / before_compression_total_bytes::float * 100) as savings_percent
FROM timescaledb_information.compressed_chunk_stats;
```

### Check Retention Policies

```sql
-- List retention policies
SELECT * FROM timescaledb_information.jobs
WHERE proc_name = 'policy_retention';
```

---

## 🎓 Best Practices for Our Project

### 1. Always Use time_bucket for Aggregations

```sql
-- ❌ BAD: Slow for large datasets
SELECT DATE(prediction_time), COUNT(*)
FROM predictions
GROUP BY DATE(prediction_time);

-- ✅ GOOD: Optimized for TimescaleDB
SELECT time_bucket('1 day', prediction_time), COUNT(*)
FROM predictions
GROUP BY 1;
```

### 2. Filter by Time First

```sql
-- ❌ BAD: Scans all chunks
SELECT * FROM predictions WHERE ticker = 'AAPL';

-- ✅ GOOD: Only scans recent chunks
SELECT * FROM predictions
WHERE prediction_time >= NOW() - INTERVAL '7 days'
  AND ticker = 'AAPL';
```

### 3. Use Continuous Aggregates for Dashboards

```sql
-- ❌ BAD: Calculate on every request
SELECT time_bucket('1 hour', prediction_time), AVG(confidence_score)
FROM predictions
WHERE prediction_time >= NOW() - INTERVAL '30 days'
GROUP BY 1;

-- ✅ GOOD: Use pre-calculated aggregate
SELECT bucket, avg_confidence
FROM prediction_summary_hourly
WHERE bucket >= NOW() - INTERVAL '30 days';
```

---

## 🐛 Common Issues & Solutions

### Issue: "ERROR: function create_hypertable does not exist"

**Solution:**
```sql
-- TimescaleDB extension not loaded
CREATE EXTENSION IF NOT EXISTS timescaledb;
```

### Issue: Slow queries

**Solution:**
```sql
-- Check if you're filtering by time
EXPLAIN ANALYZE
SELECT * FROM predictions
WHERE ticker = 'AAPL'
  AND prediction_time >= NOW() - INTERVAL '7 days';

-- Should show "Chunks excluded: XX"
```

### Issue: Disk space growing

**Solution:**
```sql
-- Check if compression is working
SELECT * FROM timescaledb_information.compression_settings;

-- Manually compress a chunk
SELECT compress_chunk('_timescaledb_internal._hyper_1_1_chunk');
```

---

## 📚 Learn More

**Official Docs:**
- TimescaleDB Docs: https://docs.timescale.com/
- Time Buckets: https://docs.timescale.com/api/latest/hyperfunctions/time_bucket/
- Compression: https://docs.timescale.com/use-timescale/latest/compression/

**Our Schema File:**
- `scripts/db/init/01_init_schema.sql` - Complete schema definition

**Practice Commands:**
```bash
# Connect and explore
docker exec -it riskee_timescaledb psql -U postgres -d riskee

# List all tables
\dt

# Describe predictions table
\d predictions

# View hypertables
SELECT * FROM timescaledb_information.hypertables;
```

---

## ✅ Quick Checklist

- [ ] Understand what a hypertable is
- [ ] Know how to insert time-series data
- [ ] Can query with time filters
- [ ] Understand time_bucket() function
- [ ] Know compression saves disk space
- [ ] Understand retention deletes old data
- [ ] Can use materialized views
- [ ] Know how to check chunk statistics

**Next:** Learn Redis for caching! → [02_Redis.md](02_Redis.md)
