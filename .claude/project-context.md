# Project Context: Feature 1 - Real-Time Price Prediction System

## Current Status

**Active Milestone:** M1 - Foundation & Infrastructure Setup
**Duration:** Week 1-2 (10 working days)
**Status:** Not Started
**Last Updated:** 2025-12-16

## Quick Links

- **Milestone Tracker:** [docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md](../docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)
- **M1 Plan:** [docs/ver_0_1/Feature_1_PricePrediction/milestones/M1_Foundation_Infrastructure.md](../docs/ver_0_1/Feature_1_PricePrediction/milestones/M1_Foundation_Infrastructure.md)
- **Architecture:** [docs/ver_0_1/Feature_1_PricePrediction/01_Architecture_Overview.md](../docs/ver_0_1/Feature_1_PricePrediction/01_Architecture_Overview.md)

## Project Overview

This is a 12-14 week project to build an AI-powered real-time stock price prediction system with the following components:

1. **Data Ingestion:** Yahoo Finance API → NATS
2. **Feature Engineering:** 20 technical indicators (NumPy/Pandas)
3. **ML Models:** LSTM (Normal Day + Earnings Day)
4. **Prediction Pipeline:** GPU-accelerated inference
5. **LLM Explanations:** RAG with Llama 3.1 8B via Ollama + LangChain
6. **API Gateway:** FastAPI + WebSocket
7. **UI:** Next.js 14 + React
8. **Infrastructure:** Docker Compose, TimescaleDB, Redis, NATS, Qdrant

## Current Work (M1)

### Focus Areas
- Setting up Docker Compose infrastructure
- Configuring databases (TimescaleDB, Redis)
- Setting up message bus (NATS JetStream)
- Setting up vector database (Qdrant)
- Setting up LLM (Ollama with Llama 3.1 8B)
- Implementing monitoring (Prometheus + Grafana)

### Key Deliverables
- [ ] docker-compose.yml with all services
- [ ] Database schemas created
- [ ] NATS streams configured
- [ ] Health check endpoints
- [ ] Monitoring dashboards
- [ ] Developer documentation

## Project Structure

```
riskee/
├── .vscode/              # VS Code settings (configured)
├── .claude/              # Claude Code context (this file)
├── docs/                 # Documentation
│   └── ver_0_1/
│       └── Feature_1_PricePrediction/
│           ├── 01_Architecture_Overview.md
│           ├── 02_Design_Specification.md
│           └── milestones/
│               ├── M1/
│               │   └── journal.md  # Daily progress tracking
│               ├── M1_Foundation_Infrastructure.md
│               ├── M2_Data_Ingestion.md
│               └── ... (M3-M9)
├── services/             # Microservices (to be created)
│   ├── ingestion_agent/
│   ├── feature_store/
│   ├── prediction_normal_agent/
│   ├── prediction_earnings_agent/
│   ├── explanation_worker/
│   ├── api_gateway/
│   └── ui/
├── models/               # ML models (to be created)
│   ├── normal_day/
│   └── earnings_day/
├── data/                 # Data files (to be created)
│   ├── playbooks/
│   └── edgar/
├── tests/                # Tests (to be created)
├── scripts/              # Utility scripts (to be created)
├── docker-compose.yml    # Infrastructure (to be created)
├── requirements.txt      # Python dependencies (to be created)
└── README.md             # Project README (to be created)
```

## Technology Stack

### Backend
- **Language:** Python 3.11+
- **Framework:** FastAPI
- **Databases:** TimescaleDB (PostgreSQL 15), Redis 7
- **Message Bus:** NATS JetStream
- **Vector DB:** Qdrant
- **ML:** TensorFlow/Keras, ONNX Runtime
- **LLM:** Llama 3.1 8B via Ollama
- **LLM Framework:** LangChain

### Frontend
- **Framework:** Next.js 14 (React)
- **Styling:** Tailwind CSS
- **State:** Zustand
- **Charts:** Recharts or TradingView

### Infrastructure
- **Containerization:** Docker + Docker Compose
- **Monitoring:** Prometheus + Grafana
- **Logging:** Structured JSON logging

## Key Performance Targets

- Prediction retrieval: p95 < 100ms
- Full pipeline update: < 10 seconds (5,000 symbols)
- Model accuracy (MAE): < 1.5% (normal), < 2.5% (earnings)
- Explanation generation: < 3 seconds
- WebSocket connections: 10,000+ concurrent
- System availability: 99.5%

## Team Roles

- **DevOps Lead:** Infrastructure, Docker, deployment
- **Backend Dev 1:** API Gateway, ingestion, features
- **Backend Dev 2:** Storage, WebSocket, monitoring
- **Data Scientist 1:** ML models (Normal Day)
- **Data Scientist 2:** ML models (Earnings Day)
- **AI/ML Dev:** LLM, RAG, LangChain integration
- **Frontend Dev 1:** Next.js, dashboard, charts
- **Frontend Dev 2:** Components, WebSocket integration
- **Full Stack Dev:** Integration, testing
- **Tech Lead:** Architecture, reviews, coordination
- **Product Owner:** Requirements, acceptance, demos

## Workflow

1. **Daily Updates:** Team members update [M1/journal.md](../docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)
2. **Task Tracking:** Check boxes in milestone documents
3. **Code Reviews:** 2 approvals required before merge
4. **Testing:** >80% code coverage required
5. **Documentation:** Update as you build

## Common Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Run tests
pytest tests/ -v --cov

# Lint code
ruff check .

# Format code
ruff format .

# Connect to TimescaleDB
docker exec -it riskee_timescaledb_1 psql -U postgres -d riskee

# Connect to Redis
docker exec -it riskee_redis_1 redis-cli

# Open Grafana
open http://localhost:3001

# Open API docs
open http://localhost:8000/api/docs
```

## Important Notes

- **GPU Required:** For ML model training and inference (NVIDIA with 16GB+ VRAM recommended)
- **Rate Limits:** Yahoo Finance API has rate limits; consider paid tier if needed
- **LangChain:** Fully integrated in M6 for RAG-based explanations
- **Security:** Never commit API keys, secrets, or .env files
- **Testing:** Write tests as you build, not after
- **Documentation:** Keep journal.md updated daily

## Next Steps (M1)

1. Create GitHub repository
2. Set up Python virtual environment
3. Create docker-compose.yml
4. Start with TimescaleDB and Redis
5. Add NATS, Qdrant, Ollama
6. Configure monitoring (Prometheus, Grafana)
7. Write smoke tests
8. Document setup process

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [TimescaleDB Docs](https://docs.timescale.com/)
- [NATS Documentation](https://docs.nats.io/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [LangChain Documentation](https://python.langchain.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Next.js Documentation](https://nextjs.org/docs)

## Context for AI Assistants

When working on this project:
1. Check the current milestone (M1) and its journal
2. Refer to the architecture document for design decisions
3. Follow the task list in the milestone plan
4. Update the journal with progress and decisions
5. Maintain coding standards (Ruff formatting, type hints, docstrings)
6. Write tests for all new code
7. Update documentation as you go

---

**Last Context Update:** 2025-12-16
**Updated By:** Tech Lead
**Current Focus:** M1 - Infrastructure Setup
