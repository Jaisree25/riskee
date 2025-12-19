# Developer Gym 🏋️

**Welcome to the Developer Training Ground!**

This folder contains hands-on tutorials for all 7 infrastructure technologies used in the Real-Time Price Prediction System.

---

## 📚 Tutorials

Learn each technology in ~20 minutes:

| # | Technology | Purpose | Tutorial | Duration |
|---|------------|---------|----------|----------|
| 1 | **TimescaleDB** | Time-series database | [01_TimescaleDB.md](01_TimescaleDB.md) | 20 min |
| 2 | **Redis** | In-memory cache | [02_Redis.md](02_Redis.md) | 15 min |
| 3 | **NATS** | Message streaming | [03_NATS.md](03_NATS.md) | 20 min |
| 4 | **Qdrant** | Vector database | [04_Qdrant.md](04_Qdrant.md) | 15 min |
| 5 | **Ollama** | Local LLM | [05_Ollama.md](05_Ollama.md) | 15 min |
| 6 | **Prometheus** | Metrics & monitoring | [06_Prometheus.md](06_Prometheus.md) | 20 min |
| 7 | **Grafana** | Visualization | [07_Grafana.md](07_Grafana.md) | 15 min |

**Total Time:** ~2 hours to learn all technologies

---

## 🎯 Learning Path

### Beginner (Start Here)

If you're new to these technologies, follow this order:

1. **[Redis](02_Redis.md)** - Easiest to understand
2. **[TimescaleDB](01_TimescaleDB.md)** - Build on database knowledge
3. **[Ollama](05_Ollama.md)** - Simple API, fun to play with
4. **[Grafana](07_Grafana.md)** - Visual and interactive

### Intermediate

5. **[NATS](03_NATS.md)** - More complex, async patterns
6. **[Prometheus](06_Prometheus.md)** - PromQL takes practice
7. **[Qdrant](04_Qdrant.md)** - Vector embeddings are advanced

---

## 🚀 Quick Start

### Prerequisites

Ensure all services are running:

```bash
# Check Docker services
docker-compose ps

# All 7 services should be "Up"
```

### Test Each Service

**TimescaleDB:**
```bash
docker exec -it riskee_timescaledb psql -U postgres -d riskee
# \dt to list tables
# \q to quit
```

**Redis:**
```bash
docker exec -it riskee_redis redis-cli
# PING
# QUIT
```

**NATS:**
```bash
curl http://localhost:8222/healthz
# Should return: {"status":"ok"}
```

**Qdrant:**
```bash
curl http://localhost:6333/collections
# Or visit: http://localhost:6333/dashboard
```

**Ollama:**
```bash
curl http://localhost:11434/api/tags
# Lists available models
```

**Prometheus:**
```bash
# Visit: http://localhost:9090
```

**Grafana:**
```bash
# Visit: http://localhost:3001
# Username: admin, Password: riskee123
```

---

## 📖 Tutorial Format

Each tutorial includes:

- **🎯 Quick Concept** - What it is and why we use it
- **🏗️ Core Concepts** - Key ideas explained simply
- **💻 Hands-On Examples** - Copy-paste code you can run
- **🎓 Best Practices** - How to use it in our project
- **🐛 Common Issues** - Troubleshooting guide
- **✅ Checklist** - Verify your understanding

---

## 🎓 Learning Tips

### 1. Learn by Doing

Don't just read - run every example!

```bash
# Copy code from tutorial
# Paste in terminal
# See it work
# Modify and experiment
```

### 2. Use the Cheat Sheets

Each tutorial has a "Quick Reference" section at the end with common commands.

### 3. Connect the Dots

Understand how services work together:

```
Market Data → Redis (cache) → TimescaleDB (store)
     ↓
  NATS (message)
     ↓
  ML Prediction
     ↓
  Qdrant (find similar) → Ollama (explain)
     ↓
  Prometheus (metrics) → Grafana (visualize)
```

### 4. Practice Projects

Try building:
- Simple cache with Redis
- Time-series chart with TimescaleDB + Grafana
- Message queue with NATS
- Vector search with Qdrant
- LLM chatbot with Ollama

---

## 🛠️ Hands-On Exercises

### Exercise 1: End-to-End Flow (30 minutes)

**Goal:** Send data through the entire system

