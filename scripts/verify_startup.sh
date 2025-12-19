#!/bin/bash
# Startup verification script - checks all services are healthy
# Usage: ./scripts/verify_startup.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to print section header
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to check service
check_service() {
    local service_name=$1
    local check_command=$2
    local success_msg=$3

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -n "Checking $service_name... "

    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} $success_msg"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}[FAIL]${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# Function to check with retry
check_with_retry() {
    local service_name=$1
    local check_command=$2
    local success_msg=$3
    local max_retries=5
    local retry_delay=2

    for i in $(seq 1 $max_retries); do
        if check_service "$service_name" "$check_command" "$success_msg"; then
            return 0
        fi
        if [ $i -lt $max_retries ]; then
            echo -e "${YELLOW}  Retrying in ${retry_delay}s... (attempt $((i+1))/$max_retries)${NC}"
            sleep $retry_delay
        fi
    done
    return 1
}

print_header "Riskee Startup Verification"
echo "Checking all infrastructure services..."
echo "Started at: $(date)"

# 1. Docker Services
print_header "1. Docker Services"

check_service "Docker daemon" \
    "docker info" \
    "Docker is running"

check_service "Docker Compose services" \
    "docker-compose ps | grep -q Up" \
    "Services are up"

# 2. TimescaleDB
print_header "2. TimescaleDB (PostgreSQL + TimescaleDB)"

check_with_retry "TimescaleDB connection" \
    "PGPASSWORD=riskee123 psql -h localhost -p 5432 -U postgres -d riskee -c 'SELECT 1' " \
    "Connected to PostgreSQL"

check_service "TimescaleDB extension" \
    "PGPASSWORD=riskee123 psql -h localhost -p 5432 -U postgres -d riskee -c \"SELECT extname FROM pg_extension WHERE extname='timescaledb'\" | grep -q timescaledb" \
    "TimescaleDB extension loaded"

check_service "Predictions table" \
    "PGPASSWORD=riskee123 psql -h localhost -p 5432 -U postgres -d riskee -c \"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'predictions')\" | grep -q t" \
    "Predictions table exists"

# 3. Redis
print_header "3. Redis"

check_with_retry "Redis connection" \
    "redis-cli -h localhost -p 6379 PING | grep -q PONG" \
    "Redis is responding"

check_service "Redis memory" \
    "redis-cli INFO memory | grep -q used_memory" \
    "Redis memory stats available"

# 4. NATS JetStream
print_header "4. NATS JetStream"

check_with_retry "NATS connectivity" \
    "curl -s http://localhost:8222/healthz | grep -q ok" \
    "NATS is healthy"

check_service "JetStream enabled" \
    "curl -s http://localhost:8222/jsz | grep -q '\"config\"'" \
    "JetStream is enabled"

# 5. Qdrant
print_header "5. Qdrant Vector Database"

check_with_retry "Qdrant API" \
    "curl -s http://localhost:6333 | grep -q qdrant" \
    "Qdrant API responding"

check_service "Qdrant collections" \
    "curl -s http://localhost:6333/collections | grep -q result" \
    "Collections endpoint working"

# 6. Ollama
print_header "6. Ollama (LLM)"

check_with_retry "Ollama service" \
    "curl -s http://localhost:11434/api/tags" \
    "Ollama API responding"

check_service "Ollama models loaded" \
    "curl -s http://localhost:11434/api/tags | grep -q models" \
    "Models available"

# 7. Prometheus
print_header "7. Prometheus"

check_with_retry "Prometheus API" \
    "curl -s http://localhost:9090/-/healthy | grep -q Prometheus" \
    "Prometheus is healthy"

check_service "Prometheus targets" \
    "curl -s http://localhost:9090/api/v1/targets" \
    "Targets endpoint responding"

# 8. Grafana
print_header "8. Grafana"

check_with_retry "Grafana UI" \
    "curl -s http://localhost:3001/api/health | grep -q ok" \
    "Grafana is healthy"

# Summary
print_header "Verification Summary"

echo ""
echo "Total checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
fi

echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ALL SYSTEMS OPERATIONAL ✓${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "You can now start development!"
    echo ""
    echo "Service URLs:"
    echo "  TimescaleDB:  postgresql://localhost:5432/riskee"
    echo "  Redis:        redis://localhost:6379"
    echo "  NATS:         http://localhost:8222"
    echo "  Qdrant:       http://localhost:6333/dashboard"
    echo "  Ollama:       http://localhost:11434"
    echo "  Prometheus:   http://localhost:9090"
    echo "  Grafana:      http://localhost:3001 (admin/riskee123)"
    echo ""
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  SOME CHECKS FAILED${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check Docker services: docker-compose ps"
    echo "  2. View logs: docker-compose logs [service_name]"
    echo "  3. Restart services: docker-compose restart [service_name]"
    echo "  4. Full restart: docker-compose down && docker-compose up -d"
    echo ""
    exit 1
fi
