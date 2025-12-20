# Scripts Directory

This directory contains all operational scripts for the Riskee project. Scripts are organized by function and available in both Bash (Linux/Mac) and PowerShell (Windows) versions where applicable.

---

## Quick Reference

### Database Management
```bash
# Reset database (drop and recreate)
./scripts/db_reset.sh                    # Linux/Mac
.\scripts\db_reset.ps1                   # Windows

# Backup database
./scripts/db_backup.sh [backup_name]
.\scripts\db_backup.ps1 [backup_name]

# Restore from backup
./scripts/db_restore.sh backup_name
.\scripts\db_restore.ps1 backup_name
```

### Migrations
```bash
# Upgrade to latest
./scripts/manage_migrations.sh upgrade
.\scripts\manage_migrations.ps1 upgrade

# Create new migration
./scripts/manage_migrations.sh create "migration_name"
.\scripts\manage_migrations.ps1 create "migration_name"

# View history
./scripts/manage_migrations.sh history
.\scripts\manage_migrations.ps1 history
```

### Redis Operations
```bash
# Inspect keys and memory
./scripts/redis_inspect.sh [pattern]
.\scripts\redis_inspect.ps1 [pattern]

# Test Redis operations
./scripts/test_redis.sh
```

### NATS Debugging
```bash
# Publish test message
python scripts/nats_publish.py <subject> <message>

# Subscribe to messages
python scripts/nats_subscribe.py <subject>

# Inspect streams
python scripts/nats_stream_info.py [stream_name]

# Test pub/sub
python scripts/test_nats_pubsub.py
```

### Service Setup & Testing
```bash
# Setup Qdrant collections
python scripts/setup_qdrant.py

# Test Ollama models
python scripts/setup_ollama.py

# Verify all services
./scripts/verify_startup.sh
.\scripts\verify_startup.ps1
```

### Development Environment
```bash
# Setup dev environment
./scripts/setup_dev_environment.sh
.\scripts\setup_dev_environment.ps1
```

---

## Script Categories

### 1. Database Scripts

#### `db_reset.sh` / `db_reset.ps1`
**Purpose:** Drop all tables and recreate schema from scratch

**Usage:**
```bash
./scripts/db_reset.sh
```

**What it does:**
1. Prompts for confirmation (safety check)
2. Drops all tables in correct order
3. Recreates schema from `init_timescaledb.sql`
4. Verifies tables were created

**When to use:**
- Fresh start needed
- Schema corruption
- After major schema changes

**Warning:** All data will be lost!

---

#### `db_backup.sh` / `db_backup.ps1`
**Purpose:** Create a backup of the database

**Usage:**
```bash
./scripts/db_backup.sh                    # Auto-timestamped
./scripts/db_backup.sh my_backup          # Custom name
```

**Output:** `backups/backup_YYYYMMDD_HHMMSS.sql.gz` (Bash version compressed)

**What it does:**
1. Creates pg_dump of database
2. Compresses with gzip (Bash)
3. Reports file size
4. Provides restore instructions

**When to use:**
- Before major changes
- Daily backups (cron job)
- Before migrations

---

#### `db_restore.sh` / `db_restore.ps1`
**Purpose:** Restore database from backup

**Usage:**
```bash
./scripts/db_restore.sh backup_20251219_100000
```

**What it does:**
1. Validates backup file exists
2. Prompts for confirmation
3. Drops existing tables
4. Restores from backup
5. Verifies tables

**When to use:**
- Recover from error
- Restore specific state
- Test with production data

---

#### `redis_inspect.sh` / `redis_inspect.ps1`
**Purpose:** Inspect Redis keys, memory, and cache statistics

**Usage:**
```bash
./scripts/redis_inspect.sh              # All keys
./scripts/redis_inspect.sh "pred:*"     # Specific pattern
```

**What it shows:**
1. Connection status
2. Memory usage (used, peak, max)
3. Total key count
4. Keys by pattern (with TTL)
5. Key count by prefix
6. Cache hit rate

**When to use:**
- Debug cache issues
- Monitor memory usage
- Find expired keys
- Check cache performance

---

### 2. Migration Scripts

