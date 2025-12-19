# Grafana Tutorial - Developer Gym

**What is it?** Visualization platform for metrics and logs
**Why we use it?** Beautiful dashboards to monitor system health in real-time
**In this project:** Monitor predictions, API performance, model accuracy, system health

---

## 🎯 Quick Concept

Grafana = Google Data Studio for Metrics

**Prometheus (raw data):**
```
predictions_total{ticker="AAPL"} 523
predictions_total{ticker="GOOGL"} 900
```

**Grafana (beautiful visualizations):**
- Line charts showing trend over time
- Gauges for current values
- Tables for breakdowns
- Alerts when something's wrong

---

## 🏗️ Core Concepts

### 1. Data Sources

Where Grafana gets data from:

```
Prometheus → Time-series metrics
TimescaleDB → Prediction data
Loki → Logs (future)
```

### 2. Dashboards

Collection of visualizations (panels):

```
Dashboard: "API Performance"
  ├─ Panel: Request Rate (line chart)
  ├─ Panel: Error Rate (bar chart)
  ├─ Panel: P95 Latency (gauge)
  └─ Panel: Top Endpoints (table)
```

### 3. Panels

Individual visualizations:

```
Panel Types:
- Time series (line/bar chart)
- Gauge (speedometer)
- Stat (single number)
- Table
- Heatmap
- Pie chart
```

### 4. Variables

Make dashboards dynamic:

```
Variable: $ticker = AAPL, GOOGL, MSFT, ...

Query: predictions_total{ticker="$ticker"}

User selects ticker → Dashboard updates automatically
```

---

## 💻 Hands-On Examples

### Access Grafana

```
URL: http://localhost:3001
Username: admin
Password: riskee123
```

### Example 1: Add Data Source

1. Click ⚙️ (Configuration) → Data Sources
2. Click "Add data source"
3. Select "Prometheus"
4. Set URL: `http://prometheus:9090`
5. Click "Save & Test" → Should see "Data source is working"

### Example 2: Create First Dashboard

1. Click + → Dashboard
2. Click "Add new panel"
3. In query builder:
   - Select data source: Prometheus
   - Metric: `up`
   - Click "Run query"
4. See visualization!
5. Panel options (right side):
   - Title: "Service Health"
   - Description: "Shows if services are up (1) or down (0)"
6. Click "Apply"
7. Click "Save dashboard" (top right)
8. Name: "System Overview"

### Example 3: Time Series Panel (Predictions Over Time)

**Query:**
```promql
sum(rate(predictions_total[5m])) by (ticker)
```

**Panel Settings:**
- Visualization: Time series
- Title: "Predictions per Second by Ticker"
- Legend: Show
- Tooltip: All series
- Y-axis: Label "Predictions/sec"

**Result:** Line chart showing prediction rate for each ticker

### Example 4: Gauge Panel (Current Request Rate)

**Query:**
```promql
sum(rate(http_requests_total[5m]))
```

**Panel Settings:**
- Visualization: Gauge
- Title: "Current Request Rate"
- Unit: requests/sec (reqps)
- Thresholds:
  - Green: 0-100
  - Yellow: 100-500
  - Red: >500

**Result:** Speedometer showing current request rate

### Example 5: Stat Panel (Total Predictions Today)

**Query:**
```promql
sum(increase(predictions_total[24h]))
```

**Panel Settings:**
- Visualization: Stat
- Title: "Predictions Today"
- Graph mode: None
- Text size: Large
- Color mode: Background

**Result:** Big number showing total predictions in last 24 hours

### Example 6: Table Panel (Breakdown by Ticker)

**Query:**
```promql
sum(rate(predictions_total[5m])) by (ticker)
```

**Panel Settings:**
- Visualization: Table
- Title: "Prediction Rate by Ticker"
- Columns:
  - ticker (from labels)
  - Value (prediction rate)

**Transform:**
- Add transformation → "Organize fields"
- Rename "Value" → "Predictions/sec"

**Result:** Table showing each ticker and its prediction rate

---

## 🎓 Dashboard Building Best Practices

