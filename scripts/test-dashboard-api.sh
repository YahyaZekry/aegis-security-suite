#!/bin/bash
# Test Web Dashboard API Integration

# Set paths
SECURITY_SUITE_HOME="$(dirname "$(dirname "$0)")"
WEB_DASHBOARD_DIR="$SECURITY_SUITE_HOME/web-dashboard"

echo "Testing web dashboard API integration..."

# Check if the dashboard is running
if ! pgrep -f "python.*app-optimized.py" > /dev/null; then
    echo "Starting web dashboard..."
    cd "$WEB_DASHBOARD_DIR"
    python3 app-optimized.py &
    DASHBOARD_PID=$!
    echo "Dashboard started with PID: $DASHBOARD_PID"
    sleep 5
else
    echo "Web dashboard is already running"
fi

# Test API endpoints
BASE_URL="http://localhost:5000/api"

# Test threats API
echo "Testing threats API..."
curl -s "$BASE_URL/threats/stats" | jq . || echo "Failed to get threat stats"

# Test system API
echo "Testing system API..."
curl -s "$BASE_URL/system/status" | jq . || echo "Failed to get system status"

# Test adding a test IOC
echo "Testing IOC addition..."
curl -s -X POST "$BASE_URL/threats/ioc" \
  -H "Content-Type: application/json" \
  -d '{"type": "ip", "value": "203.0.113.1", "threat_type": "malware", "confidence": 90}' \
  | jq . || echo "Failed to add IOC"

# Test searching IOCs
echo "Testing IOC search..."
curl -s "$BASE_URL/threats/ioc/search?type=ip&query=203.0.113.1" | jq . || echo "Failed to search IOCs"

echo "API testing completed"