#### `manage_migrations.sh` / `manage_migrations.ps1`
**Purpose:** Manage Alembic database migrations

**Commands:**
```bash
# Apply all pending migrations
./scripts/manage_migrations.sh upgrade

# Rollback last migration
./scripts/manage_migrations.sh downgrade

# Show current version
./scripts/manage_migrations.sh current

# Show migration history
./scripts/manage_migrations.sh history

# Create new migration
./scripts/manage_migrations.sh create "add_user_table"

# Reset database (drop all)
./scripts/manage_migrations.sh reset
```

**When to use:**
- Schema changes
- Version control for database
- Team collaboration
- Production deployments

---

### 3. NATS Scripts

#### `nats_publish.py`
**Purpose:** Publish test messages to NATS subjects

**Usage:**
```bash
python scripts/nats_publish.py data.market.quote '{"ticker":"AAPL","price":155.50}'
python scripts/nats_publish.py event.prediction.updated "Test message"
```

**Features:**
- JSON auto-detection
- Pretty printing
- Size reporting
- Timestamp tracking

**Supported subjects:**
- `data.market.*` - Market data
- `event.prediction.*` - Prediction events
- `job.predict.*` - Prediction jobs
- `thought.*` - LLM explanations

---

#### `nats_subscribe.py`
**Purpose:** Subscribe and view messages in real-time

**Usage:**
```bash
python scripts/nats_subscribe.py data.market.quote     # Specific subject
python scripts/nats_subscribe.py 'data.market.*'      # Wildcard
python scripts/nats_subscribe.py 'event.>'            # All events
```

**Features:**
- Wildcard support (* and >)
- JSON auto-parsing
- Message counter
- Ctrl+C graceful shutdown

**Wildcards:**
- `*` - Matches one token (e.g., `data.market.*`)
- `>` - Matches one or more tokens (e.g., `data.>`)

---

#### `nats_stream_info.py`
**Purpose:** Inspect JetStream streams

**Usage:**
```bash
python scripts/nats_stream_info.py                # List all streams
python scripts/nats_stream_info.py PREDICTIONS    # Stream details
```

**What it shows:**
- Stream configuration (subjects, retention, storage)
- Current state (messages, bytes, consumers)
- First/last message times
- Human-readable formatting

**When to use:**
- Monitor stream health
- Debug message flow
- Check retention policies
- Verify stream creation

---

#### `test_nats_pubsub.py`
**Purpose:** Complete NATS pub/sub integration test

**Usage:**
```bash
python scripts/test_nats_pubsub.py
```

**What it tests:**
1. Creates test stream
2. Publishes messages
3. Subscribes and consumes
4. Verifies message order
5. Tests acknowledgment
6. Cleans up

**When to use:**
- Verify NATS setup
- Test message flow
- Integration testing
- CI/CD validation

---

### 4. Service Setup Scripts

#### `setup_qdrant.py`
**Purpose:** Create and verify Qdrant vector collections

**Usage:**
```bash
python scripts/setup_qdrant.py
```

**What it does:**
1. Creates 5 RAG collections:
   - market_news (768 dims)
   - earnings_calls (768 dims)
   - economic_indicators (768 dims)
   - technical_patterns (768 dims)
   - prediction_context (768 dims)
2. Tests vector insertion
3. Tests similarity search
4. Reports status

**When to use:**
- Initial setup
- Reset collections
- Verify Qdrant working

---

#### `setup_ollama.py`
**Purpose:** Test Ollama LLM models

**Usage:**
```bash
python scripts/setup_ollama.py
```

**What it does:**
1. Lists available models
2. Tests generation with gemma3:4b
3. Measures generation time
4. Reports model details

**When to use:**
- Verify Ollama setup
- Test model performance
- Check available models

---

#### `test_redis.sh`
**Purpose:** Validate Redis operations

**Usage:**
```bash
./scripts/test_redis.sh
```

**What it tests:**
1. PING connection
2. SET/GET operations
3. TTL (expiry)
4. HASH operations
5. Keyspace statistics

**When to use:**
- Verify Redis setup
- Test cache operations
- Integration testing

---

### 5. Verification Scripts

