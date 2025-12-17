# M1: Getting Started Guide

**Milestone:** Foundation & Infrastructure Setup
**Duration:** Week 1-2 (10 working days)
**Prerequisites:** Git, Docker Desktop, Python 3.11+, VS Code

---

## Quick Start (First Day)

### 1. Clone and Setup (30 minutes)

```bash
# Navigate to your workspace
cd d:\ravi\ai

# Verify repository exists
cd riskee

# Create Python virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Verify VS Code settings are loaded
code .
```

### 2. Open VS Code and Install Extensions (15 minutes)

VS Code should automatically prompt you to install recommended extensions. Click **Install All**.

If not, open Command Palette (Ctrl+Shift+P) and run:
```
Extensions: Show Recommended Extensions
```

Key extensions needed:
- Python
- Docker
- Ruff
- Prettier (for UI later)
- GitLens

### 3. Update Journal for Day 1 (5 minutes)

Open [journal.md](./journal.md) and:
1. Replace `[Date: YYYY-MM-DD]` in Day 1 section with today's date
2. Check boxes for active team members
3. Add your name if starting work today

### 4. Review Current Task List (10 minutes)

Open [M1_Foundation_Infrastructure.md](../M1_Foundation_Infrastructure.md) and review:
- Section 1: Project Setup (Tasks T1.1 - T1.3)
- Section 2: Docker Compose (Tasks T2.1 - T2.6)

These are the first tasks to complete.

---

## Day 1 Recommended Tasks

### Task T1.1: Create GitHub Repository Structure

**Time:** 2 hours
**Owner:** DevOps Lead

1. **Create directory structure:**

```bash
# Navigate to project root
cd d:\ravi\ai\riskee

# Create service directories
mkdir -p services/{ingestion_agent,feature_store,prediction_normal_agent,prediction_earnings_agent,explanation_worker,api_gateway,routing_agent}

# Create other directories
mkdir -p models/{normal_day,earnings_day}
mkdir -p data/{playbooks,edgar,incidents}
mkdir -p tests/{unit,integration,e2e}
mkdir -p scripts
mkdir -p libs
```

2. **Create .gitignore:**

```bash
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.venv/
venv/
ENV/
env/
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
.coverage
*.egg-info/
dist/
build/

# Environment variables
.env
.env.local
.env.*.local

# IDE
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Docker
docker-compose.override.yml

# Logs
*.log
logs/

# Data (sensitive)
data/private/
*.csv
*.db

# Models (large files)
models/**/*.h5
models/**/*.onnx
!models/**/*.md

# Next.js
.next/
out/
node_modules/

# Misc
.vscode/settings.json.local
EOF
```

3. **Initialize Git (if not already done):**

```bash
git init
git add .
git commit -m "chore: initial project structure

- Create service directories
- Create data and model directories
- Add .gitignore

Refs: M1-T1.1"
```

4. **Update journal.md:**
   - Mark T1.1 as started
   - Add notes about repository setup

---

### Task T1.2: Set Up Development Environment Documentation

**Time:** 3 hours
**Owner:** Tech Lead

1. **Create README.md:**

```bash
cat > README.md << 'EOF'
# Feature 1: Real-Time Price Prediction System

AI-powered stock price prediction with LLM-generated explanations.

## Quick Start

See [docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/GETTING_STARTED.md](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/GETTING_STARTED.md)

## Prerequisites

- Docker Desktop 24.0+
- Python 3.11+
- Node.js 18+ (for UI)
- Git
- NVIDIA GPU with 16GB+ VRAM (recommended for M4+)

## Installation

1. Clone repository
2. Copy `.env.example` to `.env`
3. Run `docker-compose up -d`
4. Visit http://localhost:3001 (Grafana)

## Documentation

- [Architecture](docs/ver_0_1/Feature_1_PricePrediction/01_Architecture_Overview.md)
- [Milestones](docs/ver_0_1/Feature_1_PricePrediction/milestones/README.md)
- [Current Progress](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)

## Project Status

**Current Milestone:** M1 - Foundation & Infrastructure Setup
**Status:** In Progress
**Target Completion:** Week 2

## License

Proprietary
EOF
```

2. **Create .env.example:**

```bash
cat > .env.example << 'EOF'
# Feature 1: Environment Variables Template
# Copy this file to .env and fill in values

# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=changeme
POSTGRES_DB=riskee
POSTGRES_HOST=timescaledb
POSTGRES_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# NATS
NATS_HOST=nats
NATS_PORT=4222
NATS_CLUSTER_NAME=riskee-cluster

# Qdrant
QDRANT_HOST=qdrant
QDRANT_PORT=6333
QDRANT_GRPC_PORT=6334

# Ollama
OLLAMA_HOST=ollama
OLLAMA_PORT=11434
OLLAMA_MODEL=llama3.1:8b-instruct-q4_K_M

# API
API_HOST=0.0.0.0
API_PORT=8000
API_KEY=changeme-generate-random-key

# Yahoo Finance API (optional paid tier)
YAHOO_FINANCE_API_KEY=

# Monitoring
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=changeme

# Development
DEBUG=true
LOG_LEVEL=INFO
PYTHONPATH=.
EOF
```