### 1. Dashboard Structure (Top to Bottom)

```
Row 1: Overview (big numbers)
  - Total predictions today
  - Success rate
  - Average latency

Row 2: Key metrics over time (charts)
  - Prediction rate
  - Error rate
  - Latency P95

Row 3: Breakdowns (tables/details)
  - Predictions by ticker
  - Errors by type
  - Slow endpoints
```

### 2. Use Variables for Interactivity

**Create Variable:**
1. Dashboard settings → Variables
2. Add variable:
   - Name: `ticker`
   - Type: Query
   - Data source: Prometheus
   - Query: `label_values(predictions_total, ticker)`
3. Save

**Use Variable:**
```promql
predictions_total{ticker="$ticker"}
```

Now users can select ticker from dropdown!

### 3. Color Coding

```yaml
Thresholds:
  Green:  Good (< threshold)
  Yellow: Warning (threshold to critical)
  Red:    Critical (> critical)

Examples:
  Error Rate:
    Green: 0-1%
    Yellow: 1-5%
    Red: >5%

  Latency:
    Green: <500ms
    Yellow: 500ms-1s
    Red: >1s

  Success Rate:
    Red: <95%
    Yellow: 95-99%
    Green: >99%
```

### 4. Useful Panel Options

```yaml
Legend:
  - Show: Always show legend
  - Placement: Right (for many series)
  - Values: Show current, min, max

Tooltip:
  - Mode: All series (show all on hover)
  - Sort: Descending

Y-axis:
  - Unit: Choose appropriate (%, ms, bytes, etc.)
  - Min/Max: Auto or set manually
  - Log scale: For exponential data
```

---

## 🔍 Example Queries for Dashboards

### API Performance Dashboard

**Panel 1: Request Rate**
```promql
sum(rate(http_requests_total[5m]))
```

**Panel 2: Success Rate**
```promql
sum(rate(http_requests_total{status="200"}[5m])) / sum(rate(http_requests_total[5m])) * 100
```

**Panel 3: P95 Latency**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Panel 4: Error Rate by Type**
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) by (status)
```

### Prediction Monitoring Dashboard

**Panel 1: Predictions/Second**
```promql
sum(rate(predictions_total[5m])) by (ticker)
```

**Panel 2: Average Confidence**
```promql
rate(prediction_confidence_sum[5m]) / rate(prediction_confidence_count[5m])
```

**Panel 3: Predictions by Model Type**
```promql
sum(rate(predictions_total[5m])) by (model_type)
```

**Panel 4: Cache Hit Rate**
```promql
rate(cache_hits_total[5m]) / (rate(cache_hits_total[5m]) + rate(cache_misses_total[5m])) * 100
```

### System Health Dashboard

**Panel 1: Service Up/Down**
```promql
up{job="prediction-api"}
```

**Panel 2: CPU Usage**
```promql
rate(process_cpu_seconds_total[5m]) * 100
```

**Panel 3: Memory Usage**
```promql
process_resident_memory_bytes / 1024 / 1024
```

**Panel 4: Active Connections**
```promql
active_connections
```

---

## 🎯 Create Production Dashboard (Step-by-Step)

### Dashboard: "Prediction System Overview"

**Row 1: Key Metrics (Stats)**

```
Panel 1: Total Predictions Today
Query: sum(increase(predictions_total[24h]))
Type: Stat
Color: Blue background

Panel 2: Success Rate
Query: sum(rate(predictions_total{status="success"}[5m])) / sum(rate(predictions_total[5m])) * 100
Type: Stat
Unit: percent (0-100)
Thresholds: Red <95, Yellow 95-99, Green >99

Panel 3: Avg Confidence
Query: avg(model_confidence)
Type: Gauge
Unit: percent (0-100)
Thresholds: Red <70, Yellow 70-85, Green >85

Panel 4: P95 Latency
Query: histogram_quantile(0.95, rate(prediction_duration_seconds_bucket[5m]))
Type: Stat
Unit: seconds (s)
Thresholds: Green <1s, Yellow 1-2s, Red >2s
```

**Row 2: Trends (Time Series)**

```
Panel 1: Prediction Rate
Query: sum(rate(predictions_total[5m])) by (ticker)
Type: Time series
Y-axis: predictions/sec

