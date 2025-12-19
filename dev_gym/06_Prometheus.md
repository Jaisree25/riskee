# Prometheus Tutorial - Developer Gym

**What is it?** Time-series metrics database and monitoring system
**Why we use it?** Track system health, performance, errors over time
**In this project:** Monitor API requests, prediction latency, model accuracy, service health

---

## 🎯 Quick Concept

Prometheus = Health Monitor for Your System

**Without Prometheus:**
- "Is the system slow?" → Check logs manually
- "How many errors today?" → Count by hand
- "When did it break?" → No idea

**With Prometheus:**
- Auto-collects metrics every 15 seconds
- Stores in time-series database
- Alerts when something's wrong
- Visualize in Grafana

---

## 🏗️ Core Concepts

### 1. Metrics

4 types:

```python
# Counter (only goes up)
api_requests_total = 1523  # Total requests since start
errors_total = 42          # Total errors

# Gauge (can go up or down)
cpu_usage_percent = 45.2
active_predictions = 8
memory_used_bytes = 1024000

# Histogram (distribution)
request_duration_seconds = {0.1s, 0.5s, 1.2s, 0.3s, ...}
# → avg: 0.5s, p95: 1.0s, p99: 1.2s

# Summary (like histogram but client-side)
prediction_confidence = {0.87, 0.92, 0.78, ...}
# → avg: 0.86, p50: 0.87, p90: 0.92
```

### 2. Labels

Add dimensions to metrics:

```python
# Without labels (limited)
predictions_total = 1523

# With labels (powerful!)
predictions_total{ticker="AAPL", model="normal"} = 523
predictions_total{ticker="AAPL", model="earnings"} = 100
predictions_total{ticker="GOOGL", model="normal"} = 900

# Now you can ask:
# - How many AAPL predictions? (623)
# - How many normal model predictions? (1423)
# - How many GOOGL earnings predictions? (0)
```

### 3. Scraping

Prometheus pulls metrics from your services:

```
Every 15 seconds:
Prometheus → HTTP GET /metrics → Your Service
           ← Returns metrics    ←
```

### 4. PromQL (Query Language)

```promql
# Simple query
http_requests_total

# Filter by label
http_requests_total{status="200"}

# Rate (requests per second)
rate(http_requests_total[5m])

# Sum across labels
sum(http_requests_total) by (endpoint)

# 95th percentile latency
histogram_quantile(0.95, rate(request_duration_bucket[5m]))
```

---

## 💻 Hands-On Examples

### Access Prometheus

```
Browser: http://localhost:9090
Targets: http://localhost:9090/targets
Metrics: http://localhost:9090/graph
```

### Example 1: Basic Metrics (Python)

```python
from prometheus_client import Counter, Gauge, Histogram, start_http_server
import time
import random

# Define metrics
predictions_total = Counter(
    'predictions_total',
    'Total predictions made',
    ['ticker', 'model_type']
)

active_requests = Gauge(
    'active_requests',
    'Number of active requests'
)

prediction_duration = Histogram(
    'prediction_duration_seconds',
    'Time to make prediction',
    ['model_type']
)

# Start metrics server on port 8000
start_http_server(8000)

# Use metrics
def make_prediction(ticker, model_type):
    active_requests.inc()  # Increment gauge

    start = time.time()

    # Simulate prediction
    time.sleep(random.uniform(0.1, 0.5))

    duration = time.time() - start

    # Record metrics
    predictions_total.labels(ticker=ticker, model_type=model_type).inc()
    prediction_duration.labels(model_type=model_type).observe(duration)
    active_requests.dec()  # Decrement gauge

    return f"Prediction for {ticker}"

# Make some predictions
make_prediction("AAPL", "normal")
make_prediction("GOOGL", "earnings")
make_prediction("AAPL", "normal")

# Metrics now available at http://localhost:8000/metrics
```

### Example 2: View Metrics Endpoint

```bash
# Visit http://localhost:8000/metrics
# You'll see:

# TYPE predictions_total counter
predictions_total{ticker="AAPL",model_type="normal"} 2.0
predictions_total{ticker="GOOGL",model_type="earnings"} 1.0

# TYPE active_requests gauge
active_requests 0.0

# TYPE prediction_duration_seconds histogram
prediction_duration_seconds_bucket{model_type="normal",le="0.5"} 2.0
prediction_duration_seconds_sum{model_type="normal"} 0.6
prediction_duration_seconds_count{model_type="normal"} 2.0
```

### Example 3: PromQL Queries

Visit http://localhost:9090/graph and try:

```promql
# Total predictions
sum(predictions_total)

# Predictions per ticker
sum(predictions_total) by (ticker)

# Prediction rate (per second) over last 5 minutes
rate(predictions_total[5m])

# Average prediction duration
rate(prediction_duration_seconds_sum[5m]) / rate(prediction_duration_seconds_count[5m])

# 95th percentile duration
histogram_quantile(0.95, rate(prediction_duration_seconds_bucket[5m]))

# Predictions in last hour
increase(predictions_total[1h])
```

### Example 4: Flask Integration

