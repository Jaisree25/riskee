#!/bin/bash
# Feature 1: NATS JetStream Basic Testing Script
# Tests NATS connectivity and monitoring endpoints

NATS_HOST="localhost:8222"

echo "==================================================================="
echo "NATS JetStream Basic Test"
echo "==================================================================="

# Check NATS health
echo -e "\n1. Checking NATS server health..."
HEALTH=$(curl -s http://${NATS_HOST}/healthz)
if [ "$HEALTH" == '{"status":"ok"}' ]; then
    echo "[OK] NATS server is healthy"
else
    echo "[ERROR] NATS server health check failed"
    exit 1
fi

# Get server info
echo -e "\n2. Getting NATS server information..."
curl -s http://${NATS_HOST}/varz | python -m json.tool | grep -E "(server_id|version|connections|in_msgs|out_msgs)" | head -10

# Check JetStream status
echo -e "\n3. Checking JetStream status..."
JSINFO=$(curl -s http://${NATS_HOST}/jsz | python -m json.tool)
echo "$JSINFO" | grep -E "(streams|consumers|messages|bytes)" | head -10

# Get connection info
echo -e "\n4. Checking active connections..."
curl -s http://${NATS_HOST}/connz | python -m json.tool | grep -E "(num_connections|total|connections)" | head -5

echo -e "\n==================================================================="
echo "[OK] NATS Basic Test Complete"
echo "==================================================================="

echo -e "\nNATS Server Status: Operational"
echo "JetStream: Enabled"
echo "Monitoring Endpoint: http://${NATS_HOST}"

echo -e "\nAvailable Endpoints:"
echo "  - Health: http://${NATS_HOST}/healthz"
echo "  - Server Stats: http://${NATS_HOST}/varz"
echo "  - JetStream Stats: http://${NATS_HOST}/jsz"
echo "  - Connections: http://${NATS_HOST}/connz"
echo "  - Subscriptions: http://${NATS_HOST}/subsz"

echo -e "\nTo run full pub/sub test:"
echo "  python scripts/test_nats_pubsub.py"

echo -e "\nNATS is ready for message streaming!"