#### `verify_startup.sh` / `verify_startup.ps1`
**Purpose:** Comprehensive health check for all services

**Usage:**
```bash
./scripts/verify_startup.sh
```

**What it checks:**
1. Docker daemon
2. TimescaleDB (connection, extension, tables)
3. Redis (connection, memory)
4. NATS JetStream (connectivity, streams)
5. Qdrant (API, collections)
6. Ollama (service, models)
7. Prometheus (API, targets)
8. Grafana (UI health)

**Features:**
- Retry logic (5 attempts)
- Colored output
- Pass/fail summary
- Service URLs reference
- Troubleshooting tips

**When to use:**
- After `docker-compose up`
- Before development
- CI/CD health checks
- Troubleshooting

---

### 6. Development Scripts

#### `setup_dev_environment.sh` / `setup_dev_environment.ps1`
**Purpose:** Automated development environment setup

**Usage:**
```bash
./scripts/setup_dev_environment.sh
```

**What it does:**
1. Checks Python version (3.11+)
2. Creates virtual environment
3. Installs dependencies
4. Installs pre-commit hooks
5. Runs initial checks

**When to use:**
- New developer onboarding
- Fresh clone setup
- After dependencies change

---

## Environment Variables

Scripts use these environment variables (with defaults):

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=riskee
DB_USER=postgres
DB_PASSWORD=riskee123

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# NATS
NATS_URL=nats://localhost:4222

# Qdrant
QDRANT_HOST=localhost
QDRANT_PORT=6333

# Ollama
OLLAMA_HOST=http://localhost:11434
```

---

## Common Workflows

### Daily Development
```bash
# 1. Start services
docker-compose up -d

# 2. Verify all healthy
./scripts/verify_startup.sh

# 3. Activate venv
source venv/bin/activate

# 4. Start coding!
```

### Before Major Changes
```bash
# 1. Backup database
./scripts/db_backup.sh before_feature_x

# 2. Make changes...

# 3. If needed, restore
./scripts/db_restore.sh before_feature_x
```

### Schema Changes
```bash
# 1. Create migration
./scripts/manage_migrations.sh create "add_new_column"

# 2. Edit migration file in migrations/versions/

# 3. Apply migration
./scripts/manage_migrations.sh upgrade

# 4. Test changes

# 5. If error, rollback
./scripts/manage_migrations.sh downgrade
```

### Debugging Messages
```bash
# Terminal 1: Subscribe to all prediction events
python scripts/nats_subscribe.py 'event.prediction.*'

# Terminal 2: Publish test message
python scripts/nats_publish.py event.prediction.updated '{"ticker":"AAPL","price":155.50}'

# Terminal 1 will show the message
```

### Redis Debugging
```bash
# 1. Check what keys exist
./scripts/redis_inspect.sh

# 2. Check specific pattern
./scripts/redis_inspect.sh "pred:*"

# 3. Check cache hit rate
./scripts/redis_inspect.sh  # Shows cache statistics
```

---

## Troubleshooting

### Script won't run (Bash)
```bash
# Make executable
chmod +x scripts/*.sh

# Or run with bash
bash scripts/verify_startup.sh
```

### Script won't run (PowerShell)
```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with explicit path
powershell -ExecutionPolicy Bypass -File .\scripts\verify_startup.ps1
```

### Connection errors
```bash
# Check services are running
docker-compose ps

# Check specific service logs
docker-compose logs timescaledb
docker-compose logs redis
docker-compose logs nats
```

### Python scripts fail
```bash
# Ensure dependencies installed
pip install -r scripts/requirements.txt

# Or use dev setup
./scripts/setup_dev_environment.sh
```

---

## Adding New Scripts

When adding new scripts, follow these guidelines:

1. **Naming:** Use descriptive names (verb_noun.sh)
2. **Cross-platform:** Provide both `.sh` and `.ps1` versions
3. **Documentation:** Add to this README
4. **Comments:** Include usage comments in script
5. **Error handling:** Use `set -e` (Bash) or `$ErrorActionPreference` (PowerShell)
6. **Colors:** Use consistent color coding
7. **Confirmation:** Prompt before destructive operations

---

**Last Updated:** 2025-12-19
