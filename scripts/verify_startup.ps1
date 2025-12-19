# Startup verification script for Windows
# Usage: .\scripts\verify_startup.ps1

$ErrorActionPreference = "Continue"

# Counters
$script:TotalChecks = 0
$script:PassedChecks = 0
$script:FailedChecks = 0

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Text -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
}

function Test-Service {
    param(
        [string]$ServiceName,
        [scriptblock]$CheckCommand,
        [string]$SuccessMessage
    )

    $script:TotalChecks++
    Write-Host "Checking $ServiceName... " -NoNewline

    try {
        $result = & $CheckCommand
        if ($result) {
            Write-Host "[OK]" -ForegroundColor Green -NoNewline
            Write-Host " $SuccessMessage"
            $script:PassedChecks++
            return $true
        }
    } catch {
        # Silently fail
    }

    Write-Host "[FAIL]" -ForegroundColor Red
    $script:FailedChecks++
    return $false
}

function Test-ServiceWithRetry {
    param(
        [string]$ServiceName,
        [scriptblock]$CheckCommand,
        [string]$SuccessMessage,
        [int]$MaxRetries = 5,
        [int]$RetryDelay = 2
    )

    for ($i = 1; $i -le $MaxRetries; $i++) {
        if (Test-Service $ServiceName $CheckCommand $SuccessMessage) {
            return $true
        }
        if ($i -lt $MaxRetries) {
            Write-Host "  Retrying in ${RetryDelay}s... (attempt $($i+1)/$MaxRetries)" -ForegroundColor Yellow
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

Write-Header "Riskee Startup Verification"
Write-Host "Checking all infrastructure services..."
Write-Host "Started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 1. Docker Services
Write-Header "1. Docker Services"

Test-Service "Docker daemon" {
    docker info 2>$null
    return $LASTEXITCODE -eq 0
} "Docker is running"

Test-Service "Docker Compose services" {
    $output = docker-compose ps 2>$null
    return $output -match "Up"
} "Services are up"

# 2. TimescaleDB
Write-Header "2. TimescaleDB (PostgreSQL + TimescaleDB)"

Test-ServiceWithRetry "TimescaleDB connection" {
    $env:PGPASSWORD = "riskee123"
    psql -h localhost -p 5432 -U postgres -d riskee -c "SELECT 1" 2>$null | Out-Null
    return $LASTEXITCODE -eq 0
} "Connected to PostgreSQL"

Test-Service "TimescaleDB extension" {
    $env:PGPASSWORD = "riskee123"
    $output = psql -h localhost -p 5432 -U postgres -d riskee -c "SELECT extname FROM pg_extension WHERE extname='timescaledb'" 2>$null
    return $output -match "timescaledb"
} "TimescaleDB extension loaded"

Test-Service "Predictions table" {
    $env:PGPASSWORD = "riskee123"
    $output = psql -h localhost -p 5432 -U postgres -d riskee -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'predictions')" 2>$null
    return $output -match "t"
} "Predictions table exists"

# 3. Redis
Write-Header "3. Redis"

Test-ServiceWithRetry "Redis connection" {
    $output = redis-cli -h localhost -p 6379 PING 2>$null
    return $output -eq "PONG"
} "Redis is responding"

Test-Service "Redis memory" {
    $output = redis-cli INFO memory 2>$null
    return $output -match "used_memory"
} "Redis memory stats available"

# 4. NATS JetStream
Write-Header "4. NATS JetStream"

Test-ServiceWithRetry "NATS connectivity" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8222/healthz" -TimeoutSec 2 -ErrorAction Stop
        return $response -match "ok"
    } catch {
        return $false
    }
} "NATS is healthy"

Test-Service "JetStream enabled" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8222/jsz" -TimeoutSec 2 -ErrorAction Stop
        return $response -match "config"
    } catch {
        return $false
    }
} "JetStream is enabled"

# 5. Qdrant
Write-Header "5. Qdrant Vector Database"

Test-ServiceWithRetry "Qdrant API" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:6333" -TimeoutSec 2 -ErrorAction Stop
        return $response -match "qdrant"
    } catch {
        return $false
    }
} "Qdrant API responding"

Test-Service "Qdrant collections" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:6333/collections" -TimeoutSec 2 -ErrorAction Stop
        return $response.result -ne $null
    } catch {
        return $false
    }
} "Collections endpoint working"

# 6. Ollama
Write-Header "6. Ollama (LLM)"

Test-ServiceWithRetry "Ollama service" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
        return $response -ne $null
    } catch {
        return $false
    }
} "Ollama API responding"

Test-Service "Ollama models loaded" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
        return $response.models -ne $null
    } catch {
        return $false
    }
} "Models available"

# 7. Prometheus
Write-Header "7. Prometheus"

Test-ServiceWithRetry "Prometheus API" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:9090/-/healthy" -TimeoutSec 2 -ErrorAction Stop
        return $response -match "Prometheus"
    } catch {
        return $false
    }
} "Prometheus is healthy"

Test-Service "Prometheus targets" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/targets" -TimeoutSec 2 -ErrorAction Stop
        return $response -ne $null
    } catch {
        return $false
    }
} "Targets endpoint responding"

# 8. Grafana
Write-Header "8. Grafana"

Test-ServiceWithRetry "Grafana UI" {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:3001/api/health" -TimeoutSec 2 -ErrorAction Stop
        return $response.database -eq "ok"
    } catch {
        return $false
    }
} "Grafana is healthy"

# Summary
Write-Header "Verification Summary"

Write-Host ""
Write-Host "Total checks: $TotalChecks"
Write-Host "Passed: $PassedChecks" -ForegroundColor Green
if ($FailedChecks -gt 0) {
    Write-Host "Failed: $FailedChecks" -ForegroundColor Red
}

Write-Host ""
if ($FailedChecks -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ALL SYSTEMS OPERATIONAL ✓" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now start development!"
    Write-Host ""
    Write-Host "Service URLs:"
    Write-Host "  TimescaleDB:  postgresql://localhost:5432/riskee"
    Write-Host "  Redis:        redis://localhost:6379"
    Write-Host "  NATS:         http://localhost:8222"
    Write-Host "  Qdrant:       http://localhost:6333/dashboard"
    Write-Host "  Ollama:       http://localhost:11434"
    Write-Host "  Prometheus:   http://localhost:9090"
    Write-Host "  Grafana:      http://localhost:3001 (admin/riskee123)"
    Write-Host ""
    exit 0
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  SOME CHECKS FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "  1. Check Docker services: docker-compose ps"
    Write-Host "  2. View logs: docker-compose logs [service_name]"
    Write-Host "  3. Restart services: docker-compose restart [service_name]"
    Write-Host "  4. Full restart: docker-compose down; docker-compose up -d"
    Write-Host ""
    exit 1
}
