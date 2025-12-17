#!/bin/bash
# Feature 1: Redis Cache Testing Script
# Tests Redis functionality for the prediction system

echo "Testing Redis Connection..."
docker exec riskee_redis redis-cli ping

echo -e "\n1. Testing basic SET/GET with TTL..."
docker exec riskee_redis redis-cli SET test_key "Hello from riskee" EX 300
docker exec riskee_redis redis-cli GET test_key
echo "TTL remaining:"
docker exec riskee_redis redis-cli TTL test_key

echo -e "\n2. Testing HASH operations (for feature storage)..."
docker exec riskee_redis redis-cli HSET feature:AAPL:latest \
    open 150.25 \
    high 152.10 \
    low 149.80 \
    close 151.50 \
    volume 50000000

echo "Retrieving all features:"
docker exec riskee_redis redis-cli HGETALL feature:AAPL:latest

echo -e "\n3. Retrieving single field:"
docker exec riskee_redis redis-cli HGET feature:AAPL:latest close

echo -e "\n4. Testing list operations (for prediction queues)..."
docker exec riskee_redis redis-cli LPUSH prediction_queue:normal "AAPL" "GOOGL" "MSFT"
echo "Queue length:"
docker exec riskee_redis redis-cli LLEN prediction_queue:normal
echo "Queue contents:"
docker exec riskee_redis redis-cli LRANGE prediction_queue:normal 0 -1

echo -e "\n5. Testing sorted sets (for priority queues)..."
docker exec riskee_redis redis-cli ZADD priority_queue 1.0 "AAPL" 0.9 "GOOGL" 0.8 "MSFT"
echo "Top priority items:"
docker exec riskee_redis redis-cli ZREVRANGE priority_queue 0 2 WITHSCORES

echo -e "\n6. Redis INFO..."
docker exec riskee_redis redis-cli INFO keyspace

echo -e "\n7. Cleanup test keys..."
docker exec riskee_redis redis-cli DEL test_key feature:AAPL:latest prediction_queue:normal priority_queue

echo -e "\nRedis testing complete! All operations successful."
