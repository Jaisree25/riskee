# Infrastructure Architecture

**Project:** Riskee - Real-Time Price Prediction System
**Version:** 0.1.0
**Last Updated:** 2025-12-19

---

## Overview

This document describes the complete infrastructure architecture for the Riskee real-time price prediction system.

### System Purpose
Predict stock price movements in real-time using machine learning models enhanced with RAG (Retrieval Augmented Generation) for explainability.

### Key Characteristics
- **Real-time:** Sub-second prediction latency
- **Scalable:** Handle 100+ tickers simultaneously
- **Explainable:** LLM-generated reasoning for each prediction
- **Resilient:** Event-driven architecture with async processing

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
│  (API Consumers, Web UI, Mobile Apps)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTP/WebSocket
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (Future)                         │
│  FastAPI - REST + WebSocket endpoints                           │
│  ├─ GET /predict/{ticker}                                       │
│  ├─ POST /predict                                               │
│  └─ WS /stream                                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   REDIS      │ │ TIMESCALEDB  │ │    NATS      │
│   Cache      │ │   Database   │ │  JetStream   │
│              │ │              │ │              │
│ • Predictions│ │• Predictions │ │• Data stream │
│ • Features   │ │• Market data │ │• Events      │
│ • Metadata   │ │• Earnings    │ │• Job queue   │
└──────────────┘ └──────────────┘ └──────┬───────┘
                                          │
                 ┌────────────────────────┼────────────────┐
                 │                        │                │
                 ▼                        ▼                ▼
        ┌────────────────┐      ┌────────────────┐  ┌──────────┐
        │  PREDICTION    │      │  EXPLANATION   │  │ INGESTION│
        │   SERVICE      │      │    SERVICE     │  │ SERVICE  │
        │                │      │                │  │          │
        │ • ML Models    │      │ • RAG Pipeline │  │ • Market │
        │ • Feature Eng  │      │ • LLM Prompts  │  │   Data   │
        └────┬───────────┘      └────┬───────────┘  └──────────┘
             │                       │
             │ Uses                  │ Uses
             ▼                       ▼
     ┌──────────────┐        ┌──────────────┐
     │   QDRANT     │        │   OLLAMA     │
     │Vector Search │        │   LLM API    │
     │              │        │              │
     │• News        │        │• gemma3:4b   │
     │• Earnings    │        │• mistral:7b  │
     │• Patterns    │        │• tinyllama   │
     └──────────────┘        └──────────────┘

                ┌─────────────────────────┐
                │    MONITORING LAYER     │
                │                         │
                │  Prometheus ← Services  │
                │       ↓                 │
                │    Grafana              │
                └─────────────────────────┘
