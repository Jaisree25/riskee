# Developer Getting Started Guide

**Feature 1: Real-Time Price Prediction System**
**Last Updated:** 2025-12-17
**For:** New team members joining the project

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites

Before you begin, ensure you have:

- **Docker Desktop 24.0+** ([Download](https://www.docker.com/products/docker-desktop))
- **Git** ([Download](https://git-scm.com/downloads))
- **Python 3.11+** ([Download](https://www.python.org/downloads/))
- **VS Code** (recommended) ([Download](https://code.visualstudio.com/))

### 1. Clone the Repository

```bash
git clone https://github.com/Jaisree25/riskee.git
cd riskee
```

### 2. Start All Services

```bash
# Start Docker Desktop first (if not running)

# Start all infrastructure services
docker-compose up -d

# Wait ~30 seconds for services to initialize
# Verify all services are running
docker-compose ps
```

You should see 7 services running:
- `riskee_timescaledb` (database)
- `riskee_redis` (cache)
- `riskee_nats` (messaging)
- `riskee_qdrant` (vector database)
- `riskee_ollama` (LLM)
- `riskee_prometheus` (metrics)
- `riskee_grafana` (dashboards)

### 3. Install Python Dependencies

```bash
# Create virtual environment (recommended)
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Install dependencies
pip install -r scripts/requirements.txt
```

### 4. Initialize Infrastructure

```bash
# Set up Qdrant vector collections
python scripts/setup_qdrant.py

# Verify Ollama LLM models
python scripts/setup_ollama.py

# Test Redis cache
bash scripts/test_redis.sh
```

### 5. Access Services

Open your browser and verify these URLs work:

- **Grafana:** http://localhost:3001 (username: `admin`, password: `riskee123`)
- **Prometheus:** http://localhost:9090
- **Qdrant Dashboard:** http://localhost:6333/dashboard
- **NATS Monitoring:** http://localhost:8222

---

## 🎯 Development Credentials

**IMPORTANT:** These are development-only credentials. Never use in production!

| Service | Username | Password | Port |
|---------|----------|----------|------|
| PostgreSQL/TimescaleDB | `postgres` | `riskee123` | 5432 |
| Grafana | `admin` | `riskee123` | 3001 |
| Redis | - | (none) | 6379 |

**Environment File:** All credentials are in `.env` file (already configured)

---

## 📁 Project Structure

```
riskee/
├── services/               # Microservices code
│   ├── ingestion_agent/   # Market data ingestion
│   ├── feature_store/     # Feature engineering
│   ├── prediction_normal_agent/
│   ├── prediction_earnings_agent/
│   ├── explanation_worker/
│   ├── api_gateway/
│   └── routing_agent/
├── models/                # ML model artifacts
│   ├── normal_day/
│   └── earnings_day/
├── data/                  # Data storage
│   ├── playbooks/        # Runbooks and procedures
│   ├── edgar/           # SEC filings
│   └── incidents/       # Incident logs
├── tests/                # Test suites
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── scripts/              # Setup and utility scripts
├── config/               # Configuration files
├── docs/                 # Documentation
├── docker-compose.yml    # Infrastructure definition
└── .env                  # Environment variables
```

---

## 🗄️ Database Schema

### TimescaleDB Tables

**Hypertables (Time-series):**

1. **predictions** - ML model predictions
   ```sql
   - ticker, prediction_time, target_time
   - predicted_price, confidence_score
   - model_version, agent_type
   - Compression: after 7 days
   - Retention: 90 days
   ```

2. **model_metrics** - Model performance tracking
   ```sql
   - model_version, metric_time
   - mae, rmse, mape, accuracy
   - Compression: after 7 days
   - Retention: 90 days
   ```

3. **market_data** - OHLCV data
   ```sql
   - ticker, timestamp
   - open, high, low, close, volume
   - Compression: after 7 days
   - Retention: 90 days
   ```

**Regular Table:**

4. **explanations** - LLM-generated explanations
   ```sql
   - prediction_id (FK to predictions)
   - explanation_text, llm_model
   - sentiment_score, factors
   ```

### Connect to Database

```bash
# Using docker exec
docker exec -it riskee_timescaledb psql -U postgres -d riskee

# Or from host (if psql installed)
psql -h localhost -U postgres -d riskee
# Password: riskee123

# List tables
\dt

# Describe table
\d predictions
```

---

## 📊 Qdrant Vector Collections

**5 RAG Collections** (768 dimensions, COSINE distance):

1. `market_news` - Financial news and commentary
2. `earnings_calls` - Earnings call transcripts
3. `economic_indicators` - Economic reports
4. `technical_patterns` - Technical analysis patterns
5. `prediction_context` - Historical prediction contexts

**Query Example:**
```python
from qdrant_client import QdrantClient

client = QdrantClient(host="localhost", port=6333)

# List collections
collections = client.get_collections()

# Search for similar vectors
results = client.query_points(
    collection_name="market_news",
    query=[0.1] * 768,  # Your embedding vector
    limit=5
)
```

---

## 🔄 NATS JetStream Streams

**5 Message Streams:**

| Stream | Subjects | Retention | Max Size |
|--------|----------|-----------|----------|
| MARKET_DATA | `market.data.*` | 7 days | 10 GB |
| PREDICTIONS | `predictions.*` | 30 days | 5 GB |
| EXPLANATIONS | `explanations.*` | 30 days | 2 GB |
| MODEL_METRICS | `metrics.model.*` | 90 days | 1 GB |
| ROUTING | `routing.*` | 7 days | 512 MB |

**Test Pub/Sub:**
```bash
# When Docker is running
python scripts/test_nats_pubsub.py
```

---

## 🤖 Ollama LLM Models

**Available Models:**

1. **gemma3:4b** (3.2 GB) - Fast, good quality ✓ Tested
2. **mistral:7b** (4.2 GB) - Balanced performance
3. **tinyllama:latest** (608 MB) - Lightweight testing

**Test Generation:**
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3:4b",
  "prompt": "Explain why AAPL stock might increase in 1 sentence."
}'
```

**Or use Python:**
```python
import requests

response = requests.post(
    "http://localhost:11434/api/generate",
    json={
        "model": "gemma3:4b",
        "prompt": "Why might AAPL stock increase tomorrow?",
        "stream": False
    }
)
print(response.json()["response"])
```

---

## 🧪 Testing Your Setup

### Health Check Script (Coming Soon)

```bash
# Will verify all services are healthy
python scripts/health_check.py
```

### Manual Verification

**1. Check Docker Services:**
```bash
docker-compose ps
# All services should show "Up" or "healthy"
```

**2. Test TimescaleDB:**
```bash
docker exec riskee_timescaledb psql -U postgres -d riskee -c "SELECT COUNT(*) FROM predictions;"
```

**3. Test Redis:**
```bash
docker exec riskee_redis redis-cli PING
# Should return: PONG
```

**4. Test NATS:**
```bash
curl -s http://localhost:8222/healthz
# Should return: {"status":"ok"}
```

**5. Test Qdrant:**
```bash
curl -s http://localhost:6333/collections | python -m json.tool
# Should list 5 collections
```

**6. Test Ollama:**
```bash
curl -s http://localhost:11434/api/tags
# Should list available models
```

---

## 🛠️ Common Tasks

### Stop All Services
```bash
docker-compose down
```

### Restart Specific Service
```bash
docker-compose restart timescaledb
```

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs -f timescaledb

# Last 100 lines
docker-compose logs --tail=100
```

### Clean Up Everything
```bash
# Stop and remove containers, networks
docker-compose down

# Also remove volumes (WARNING: deletes all data!)
docker-compose down -v
```

### Reset Database
```bash
# Stop database
docker-compose stop timescaledb

# Remove volume
docker volume rm riskee_timescaledb_data

# Restart
docker-compose up -d timescaledb

# Re-initialize schema
docker exec -i riskee_timescaledb psql -U postgres -d riskee < scripts/db/init/01_init_schema.sql
```

---

## 📚 Documentation

### Key Documents

- **[Progress Summary](docs/PROGRESS_SUMMARY.md)** - Current project status
- **[Daily Journal](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)** - Daily progress log
- **[Architecture](docs/ver_0_1/Feature_1_PricePrediction/01_Architecture_Overview.md)** - System architecture
- **[M1 Milestone Plan](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/M1_Foundation_Infrastructure.md)** - Current milestone

### External Resources

- **TimescaleDB:** https://docs.timescale.com/
- **Redis:** https://redis.io/documentation
- **NATS JetStream:** https://docs.nats.io/nats-concepts/jetstream
- **Qdrant:** https://qdrant.tech/documentation/
- **Ollama:** https://github.com/ollama/ollama

---

## 🐛 Troubleshooting

### Issue: "Cannot connect to Docker daemon"

**Solution:**
```bash
# Windows: Start Docker Desktop
# Check status
docker ps
```

### Issue: Port already in use

**Solution:**
```bash
# Find what's using the port (Windows)
netstat -ano | findstr :5432

# Kill the process or change port in docker-compose.yml
```

### Issue: Service unhealthy

**Solution:**
```bash
# Check logs
docker-compose logs <service-name>

# Restart service
docker-compose restart <service-name>

# If persists, recreate
docker-compose up -d --force-recreate <service-name>
```

### Issue: "Permission denied" errors

**Solution:**
```bash
# Windows: Run terminal as Administrator
# Linux/Mac: Use sudo or fix file permissions
sudo chown -R $USER:$USER .
```

### Issue: Slow Docker performance on Windows

**Solution:**
1. Enable WSL 2 backend in Docker Desktop
2. Allocate more resources in Docker Desktop Settings
3. Move project to WSL filesystem (better performance)

---

## 🔐 Security Notes

### Development Environment Only

⚠️ **WARNING:** Current setup is for **development only**!

**Never use in production:**
- Default passwords (`riskee123`)
- No authentication on some services
- No TLS/SSL encryption
- Exposed ports without firewall

### For Production Deployment

You will need to:
- [ ] Generate strong, unique passwords
- [ ] Enable authentication on all services
- [ ] Set up TLS/SSL certificates
- [ ] Configure firewall rules
- [ ] Use secrets management (e.g., HashiCorp Vault)
- [ ] Enable audit logging
- [ ] Set up VPN/bastion for database access

---

## 🤝 Getting Help

### Team Communication

- **Slack Channel:** #feature-1-price-prediction (if applicable)
- **GitHub Issues:** https://github.com/Jaisree25/riskee/issues
- **Tech Lead:** [Contact info]

### Reporting Issues

When reporting issues, include:
1. What you were trying to do
2. What happened vs. what you expected
3. Error messages (full output)
4. Docker service logs (`docker-compose logs`)
5. Your environment (OS, Docker version)

### Contributing

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and test locally
3. Commit with clear messages: `git commit -m "feat: add feature X"`
4. Push and create Pull Request
5. Wait for code review

---

## ✅ Verification Checklist

Use this checklist to verify your setup is complete:

- [ ] Cloned repository from GitHub
- [ ] Docker Desktop running
- [ ] All 7 services started (`docker-compose ps`)
- [ ] Can access Grafana (http://localhost:3001)
- [ ] Can access Prometheus (http://localhost:9090)
- [ ] Qdrant collections created (5 collections)
- [ ] Ollama models available (3 models)
- [ ] Redis responding to PING
- [ ] TimescaleDB schema initialized
- [ ] Python virtual environment created
- [ ] Python dependencies installed
- [ ] Read architecture documentation
- [ ] Understand project structure

---

## 🎓 Next Steps

Once your environment is set up:

1. **Read the Architecture**
   - [Architecture Overview](docs/ver_0_1/Feature_1_PricePrediction/01_Architecture_Overview.md)
   - Understand the system design

2. **Review Current Progress**
   - [Progress Summary](docs/PROGRESS_SUMMARY.md)
   - [Daily Journal](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)

3. **Pick a Task**
   - Check [M1 Journal](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md) for pending tasks
   - Coordinate with team on Slack

4. **Start Coding**
   - Create feature branch
   - Write tests first (TDD)
   - Follow coding standards
   - Submit PR for review

---

## 📞 Quick Reference

**Service URLs:**
```
Grafana:     http://localhost:3001  (admin/riskee123)
Prometheus:  http://localhost:9090
Qdrant:      http://localhost:6333/dashboard
NATS:        http://localhost:8222
TimescaleDB: localhost:5432 (postgres/riskee123)
Redis:       localhost:6379
Ollama:      http://localhost:11434
```

**Common Commands:**
```bash
# Start all
docker-compose up -d

# Stop all
docker-compose down

# View logs
docker-compose logs -f

# Restart service
docker-compose restart <service>

# Database
docker exec -it riskee_timescaledb psql -U postgres -d riskee

# Redis
docker exec -it riskee_redis redis-cli

# Health checks
curl http://localhost:8222/healthz     # NATS
curl http://localhost:6333/collections # Qdrant
```

---

**Welcome to the team! 🎉**

If you run into any issues, don't hesitate to ask for help on Slack or create a GitHub issue.

Happy coding! 💻