```python
from flask import Flask
from prometheus_client import Counter, Histogram, make_wsgi_app
from werkzeug.middleware.dispatcher import DispatcherMiddleware
import time

app = Flask(__name__)

# Metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

@app.route('/predict/<ticker>')
def predict(ticker):
    start = time.time()

    # Your logic
    result = {"ticker": ticker, "prediction": 155.50}

    # Record metrics
    duration = time.time() - start
    request_duration.labels(method='GET', endpoint='/predict').observe(duration)
    request_count.labels(method='GET', endpoint='/predict', status=200).inc()

    return result

# Add Prometheus metrics endpoint
app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

# Metrics now at http://localhost:5000/metrics
```

---

## 🎓 Best Practices for Our Project

### 1. Metric Naming Convention

```python
# Format: {namespace}_{subsystem}_{name}_{unit}

# ✅ GOOD
predictions_total                      # Counter
prediction_duration_seconds           # Histogram
model_accuracy_ratio                  # Gauge (0-1)
redis_cache_hits_total               # Counter
api_requests_in_flight               # Gauge

# ❌ BAD
pred                                  # Too short
total_predictions_made_count         # Redundant _count
prediction_duration_ms               # Use _seconds not _ms
```

### 2. Label Best Practices

```python
# ✅ GOOD - Low cardinality
predictions_total{ticker="AAPL", model_type="normal"}
# 100 tickers × 2 models = 200 series ✓

# ❌ BAD - High cardinality
predictions_total{prediction_id="abc123"}  # Millions of unique IDs!
# → Explodes memory

# ✅ GOOD - Use sensible labels
http_requests_total{status="200", endpoint="/predict"}

# ❌ BAD - Too many labels
http_requests_total{status="200", endpoint="/predict", user="john", session="xyz"}
```

### 3. Use All 4 Metric Types

```python
from prometheus_client import Counter, Gauge, Histogram, Summary

# Counter - things that only increase
api_errors_total = Counter('api_errors_total', 'Total API errors', ['error_type'])

# Gauge - current value
active_predictions = Gauge('active_predictions', 'Predictions in progress')
memory_usage_bytes = Gauge('memory_usage_bytes', 'Memory usage')

# Histogram - distribution (server-side quantiles)
request_duration = Histogram(
    'request_duration_seconds',
    'Request duration',
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0]  # Custom buckets
)

# Summary - distribution (client-side quantiles)
model_confidence = Summary('model_confidence', 'Prediction confidence')
```

---

## 🔍 Useful Queries for Our Project

### API Performance

```promql
# Request rate (requests/sec)
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Success rate
sum(rate(http_requests_total{status="200"}[5m])) / sum(rate(http_requests_total[5m]))
```

### Model Performance

```promql
# Predictions per second
rate(predictions_total[5m])

# Prediction rate by ticker
sum(rate(predictions_total[5m])) by (ticker)

# Average prediction time
rate(prediction_duration_seconds_sum[5m]) / rate(prediction_duration_seconds_count[5m])

# Cache hit rate
rate(cache_hits_total[5m]) / (rate(cache_hits_total[5m]) + rate(cache_misses_total[5m]))
```

### System Health

```promql
# CPU usage
rate(process_cpu_seconds_total[5m])

# Memory usage
process_resident_memory_bytes

# Active connections
up{job="prediction-api"}  # 1 = up, 0 = down
```

---

## 🐛 Common Issues & Solutions

### Issue: Metrics not showing up

**Solution:**
```bash
# Check if Prometheus can reach your service
# Visit http://localhost:9090/targets
# Should show your service as "UP"

# If DOWN, check:
# 1. Service is running
# 2. Firewall allows connection
# 3. /metrics endpoint works
curl http://your-service:8000/metrics
```

### Issue: Too many metrics

**Solution:**
```python
# Avoid high-cardinality labels
# ❌ BAD
user_requests{user_id="12345"}  # 1M users = 1M series!

# ✅ GOOD
user_requests{user_tier="premium"}  # 3 tiers = 3 series
```

### Issue: Old data

**Solution:**
```yaml
# Prometheus config (prometheus.yml)
global:
  scrape_interval: 15s      # Scrape every 15s
  evaluation_interval: 15s  # Evaluate rules every 15s

# Retention
storage:
  tsdb:
    retention.time: 15d  # Keep 15 days
```

---

## 📚 Learn More

**Official Docs:**
- Prometheus: https://prometheus.io/docs/
- PromQL: https://prometheus.io/docs/prometheus/latest/querying/basics/
- Python Client: https://github.com/prometheus/client_python

**Our Setup:**
- Port: 9090
- Config: `config/prometheus.yml`
- Scrape Interval: 15s

**Access:**
```
UI: http://localhost:9090
Targets: http://localhost:9090/targets
Alerts: http://localhost:9090/alerts
```

---

## ✅ Quick Checklist

- [ ] Understand 4 metric types (Counter, Gauge, Histogram, Summary)
- [ ] Know when to use each type
- [ ] Can add metrics to Python code
- [ ] Understand labels and cardinality
- [ ] Can write basic PromQL queries
- [ ] Know how to check if metrics are being collected
- [ ] Understand scraping concept
- [ ] Can calculate rates and percentiles

**Next:** Learn Grafana for visualization! → [07_Grafana.md](07_Grafana.md)