```

---

## Infrastructure Components

### 1. TimescaleDB (PostgreSQL + TimescaleDB Extension)

**Purpose:** Primary data store for time-series data

**Port:** 5432

**Schema:**
- **predictions** (hypertable)
  - Partitioned by `prediction_time` (1-day chunks)
  - Compressed after 7 days
  - Retained for 90 days
  - Indexed on `ticker` and `prediction_time`

- **market_data** (hypertable)
  - OHLCV data
  - Partitioned by `timestamp`
  - Compressed after 7 days

- **earnings_calendar** (regular table)
  - Earnings dates and estimates

- **model_metadata** (regular table)
  - Model versions and performance metrics

**Configuration:**
```yaml
Container: riskee_timescaledb
Image: timescale/timescaledb:latest-pg16
Memory: 2GB
CPU: 2 cores
Storage: 20GB volume
```

**Connection:**
```
postgresql://postgres:riskee123@localhost:5432/riskee
```

**Performance Targets:**
- Insert rate: >1000 predictions/sec
- Query latency: <100ms (p95)
- Compression ratio: 10:1

---

### 2. Redis

**Purpose:** High-speed cache for frequently accessed data

**Port:** 6379

**Data Structures:**
- `pred:{ticker}` - Latest prediction (Hash, TTL: 5min)
- `features:{ticker}` - Pre-computed features (Hash, TTL: 1min)
- `earnings_analysis:{ticker}:{date}` - Earnings analysis (Hash, TTL: 24h)
- `explanation:{ticker}:{ts}` - Prediction explanation (Hash, TTL: 10min)
- `model:{type}:active` - Active model metadata (Hash, TTL: 1h)
- `stats:cache:*` - Cache statistics (String/Sorted Set, TTL: 24h)

**Configuration:**
```yaml
Container: riskee_redis
Image: redis:7-alpine
Memory: 8GB (maxmemory)
Persistence: AOF (appendonly)
```

**Connection:**
```
redis://localhost:6379
```

**Performance Targets:**
- Read latency: <2ms (p95)
- Hit rate: >80%
- Throughput: >10,000 ops/sec

---

### 3. NATS JetStream

**Purpose:** Asynchronous message bus and event streaming

**Ports:** 4222 (client), 8222 (monitoring)

**Streams:**

| Stream | Subjects | Retention | Max Size | Purpose |
|--------|----------|-----------|----------|---------|
| MARKET_DATA | `data.market.*` | 7 days | 10GB | Market quotes |
| PREDICTIONS | `event.prediction.*` | 30 days | 5GB | Prediction events |
| EXPLANATIONS | `thought.*` | 30 days | 2GB | LLM explanations |
| MODEL_METRICS | `metrics.model.*` | 90 days | 1GB | Model performance |
| ROUTING | `job.*` | 7 days | 512MB | Job queue |

**Message Flow:**
```
Market Data → data.market.quote → Ingestion
              ↓
         Feature Extraction
              ↓
         job.predict.* → ML Service
              ↓
      event.prediction.updated → Cache + DB
              ↓
         thought.* → LLM Service
              ↓
        Explanation → Client
```

**Configuration:**
```yaml
Container: riskee_nats
Image: nats:latest
Memory: 1GB
Storage: File-based (persistent)
```

**Connection:**
```
nats://localhost:4222
```

**Performance Targets:**
- Throughput: >10,000 msg/sec
- Latency: <10ms (p95)
- Durability: File-backed

---

### 4. Qdrant

**Purpose:** Vector database for RAG (Retrieval Augmented Generation)

**Ports:** 6333 (HTTP), 6334 (gRPC)

**Collections:**

| Collection | Vector Size | Distance | Purpose |
|------------|-------------|----------|---------|
| market_news | 768 | COSINE | Financial news articles |
| earnings_calls | 768 | COSINE | Earnings call transcripts |
| economic_indicators | 768 | COSINE | Economic reports |
| technical_patterns | 768 | COSINE | Technical analysis patterns |
| prediction_context | 768 | COSINE | Historical contexts |

**Embedding Model:** all-MiniLM-L6-v2 (768 dimensions)

**Configuration:**
```yaml
Container: riskee_qdrant
Image: qdrant/qdrant:latest
Memory: 2GB
Storage: 10GB volume
```

**Connection:**
```
http://localhost:6333
```

**Performance Targets:**
- Search latency: <50ms (p95)
- Insertion rate: >1000 vectors/sec
- Collection size: 100K+ vectors each

---

### 5. Ollama

**Purpose:** Local LLM for generating prediction explanations

**Port:** 11434

**Models:**

| Model | Size | Quantization | Use Case |
|-------|------|--------------|----------|
| gemma3:4b | 3.2GB | Q4_K_M | **Production** - Best balance |
| mistral:7b | 4.2GB | Q4_K_M | Alternative/Testing |
| tinyllama | 608MB | Q4_0 | Development/Testing |

**Configuration:**
```yaml
Container: riskee_ollama
Image: ollama/ollama:latest
Memory: 8GB
GPU: NVIDIA runtime (if available)
```

**Connection:**
```
http://localhost:11434
```

**Performance Targets:**
- Generation time: <30s (500 tokens)
- Concurrent requests: 2-3
- Quality: Coherent financial explanations

---

### 6. Prometheus

**Purpose:** Metrics collection and monitoring

**Port:** 9090

**Metrics Collected:**
- Service health (up/down)
- Request rates
- Error rates
- Latencies (p50, p95, p99)
- Cache hit rates
- Model prediction counts
- Queue depths

**Scrape Targets:**
- Prediction Service: `/metrics`
- Explanation Service: `/metrics`
- Ingestion Service: `/metrics`
- Redis Exporter
- PostgreSQL Exporter
- NATS Exporter

**Configuration:**
```yaml
Container: riskee_prometheus
Image: prom/prometheus:latest
Scrape interval: 15s
Retention: 15 days
```

**Connection:**
```
http://localhost:9090
```

---

### 7. Grafana

**Purpose:** Metrics visualization and dashboards

**Port:** 3001

**Credentials:** admin / riskee123

**Dashboards (Planned):**
1. **System Overview**
   - Service health
   - Request rates
   - Error rates
   - Latencies

2. **Prediction Monitoring**
   - Predictions per second (by ticker)
   - Model confidence distribution
   - Prediction accuracy over time
   - Cache hit rates

3. **Model Performance**
   - Accuracy, Precision, Recall, F1
   - Prediction latency
   - Feature importance

4. **Infrastructure Health**
   - CPU, Memory usage
   - Disk I/O
   - Network traffic
   - Database connections

**Configuration:**
```yaml
Container: riskee_grafana
Image: grafana/grafana:latest
Data source: Prometheus
```

**Connection:**
```
http://localhost:3001
```

---

## Network Architecture

### Docker Network
```yaml
Network: riskee_network
Type: bridge
Subnet: 172.20.0.0/16