```python
# 1. Store in Redis (cache)
import redis
r = redis.Redis(host='localhost', port=6379)
r.set('AAPL:price', '155.50')

# 2. Store in TimescaleDB (persistence)
import psycopg2
conn = psycopg2.connect("host=localhost dbname=riskee user=postgres password=riskee123")
cur = conn.cursor()
cur.execute("INSERT INTO predictions (...) VALUES (...)")

# 3. Publish to NATS (event)
import asyncio
from nats.aio.client import Client as NATS
async def publish():
    nc = NATS()
    await nc.connect("nats://localhost:4222")
    await nc.publish("predictions.AAPL", b"155.50")
    await nc.close()
asyncio.run(publish())

# 4. Search Qdrant (context)
from qdrant_client import QdrantClient
client = QdrantClient(host="localhost", port=6333)
results = client.query_points("market_news", query=[0.1]*768, limit=5)

# 5. Generate with Ollama (explanation)
import requests
response = requests.post(
    "http://localhost:11434/api/generate",
    json={"model": "gemma3:4b", "prompt": "Why AAPL up?", "stream": False}
)
print(response.json()["response"])

# 6. View in Grafana
# Visit http://localhost:3001 and see your metrics!
```

### Exercise 2: Build a Dashboard (20 minutes)

**Goal:** Create a Grafana dashboard with all data sources

1. Create dashboard with 4 panels:
   - TimescaleDB: Predictions over time
   - Redis: Cache hit rate
   - Prometheus: Request rate
   - Custom: Prediction count

---

## 📊 Technology Comparison

### When to Use Each

| Technology | Use When... | Don't Use When... |
|------------|-------------|-------------------|
| **TimescaleDB** | Storing time-series data (metrics, predictions) | Need ultra-low latency reads |
| **Redis** | Frequently accessed data, temporary storage | Data can't be lost, need complex queries |
| **NATS** | Decoupling services, async processing | Need guaranteed delivery in order |
| **Qdrant** | Finding similar items, RAG for LLMs | Simple exact-match searches |
| **Ollama** | Text generation, local AI processing | Need GPT-4 quality, cloud OK |
| **Prometheus** | Monitoring metrics, alerting | Storing logs, traces |
| **Grafana** | Visualizing time-series data | Real-time collaboration |

### Performance Comparison

| Technology | Read Speed | Write Speed | Storage | Cost |
|------------|-----------|-------------|---------|------|
| TimescaleDB | Medium | Medium | Disk (cheap) | Low |
| Redis | **Fastest** | **Fastest** | RAM (expensive) | Medium |
| NATS | Fast | Fast | Disk | Low |
| Qdrant | Fast | Medium | Disk | Low |
| Ollama | Slow | N/A | Disk (models) | Free |
| Prometheus | Fast | Fast | Disk | Low |
| Grafana | N/A | N/A | Minimal | Free |

---

## 🔗 Related Documentation

- **[DEV_GETTING_STARTED.md](../DEV_GETTING_STARTED.md)** - Complete setup guide
- **[DEV_GETTING_STARTED_WINDOWS.md](../DEV_GETTING_STARTED_WINDOWS.md)** - Windows PowerShell guide
- **[docs/PROGRESS_SUMMARY.md](../docs/PROGRESS_SUMMARY.md)** - Project status
- **[README.md](../README.md)** - Project overview

---

## 🎯 Completion Criteria

You've mastered the Dev Gym when you can:

- [ ] Explain what each technology does in one sentence
- [ ] Write data to all 3 databases (TimescaleDB, Redis, Qdrant)
- [ ] Publish and subscribe to NATS messages
- [ ] Generate text with Ollama
- [ ] Query Prometheus metrics with PromQL
- [ ] Create a Grafana dashboard with multiple panels
- [ ] Troubleshoot common issues for each service
- [ ] Choose the right technology for a given use case

---

## 💡 Pro Tips

### Tip 1: Use Docker Logs for Debugging

```bash
# View logs for any service
docker-compose logs -f timescaledb
docker-compose logs -f redis
docker-compose logs -f nats
# ... etc
```

### Tip 2: Keep Services Running

```bash
# Don't stop services while learning
docker-compose up -d

# Only restart if needed
docker-compose restart <service>
```

### Tip 3: Bookmark These URLs

```
TimescaleDB: postgresql://localhost:5432/riskee
Redis:       redis://localhost:6379
NATS:        http://localhost:8222
Qdrant:      http://localhost:6333/dashboard
Ollama:      http://localhost:11434
Prometheus:  http://localhost:9090
Grafana:     http://localhost:3001
```

### Tip 4: Learn One at a Time

Don't try to learn all 7 in one day. Spread it over a week:

- **Day 1:** Redis + TimescaleDB (databases)
- **Day 2:** NATS (messaging)
- **Day 3:** Qdrant + Ollama (AI components)
- **Day 4:** Prometheus + Grafana (monitoring)
- **Day 5:** Practice integration

---

## 🎉 You're Ready!

After completing the Dev Gym, you'll have hands-on experience with all 7 technologies.

**Next Steps:**
1. Complete all 7 tutorials
2. Run the hands-on exercises
3. Build something small with each tech
4. Read the main project docs
5. Start contributing to the codebase!

**Questions?** Check the troubleshooting section in each tutorial or ask on Slack.

---

**Happy Learning!** 🚀

*Last Updated: 2025-12-17*
