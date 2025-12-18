# Developer Getting Started Guide - Windows PowerShell

**Feature 1: Real-Time Price Prediction System**
**Last Updated:** 2025-12-17
**For:** Windows developers using PowerShell

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites

Before you begin, ensure you have:

- **Docker Desktop 24.0+** ([Download](https://www.docker.com/products/docker-desktop))
- **Git** ([Download](https://git-scm.com/downloads))
- **Python 3.11+** ([Download](https://www.python.org/downloads/))
- **VS Code** (recommended) ([Download](https://code.visualstudio.com/))
- **PowerShell 5.1+** (included with Windows)

### 1. Clone the Repository

```powershell
# Open PowerShell
git clone https://github.com/Jaisree25/riskee.git
cd riskee
```

### 2. Start All Services

```powershell
# Start Docker Desktop first (if not running)
# You can check if Docker is running with:
docker ps

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

```powershell
# Create virtual environment (recommended)
python -m venv .venv

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# If you get execution policy error, run:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install dependencies
pip install -r scripts/requirements.txt
```

### 4. Initialize Infrastructure

```powershell
# Set up Qdrant vector collections
python scripts/setup_qdrant.py

# Verify Ollama LLM models
python scripts/setup_ollama.py

# Test Redis cache (use Git Bash or WSL for bash scripts)
# Or test manually:
docker exec riskee_redis redis-cli PING
# Should return: PONG
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

## 💻 PowerShell-Specific Commands

### Testing Services with PowerShell

**Test NATS:**
```powershell
Invoke-RestMethod -Uri "http://localhost:8222/healthz"
# Should return: @{status=ok}
```

**Test Qdrant:**
```powershell
Invoke-RestMethod -Uri "http://localhost:6333/collections" | ConvertTo-Json -Depth 3
```

**Test Ollama:**
```powershell
Invoke-RestMethod -Uri "http://localhost:11434/api/tags" | ConvertTo-Json -Depth 3
```

**Test Ollama Generation:**
```powershell
$body = @{
    model = "gemma3:4b"
    prompt = "Explain why AAPL stock might increase in 1 sentence."
    stream = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json"
```

**Test Redis:**
```powershell
docker exec riskee_redis redis-cli PING
docker exec riskee_redis redis-cli SET test_key "Hello from PowerShell"
docker exec riskee_redis redis-cli GET test_key
```

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

## 🗄️ Database Access (Windows)

### Connect to TimescaleDB

**Option 1: Using Docker (Recommended)**
```powershell
docker exec -it riskee_timescaledb psql -U postgres -d riskee
```

**Option 2: Using psql (if installed)**
```powershell
# Set password as environment variable
$env:PGPASSWORD="riskee123"
psql -h localhost -U postgres -d riskee

# Common SQL commands once connected:
# \dt              - List tables
# \d predictions   - Describe table
# \q               - Quit
```

**Option 3: Using DBeaver or pgAdmin**
- Host: `localhost`
- Port: `5432`
- Database: `riskee`
- Username: `postgres`
- Password: `riskee123`

### Query Examples

```powershell
# Count predictions
docker exec -it riskee_timescaledb psql -U postgres -d riskee -c "SELECT COUNT(*) FROM predictions;"

# View table structure
docker exec -it riskee_timescaledb psql -U postgres -d riskee -c "\d predictions"

# Check hypertables
docker exec -it riskee_timescaledb psql -U postgres -d riskee -c "SELECT * FROM timescaledb_information.hypertables;"
```

---

## 📊 Qdrant Vector Collections

**5 RAG Collections** (768 dimensions, COSINE distance):

1. `market_news` - Financial news and commentary
2. `earnings_calls` - Earnings call transcripts
3. `economic_indicators` - Economic reports
4. `technical_patterns` - Technical analysis patterns
5. `prediction_context` - Historical prediction contexts

**Query Example (PowerShell):**
```powershell
# List collections
$collections = Invoke-RestMethod -Uri "http://localhost:6333/collections"
$collections.result.collections | Format-Table

# Get collection info
Invoke-RestMethod -Uri "http://localhost:6333/collections/market_news" | ConvertTo-Json -Depth 5
```

**Python Example:**
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

## 🔄 NATS JetStream Testing

**PowerShell Health Check:**
```powershell
# Check NATS health
Invoke-RestMethod -Uri "http://localhost:8222/healthz"

# Get JetStream info
Invoke-RestMethod -Uri "http://localhost:8222/jsz" | ConvertTo-Json -Depth 3

# Get server stats
Invoke-RestMethod -Uri "http://localhost:8222/varz" | ConvertTo-Json -Depth 2
```

**Python Pub/Sub Test:**
```powershell
# Run the test script
python scripts/test_nats_pubsub.py
```

---

## 🤖 Ollama LLM Models

**Available Models:**

1. **gemma3:4b** (3.2 GB) - Fast, good quality ✓ Tested
2. **mistral:7b** (4.2 GB) - Balanced performance
3. **tinyllama:latest** (608 MB) - Lightweight testing

**Test with PowerShell:**
```powershell
# List models
Invoke-RestMethod -Uri "http://localhost:11434/api/tags" | ConvertTo-Json -Depth 3

# Generate text
$prompt = @{
    model = "gemma3:4b"
    prompt = "Explain in one sentence why AAPL stock might increase tomorrow."
    stream = $false
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $prompt -ContentType "application/json"
$response.response
```

**Test with Python:**
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

### PowerShell Health Check Script

```powershell
# Create a simple health check script
$services = @(
    @{Name="NATS"; Url="http://localhost:8222/healthz"},
    @{Name="Qdrant"; Url="http://localhost:6333/collections"},
    @{Name="Ollama"; Url="http://localhost:11434/api/tags"},
    @{Name="Prometheus"; Url="http://localhost:9090"}
)

Write-Host "`n=== Service Health Check ===" -ForegroundColor Cyan

foreach ($service in $services) {
    try {
        $response = Invoke-RestMethod -Uri $service.Url -TimeoutSec 5
        Write-Host "[OK] $($service.Name) is responding" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] $($service.Name) is not responding" -ForegroundColor Red
    }
}

# Check Docker services
Write-Host "`n=== Docker Services ===" -ForegroundColor Cyan
docker-compose ps
```

### Manual Verification

**1. Check Docker Services:**
```powershell
docker-compose ps
# All services should show "Up" or "healthy"
```

**2. Test TimescaleDB:**
```powershell
docker exec riskee_timescaledb psql -U postgres -d riskee -c "SELECT COUNT(*) FROM predictions;"
```

**3. Test Redis:**
```powershell
docker exec riskee_redis redis-cli PING
# Should return: PONG
```

**4. Test NATS:**
```powershell
Invoke-RestMethod -Uri "http://localhost:8222/healthz"
# Should return: @{status=ok}
```

**5. Test Qdrant:**
```powershell
(Invoke-RestMethod -Uri "http://localhost:6333/collections").result.collections.Count
# Should return: 5
```

**6. Test Ollama:**
```powershell
(Invoke-RestMethod -Uri "http://localhost:11434/api/tags").models.Count
# Should return: 3
```

---

## 🛠️ Common Tasks (PowerShell)

### Stop All Services
```powershell
docker-compose down
```

### Restart Specific Service
```powershell
docker-compose restart timescaledb
```

### View Logs
```powershell
# All services
docker-compose logs

# Specific service
docker-compose logs -f timescaledb

# Last 100 lines
docker-compose logs --tail=100
```

### Clean Up Everything
```powershell
# Stop and remove containers, networks
docker-compose down

# Also remove volumes (WARNING: deletes all data!)
docker-compose down -v
```

### Reset Database
```powershell
# Stop database
docker-compose stop timescaledb

# Remove volume
docker volume rm riskee_timescaledb_data

# Restart
docker-compose up -d timescaledb

# Wait a few seconds, then re-initialize schema
Start-Sleep -Seconds 10
Get-Content scripts\db\init\01_init_schema.sql | docker exec -i riskee_timescaledb psql -U postgres -d riskee
```

### Check Port Usage (Windows)
```powershell
# Find what's using a specific port
netstat -ano | Select-String ":5432"
netstat -ano | Select-String ":6379"
netstat -ano | Select-String ":11434"

# Kill process by PID (if needed)
# Stop-Process -Id <PID> -Force
```

---

## 🐛 Troubleshooting (Windows-Specific)

### Issue: "Cannot connect to Docker daemon"

**Solution:**
```powershell
# Check if Docker Desktop is running
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

# If not running, start Docker Desktop from Start Menu
# Then verify:
docker ps
```

### Issue: PowerShell Execution Policy Error

**Solution:**
```powershell
# Allow script execution for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy -List
```

### Issue: Port Already in Use

**Solution:**
```powershell
# Find process using port
$port = 5432  # Change to your port
$process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($process) {
    Get-Process -Id $process | Select-Object Id, ProcessName, Path
    # Stop-Process -Id $process -Force  # Uncomment to kill
}
```

### Issue: Line Ending Warnings (CRLF)

**Solution:**
```powershell
# Configure Git to handle line endings
git config --global core.autocrlf true

# This is cosmetic - doesn't affect functionality
```

### Issue: Docker Container Won't Start

**Solution:**
```powershell
# Check logs for specific container
docker-compose logs timescaledb

# Try recreating the container
docker-compose up -d --force-recreate timescaledb

# If all else fails, remove and recreate
docker-compose down
docker-compose up -d
```

### Issue: Slow Docker Performance on Windows

**Solutions:**
1. Enable WSL 2 backend in Docker Desktop settings
2. Allocate more resources in Docker Desktop → Settings → Resources
3. Move project to WSL filesystem for better performance:
   ```powershell
   # From PowerShell, access WSL
   wsl
   # Then clone repo in WSL home directory
   ```

### Issue: Python not found

**Solution:**
```powershell
# Add Python to PATH
# Windows Settings → System → About → Advanced System Settings → Environment Variables
# Add Python installation directory to PATH

# Or use Python launcher
py --version
py -m venv .venv
```

---

## 📚 Documentation

### Key Documents

- **[DEV_GETTING_STARTED.md](DEV_GETTING_STARTED.md)** - General getting started (Bash-oriented)
- **[Progress Summary](docs/PROGRESS_SUMMARY.md)** - Current project status
- **[Daily Journal](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)** - Daily progress log
- **[Architecture](docs/ver_0_1/Feature_1_PricePrediction/01_Architecture_Overview.md)** - System architecture

---

## 🔐 Security Notes

### Development Environment Only

⚠️ **WARNING:** Current setup is for **development only**!

**Never use in production:**
- Default passwords (`riskee123`)
- No authentication on some services
- No TLS/SSL encryption
- Exposed ports without firewall

---

## ✅ Verification Checklist

Use this checklist to verify your setup is complete:

```powershell
# Quick verification script
Write-Host "`n=== Setup Verification Checklist ===" -ForegroundColor Cyan

$checks = @(
    @{Name="Docker running"; Command={docker ps | Out-Null}},
    @{Name="All 7 services up"; Command={(docker-compose ps | Where-Object {$_ -match "Up"}).Count -ge 7}},
    @{Name="Grafana accessible"; Command={Invoke-RestMethod -Uri "http://localhost:3001" -UseBasicParsing | Out-Null}},
    @{Name="Prometheus accessible"; Command={Invoke-RestMethod -Uri "http://localhost:9090" | Out-Null}},
    @{Name="Qdrant collections (5)"; Command={(Invoke-RestMethod -Uri "http://localhost:6333/collections").result.collections.Count -eq 5}},
    @{Name="Ollama models (3)"; Command={(Invoke-RestMethod -Uri "http://localhost:11434/api/tags").models.Count -ge 3}},
    @{Name="Redis responding"; Command={docker exec riskee_redis redis-cli PING | Out-Null}},
    @{Name="Python installed"; Command={python --version | Out-Null}}
)

foreach ($check in $checks) {
    try {
        & $check.Command
        Write-Host "[OK] $($check.Name)" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $($check.Name)" -ForegroundColor Red
    }
}
```

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

**Common PowerShell Commands:**
```powershell
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Restart service
docker-compose restart timescaledb

# Database access
docker exec -it riskee_timescaledb psql -U postgres -d riskee

# Redis access
docker exec -it riskee_redis redis-cli

# Health checks
Invoke-RestMethod -Uri "http://localhost:8222/healthz"     # NATS
Invoke-RestMethod -Uri "http://localhost:6333/collections" # Qdrant
```

---

## 🎓 Next Steps for Windows Developers

### Recommended Tools

1. **Windows Terminal** - Better terminal experience
   - Install from Microsoft Store
   - Supports PowerShell, CMD, WSL

2. **WSL 2** - Linux subsystem for Windows
   - `wsl --install` (requires admin)
   - Better Docker performance
   - Native Linux tools

3. **VS Code Extensions**
   - Docker
   - Python
   - PostgreSQL (by Chris Kolkman)
   - PowerShell

4. **Database Clients**
   - DBeaver (free, universal)
   - pgAdmin 4 (PostgreSQL-specific)

### Development Workflow

1. Open project in VS Code
2. Use integrated terminal (PowerShell or WSL)
3. Start services with Docker Compose
4. Develop in your preferred environment
5. Test with provided scripts
6. Commit and push to GitHub

---

**Welcome to the team! 🎉**

For Windows-specific issues, check the troubleshooting section or ask for help on Slack.

Happy coding! 💻