Services can communicate via:
- Container name (e.g., timescaledb:5432)
- Service name (e.g., redis:6379)
```

### Port Mappings

| Service | Internal Port | External Port | Protocol |
|---------|--------------|---------------|----------|
| TimescaleDB | 5432 | 5432 | PostgreSQL |
| Redis | 6379 | 6379 | Redis |
| NATS Client | 4222 | 4222 | NATS |
| NATS Monitor | 8222 | 8222 | HTTP |
| Qdrant HTTP | 6333 | 6333 | HTTP |
| Qdrant gRPC | 6334 | 6334 | gRPC |
| Ollama | 11434 | 11434 | HTTP |
| Prometheus | 9090 | 9090 | HTTP |
| Grafana | 3000 | 3001 | HTTP |

---

## Data Flow

### 1. Market Data Ingestion

```
External API → Ingestion Service
              ↓
         Publish to NATS (data.market.quote)
              ↓
    ┌─────────┴─────────┐
    ▼                   ▼
Redis Cache      TimescaleDB
(latest quote)   (historical data)
```

### 2. Prediction Pipeline

```
Scheduled Job / API Request
              ↓
    Fetch Features from Redis
              ↓
    Publish to NATS (job.predict.normal)
              ↓
    Prediction Service receives job
              ↓
    Extract Features (if not cached)
              ↓
    Run ML Model
              ↓
    Publish result to NATS (event.prediction.updated)
              ↓
    ┌─────────┴─────────┐
    ▼                   ▼
Redis Cache      TimescaleDB
(pred:{ticker})  (predictions table)
```

### 3. Explanation Pipeline

```
Prediction Created
              ↓
    Publish to NATS (thought.prediction.explain)
              ↓
    Explanation Service receives request
              ↓
    Query Qdrant for similar news/patterns
              ↓
    Build prompt with context
              ↓
    Send to Ollama LLM
              ↓
    Publish result (thought.prediction.explained)
              ↓
    ┌─────────┴─────────┐
    ▼                   ▼
