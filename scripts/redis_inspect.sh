#!/bin/bash
# Redis inspection script - view keys, memory, stats
# Usage: ./scripts/redis_inspect.sh [pattern]

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_CLI="redis-cli -h $REDIS_HOST -p $REDIS_PORT"

PATTERN="${1:-*}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Redis Inspector${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Connection test
echo -e "${YELLOW}[1/6] Connection Test${NC}"
if $REDIS_CLI PING > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] Connected to Redis${NC}"
else
    echo -e "${RED}[FAIL] Cannot connect to Redis${NC}"
    exit 1
fi

# 2. Memory info
echo ""
echo -e "${YELLOW}[2/6] Memory Usage${NC}"
$REDIS_CLI INFO memory | grep -E "used_memory_human|used_memory_peak_human|maxmemory_human"

# 3. Key count
echo ""
echo -e "${YELLOW}[3/6] Database Info${NC}"
DBSIZE=$($REDIS_CLI DBSIZE)
echo "Total keys: $DBSIZE"

# 4. Keys by pattern
echo ""
echo -e "${YELLOW}[4/6] Keys matching pattern: $PATTERN${NC}"
KEYS=$($REDIS_CLI --scan --pattern "$PATTERN" | head -20)

if [ -z "$KEYS" ]; then
    echo "No keys found"
else
    echo "$KEYS" | while read -r key; do
        TYPE=$($REDIS_CLI TYPE "$key")
        TTL=$($REDIS_CLI TTL "$key")

        if [ "$TTL" == "-1" ]; then
            TTL_INFO="no expiry"
        elif [ "$TTL" == "-2" ]; then
            TTL_INFO="expired"
        else
            TTL_INFO="${TTL}s remaining"
        fi

        echo "  $key ($TYPE) - $TTL_INFO"
    done

    KEY_COUNT=$(echo "$KEYS" | wc -l)
    if [ $KEY_COUNT -ge 20 ]; then
        echo "  ... (showing first 20 keys)"
    fi
fi

# 5. Key statistics by prefix
echo ""
echo -e "${YELLOW}[5/6] Key Count by Prefix${NC}"
for prefix in pred features earnings_analysis explanation model stats; do
    COUNT=$($REDIS_CLI --scan --pattern "${prefix}:*" | wc -l)
    if [ $COUNT -gt 0 ]; then
        echo "  ${prefix}:* - $COUNT keys"
    fi
done

# 6. Cache statistics
echo ""
echo -e "${YELLOW}[6/6] Cache Statistics${NC}"

HITS=$($REDIS_CLI GET stats:cache:hits 2>/dev/null || echo "0")
MISSES=$($REDIS_CLI GET stats:cache:misses 2>/dev/null || echo "0")

if [ "$HITS" == "0" ] && [ "$MISSES" == "0" ]; then
    echo "  No cache statistics available"
else
    TOTAL=$((HITS + MISSES))
    if [ $TOTAL -gt 0 ]; then
        HIT_RATE=$(echo "scale=2; $HITS * 100 / $TOTAL" | bc)
        echo "  Cache hits: $HITS"
        echo "  Cache misses: $MISSES"
        echo "  Hit rate: ${HIT_RATE}%"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Inspection Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Commands:"
echo "  View specific key: redis-cli GET <key>"
echo "  View hash: redis-cli HGETALL <key>"
echo "  Delete key: redis-cli DEL <key>"
echo "  Flush all: redis-cli FLUSHALL (WARNING: deletes everything!)"
echo ""