3. **Update journal.md:**
   - Mark T1.2 as completed
   - Note files created

---

### Task T2.1: Create Base docker-compose.yml

**Time:** 3 hours
**Owner:** DevOps Lead

1. **Create docker-compose.yml:**

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

# Feature 1: Real-Time Price Prediction System
# Docker Compose Configuration

services:
  # TimescaleDB (PostgreSQL 15 with TimescaleDB extension)
  timescaledb:
    image: timescale/timescaledb:latest-pg15
    container_name: riskee_timescaledb
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-riskee}
    ports:
      - "5432:5432"
    volumes:
      - timescaledb_data:/var/lib/postgresql/data
      - ./scripts/db/init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - riskee_network

  # Redis 7 (Cache and fast storage)
  redis:
    image: redis:7-alpine
    container_name: riskee_redis
    command: redis-server --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - riskee_network

  # NATS JetStream (Message bus)
  nats:
    image: nats:latest
    container_name: riskee_nats
    command: >
      -js
      -sd /data
      -m 8222
    ports:
      - "4222:4222"  # Client connections
      - "8222:8222"  # Monitoring
    volumes:
      - nats_data:/data
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8222/healthz"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - riskee_network

  # Qdrant (Vector database for RAG)
  qdrant:
    image: qdrant/qdrant:latest
    container_name: riskee_qdrant
    ports:
      - "6333:6333"  # HTTP API
      - "6334:6334"  # gRPC
    volumes:
      - qdrant_data:/qdrant/storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - riskee_network

  # Ollama (LLM server)
  ollama:
    image: ollama/ollama:latest
    container_name: riskee_ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama
    # GPU support (requires nvidia-docker)
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - riskee_network

  # Prometheus (Metrics collection)
  prometheus:
    image: prom/prometheus:latest
    container_name: riskee_prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - riskee_network

  # Grafana (Monitoring dashboards)
  grafana:
    image: grafana/grafana:latest
    container_name: riskee_grafana
    ports:
      - "3001:3000"  # Using 3001 to avoid conflict with UI on 3000
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_ADMIN_USER:-admin}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:-admin}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./config/grafana/datasources:/etc/grafana/provisioning/datasources
    depends_on:
      - prometheus
    networks:
      - riskee_network

volumes:
  timescaledb_data:
  redis_data:
  nats_data:
  qdrant_data:
  ollama_models:
  prometheus_data:
  grafana_data:

networks:
  riskee_network:
    driver: bridge
EOF
```

2. **Create placeholder config directories:**

```bash
mkdir -p config/grafana/{dashboards,datasources}
mkdir -p scripts/db/init
```

3. **Create basic Prometheus config:**

```bash
cat > config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']

  # Add more scrape configs as services are added
EOF
```

4. **Test docker-compose:**

```bash
# Validate syntax
docker-compose config

# Start services (this will take a while on first run)
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs

# If using GPU, verify Ollama can see it
docker exec riskee_ollama nvidia-smi
```

5. **Update journal.md:**
   - Mark T2.1 as completed
   - Note any issues encountered
   - Document services that started successfully

---

## End of Day 1 Checklist

- [ ] Repository structure created (T1.1)
- [ ] .gitignore created
- [ ] README.md created (T1.2)
- [ ] .env.example created
- [ ] docker-compose.yml created (T2.1)
- [ ] All services start without errors
- [ ] journal.md updated with Day 1 progress
- [ ] Changes committed to Git

---

## Day 2 Preview

Tomorrow's focus:
- T2.2: Configure TimescaleDB service (database schemas)
- T2.3: Configure Redis service (test caching)
- T2.4: Configure NATS JetStream (create streams)
- T3.1: Design TimescaleDB schema

---

## Troubleshooting

### Docker services won't start
```bash
# Check Docker Desktop is running
docker ps

# Check logs for specific service
docker-compose logs timescaledb

# Restart a specific service
docker-compose restart timescaledb
```

### Port conflicts
If ports 5432, 6379, or others are in use:
1. Stop conflicting services
2. Or modify ports in docker-compose.yml

### GPU not detected (Ollama)
```bash
# Check NVIDIA drivers
nvidia-smi

# Install nvidia-docker runtime
# Windows: Use Docker Desktop with WSL2 + NVIDIA drivers
# Linux: Install nvidia-docker2 package
```

### VS Code extensions not loading
1. Open Command Palette (Ctrl+Shift+P)
2. Run: "Developer: Reload Window"
3. Check Extensions view for errors

---

## Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [TimescaleDB Quick Start](https://docs.timescale.com/getting-started/latest/)
- [Redis Documentation](https://redis.io/docs/)
- [NATS JetStream](https://docs.nats.io/nats-concepts/jetstream)

---

## Questions or Issues?

1. Check [journal.md](./journal.md) for similar issues
2. Check [M1 plan](../M1_Foundation_Infrastructure.md) for details
3. Update journal.md with blockers
4. Ask team in Slack #feature1-dev

---

**Happy Building! 🚀**