Panel 2: Latency (P50, P95, P99)
Queries:
  - P50: histogram_quantile(0.50, rate(prediction_duration_seconds_bucket[5m]))
  - P95: histogram_quantile(0.95, rate(prediction_duration_seconds_bucket[5m]))
  - P99: histogram_quantile(0.99, rate(prediction_duration_seconds_bucket[5m]))
Type: Time series
Y-axis: seconds

Panel 3: Error Rate
Query: sum(rate(errors_total[5m])) by (error_type)
Type: Time series
Y-axis: errors/sec
```

**Row 3: Breakdown (Tables)**

```
Panel 1: Top Tickers by Volume
Query: topk(10, sum(rate(predictions_total[5m])) by (ticker))
Type: Table
Columns: Ticker, Predictions/sec

Panel 2: Model Performance
Query: sum(rate(predictions_total[5m])) by (model_type)
Type: Pie chart
```

---

## 🐛 Common Issues & Solutions

### Issue: "No data" in panel

**Solution:**
```
1. Check query in "Query Inspector" (bottom of panel)
2. Verify data exists in Prometheus: http://localhost:9090
3. Check time range (top right) - try "Last 5 minutes"
4. Ensure data source is Prometheus
```

### Issue: Dashboard not refreshing

**Solution:**
```
1. Check refresh interval (top right) - set to "5s" or "10s"
2. Ensure Prometheus is scraping (check /targets)
3. Try manual refresh (↻ button)
```

### Issue: Query too slow

**Solution:**
```promql
# ❌ SLOW - Long time range
sum(rate(predictions_total[24h]))

# ✅ FAST - Shorter range
sum(rate(predictions_total[5m]))

# Use recording rules for complex queries
```

---

## 📚 Learn More

**Official Docs:**
- Grafana Docs: https://grafana.com/docs/
- Panel types: https://grafana.com/docs/grafana/latest/panels/
- Variables: https://grafana.com/docs/grafana/latest/variables/

**Our Setup:**
- Port: 3001
- Username: admin
- Password: riskee123
- Data source: Prometheus (http://prometheus:9090)

**Pre-built Dashboards:**
- Browse: https://grafana.com/grafana/dashboards/
- Import: Dashboard → Import → Enter ID

---

## ✅ Quick Checklist

- [ ] Can access Grafana (http://localhost:3001)
- [ ] Added Prometheus as data source
- [ ] Created first dashboard
- [ ] Know 5+ panel types (Time series, Gauge, Stat, Table, Pie)
- [ ] Can write PromQL queries in panels
- [ ] Understand thresholds for color coding
- [ ] Can create variables for interactivity
- [ ] Know how to set refresh interval
- [ ] Can organize panels into rows
- [ ] Understand when to use each visualization type

---

## 🎓 Next Steps

1. **Create Your First Dashboard**
   - Start with 3-4 key metrics
   - Use Stat panels for overview
   - Add Time series for trends

2. **Explore Pre-built Dashboards**
   - Import Node Exporter dashboard (ID: 1860)
   - Import Prometheus Stats (ID: 2)

3. **Set Up Alerts** (Advanced)
   - Alerting → Create alert rule
   - Send to Slack/email when errors spike

4. **Share Dashboards**
   - Export as JSON
   - Import on another Grafana
   - Commit to git for version control

---

**Congratulations!** You've completed the Dev Gym! 🎉

You now understand all 7 infrastructure components:
1. ✅ TimescaleDB - Time-series data
2. ✅ Redis - Caching
3. ✅ NATS - Messaging
4. ✅ Qdrant - Vector search
5. ✅ Ollama - LLM
6. ✅ Prometheus - Metrics
7. ✅ Grafana - Visualization

**Start building!** Check out [DEV_GETTING_STARTED.md](../DEV_GETTING_STARTED.md) to begin development.
