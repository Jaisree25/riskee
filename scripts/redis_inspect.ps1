# Redis inspection script for Windows - view keys, memory, stats
# Usage: .\scripts\redis_inspect.ps1 [pattern]

param(
    [Parameter(Position=0)]
    [string]$Pattern = "*"
)

$REDIS_HOST = if ($env:REDIS_HOST) { $env:REDIS_HOST } else { "localhost" }
$REDIS_PORT = if ($env:REDIS_PORT) { $env:REDIS_PORT } else { "6379" }

Write-Host "========================================" -ForegroundColor Blue
Write-Host "Redis Inspector" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# 1. Connection test
Write-Host "[1/6] Connection Test" -ForegroundColor Yellow
try {
    $ping = redis-cli -h $REDIS_HOST -p $REDIS_PORT PING
    if ($ping -eq "PONG") {
        Write-Host "[OK] Connected to Redis" -ForegroundColor Green
    }
} catch {
    Write-Host "[FAIL] Cannot connect to Redis" -ForegroundColor Red
    exit 1
}

# 2. Memory info
Write-Host ""
Write-Host "[2/6] Memory Usage" -ForegroundColor Yellow
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | Select-String "used_memory_human|used_memory_peak_human|maxmemory_human"

# 3. Key count
Write-Host ""
Write-Host "[3/6] Database Info" -ForegroundColor Yellow
$dbSize = redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE
Write-Host "Total keys: $dbSize"

# 4. Keys by pattern
Write-Host ""
Write-Host "[4/6] Keys matching pattern: $Pattern" -ForegroundColor Yellow
$keys = redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern $Pattern | Select-Object -First 20

if ($keys) {
    foreach ($key in $keys) {
        $type = redis-cli -h $REDIS_HOST -p $REDIS_PORT TYPE $key
        $ttl = redis-cli -h $REDIS_HOST -p $REDIS_PORT TTL $key

        if ($ttl -eq "-1") {
            $ttlInfo = "no expiry"
        } elseif ($ttl -eq "-2") {
            $ttlInfo = "expired"
        } else {
            $ttlInfo = "${ttl}s remaining"
        }

        Write-Host "  $key ($type) - $ttlInfo"
    }

    $keyCount = ($keys | Measure-Object).Count
    if ($keyCount -ge 20) {
        Write-Host "  ... (showing first 20 keys)"
    }
} else {
    Write-Host "No keys found"
}

# 5. Key statistics by prefix
Write-Host ""
Write-Host "[5/6] Key Count by Prefix" -ForegroundColor Yellow
$prefixes = @("pred", "features", "earnings_analysis", "explanation", "model", "stats")
foreach ($prefix in $prefixes) {
    $count = (redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern "${prefix}:*" | Measure-Object).Count
    if ($count -gt 0) {
        Write-Host "  ${prefix}:* - $count keys"
    }
}

# 6. Cache statistics
Write-Host ""
Write-Host "[6/6] Cache Statistics" -ForegroundColor Yellow

$hits = redis-cli -h $REDIS_HOST -p $REDIS_PORT GET "stats:cache:hits"
$misses = redis-cli -h $REDIS_HOST -p $REDIS_PORT GET "stats:cache:misses"

if (-not $hits) { $hits = 0 }
if (-not $misses) { $misses = 0 }

if ($hits -eq 0 -and $misses -eq 0) {
    Write-Host "  No cache statistics available"
} else {
    $total = [int]$hits + [int]$misses
    if ($total -gt 0) {
        $hitRate = [math]::Round(([int]$hits / $total) * 100, 2)
        Write-Host "  Cache hits: $hits"
        Write-Host "  Cache misses: $misses"
        Write-Host "  Hit rate: ${hitRate}%"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Inspection Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Commands:"
Write-Host "  View specific key: redis-cli GET <key>"
Write-Host "  View hash: redis-cli HGETALL <key>"
Write-Host "  Delete key: redis-cli DEL <key>"
Write-Host "  Flush all: redis-cli FLUSHALL (WARNING: deletes everything!)"
Write-Host ""