Redis Cache      Return to Client
(explanation:{ticker})
```

---

## Scalability Considerations

### Current (Single Node)
- **Throughput:** ~100 predictions/second
- **Latency:** <1 second end-to-end
- **Concurrent users:** ~10

### Future (Multi-Node)

**Horizontal Scaling:**
- Prediction Service: 3-5 replicas
- Explanation Service: 2-3 replicas
- Ingestion Service: 2-3 replicas

**Database Scaling:**
- TimescaleDB: Read replicas + connection pooling
- Redis: Redis Cluster (sharding)
- NATS: NATS Cluster (3-5 nodes)
- Qdrant: Sharded collections

**Load Balancing:**
- NGINX or Traefik in front of services
- Round-robin for stateless services
- Consistent hashing for cache

---

## High Availability

### Current Setup (Dev)
- Single instance of each service
- Local volumes (data persisted)
- No redundancy

### Production Setup (Future)

**Database HA:**
- TimescaleDB: Streaming replication (1 primary + 2 replicas)
- Redis: Sentinel (1 master + 2 replicas)
- NATS: Cluster (3 nodes, quorum)

**Service HA:**
- Each service: 2+ replicas
- Health checks: Liveness + readiness probes
- Auto-restart on failure

**Data Backup:**
- TimescaleDB: Daily backups to S3
- Redis: RDB snapshots + AOF
- Qdrant: Snapshot backups
- NATS: File-backed streams

---

## Security

### Current (Dev)
- Hardcoded credentials (riskee123)
- No TLS/SSL
- Open ports on localhost

### Production (Future)

**Authentication:**
- PostgreSQL: Strong passwords + SSL
- Redis: ACL + password auth
- NATS: Token authentication
- API: JWT tokens

**Network Security:**
- Internal network (no external access)
- TLS for all connections
- Firewall rules
- Rate limiting

**Data Security:**
- Encrypted at rest (database volumes)
- Encrypted in transit (TLS)
- Secret management (HashiCorp Vault)

---

## Resource Requirements

### Minimum (Development)
- **CPU:** 4 cores
- **Memory:** 16GB RAM
- **Disk:** 50GB SSD
- **GPU:** Optional (Ollama faster with GPU)

### Recommended (Development)
- **CPU:** 8 cores
- **Memory:** 32GB RAM
- **Disk:** 100GB SSD
- **GPU:** NVIDIA GPU (4GB+ VRAM)

### Production (Estimated)
- **CPU:** 16+ cores
- **Memory:** 64GB+ RAM
- **Disk:** 500GB+ SSD
- **GPU:** NVIDIA GPU (8GB+ VRAM) per LLM instance

---

## Monitoring & Alerting

### Metrics to Monitor

**Service Health:**
- All services up/down status
- Restart count
- Error rate

**Performance:**
- Request latency (p50, p95, p99)
- Throughput (requests/sec)
- Queue depths

**Resources:**
- CPU usage
- Memory usage
- Disk usage
- Network bandwidth

**Business:**
- Predictions per minute
- Model accuracy
- Cache hit rate

### Alerts (Future)

**Critical:**
- Service down >5 minutes
- Error rate >5%
- Disk usage >90%

**Warning:**
- Error rate >1%
- Latency >2s (p95)
- Cache hit rate <70%

---

## Disaster Recovery

### Backup Strategy
- **Database:** Daily full + continuous WAL
- **Redis:** Hourly RDB snapshots
- **Code:** Git repository
- **Config:** Version controlled

### Recovery Plan
1. Restore database from latest backup
2. Restore Redis from snapshot (if needed)
3. Redeploy services from git
4. Verify with health checks

**RTO (Recovery Time Objective):** 1 hour
**RPO (Recovery Point Objective):** 1 hour (database) / 1 day (Redis)

---

## Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Services | Single instance | Multiple replicas |
| Data | Sample data | Real market data |
| Persistence | Local volumes | Cloud storage |
| Monitoring | Basic (Prometheus) | Full (Prometheus + Grafana + Alerts) |
| Security | Open/hardcoded | Locked down/secrets |
| Backup | Manual | Automated hourly |
| Logging | Console | Centralized (ELK) |

---

**Last Updated:** 2025-12-19
**Document Owner:** DevOps Team
**Next Review:** 2026-01-19
