#!/bin/bash
# Dashboard API Integration Tests
# Tests integration between web dashboard and security suite components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Test configuration
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DASHBOARD_DIR="$PROJECT_ROOT/web-dashboard"
DASHBOARD_URL="http://localhost:8080"
TEST_USER="admin"
TEST_PASS="admin"
TESTS_PASSED=0
TESTS_FAILED=0

# Test logging functions
log_test() {
    echo -e "${CYAN}🧪 $1${NC}"
}

log_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test 1: Dashboard Service Availability
test_dashboard_availability() {
    log_test "Testing Dashboard Service Availability"
    
    # Check if dashboard is running
    if curl -s --connect-timeout 5 "$DASHBOARD_URL" >/dev/null 2>&1; then
        log_pass "Dashboard is accessible at $DASHBOARD_URL"
    else
        log_fail "Dashboard is not accessible at $DASHBOARD_URL"
        log_info "Starting dashboard for testing..."
        
        # Try to start dashboard
        if [ -f "$DASHBOARD_DIR/start-dashboard.sh" ]; then
            cd "$DASHBOARD_DIR"
            ./start-dashboard.sh &
            local dashboard_pid=$!
            
            # Wait for dashboard to start
            sleep 5
            
            if curl -s --connect-timeout 5 "$DASHBOARD_URL" >/dev/null 2>&1; then
                log_pass "Dashboard started successfully"
                echo "$dashboard_pid" > /tmp/dashboard_test.pid
            else
                log_fail "Failed to start dashboard"
                kill $dashboard_pid 2>/dev/null || true
            fi
        else
            log_fail "Dashboard startup script not found"
        fi
    fi
}

# Test 2: Authentication API
test_authentication_api() {
    log_test "Testing Authentication API"
    
    # Test login endpoint
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TEST_USER\",\"password\":\"$TEST_PASS\"}" \
        "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
    
    if [ -n "$login_response" ]; then
        log_pass "Login API endpoint responds"
        
        # Check for success response
        if echo "$login_response" | grep -q "success\|token\|authenticated"; then
            log_pass "Login API returns success response"
        else
            log_fail "Login API does not return success response"
        fi
        
        # Extract session token if available
        local session_token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 || echo "")
        if [ -n "$session_token" ]; then
            log_pass "Session token extracted successfully"
            echo "$session_token" > /tmp/dashboard_session.txt
        else
            log_warn "Session token not found in response"
        fi
    else
        log_fail "Login API endpoint not responding"
    fi
    
    # Test logout endpoint
    local logout_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        "$DASHBOARD_URL/api/logout" 2>/dev/null || echo "")
    
    if [ -n "$logout_response" ]; then
        log_pass "Logout API endpoint responds"
    else
        log_fail "Logout API endpoint not responding"
    fi
}

# Test 3: System Status API
test_system_status_api() {
    log_test "Testing System Status API"
    
    local status_response=$(curl -s "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
    
    if [ -n "$status_response" ]; then
        log_pass "System status API responds"
        
        # Check for required fields
        local required_fields=("status" "timestamp" "uptime" "cpu" "memory" "disk")
        for field in "${required_fields[@]}"; do
            if echo "$status_response" | grep -q "\"$field\""; then
                log_pass "System status API includes field: $field"
            else
                log_fail "System status API missing field: $field"
            fi
        done
        
        # Validate JSON format
        if echo "$status_response" | python3 -m json.tool >/dev/null 2>&1; then
            log_pass "System status API returns valid JSON"
        else
            log_fail "System status API returns invalid JSON"
        fi
    else
        log_fail "System status API not responding"
    fi
}

# Test 4: Behavioral Analysis API
test_behavioral_api() {
    log_test "Testing Behavioral Analysis API"
    
    # Test metrics endpoint
    local metrics_response=$(curl -s "$DASHBOARD_URL/api/behavioral/metrics" 2>/dev/null || echo "")
    
    if [ -n "$metrics_response" ]; then
        log_pass "Behavioral metrics API responds"
        
        # Check for behavioral data fields
        local behavioral_fields=("baseline" "anomalies" "threat_score" "patterns")
        for field in "${behavioral_fields[@]}"; do
            if echo "$metrics_response" | grep -q "\"$field\""; then
                log_pass "Behavioral metrics API includes field: $field"
            else
                log_warn "Behavioral metrics API missing field: $field"
            fi
        done
        
        # Validate JSON format
        if echo "$metrics_response" | python3 -m json.tool >/dev/null 2>&1; then
            log_pass "Behavioral metrics API returns valid JSON"
        else
            log_fail "Behavioral metrics API returns invalid JSON"
        fi
    else
        log_fail "Behavioral metrics API not responding"
    fi
    
    # Test anomalies endpoint
    local anomalies_response=$(curl -s "$DASHBOARD_URL/api/behavioral/anomalies" 2>/dev/null || echo "")
    
    if [ -n "$anomalies_response" ]; then
        log_pass "Behavioral anomalies API responds"
        
        # Check for anomaly data
        if echo "$anomalies_response" | grep -q "anomalies\|detected\|severity"; then
            log_pass "Behavioral anomalies API includes anomaly data"
        else
            log_warn "Behavioral anomalies API may be missing anomaly data"
        fi
    else
        log_fail "Behavioral anomalies API not responding"
    fi
    
    # Test baseline creation endpoint
    local baseline_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"days\":7}" \
        "$DASHBOARD_URL/api/behavioral/baseline/create" 2>/dev/null || echo "")
    
    if [ -n "$baseline_response" ]; then
        log_pass "Baseline creation API responds"
        
        if echo "$baseline_response" | grep -q "success\|started\|initiated"; then
            log_pass "Baseline creation API returns success response"
        else
            log_fail "Baseline creation API does not return success response"
        fi
    else
        log_fail "Baseline creation API not responding"
    fi
}

# Test 5: Threat Intelligence API
test_threat_intelligence_api() {
    log_test "Testing Threat Intelligence API"
    
    # Test IOCs endpoint
    local iocs_response=$(curl -s "$DASHBOARD_URL/api/threats/iocs" 2>/dev/null || echo "")
    
    if [ -n "$iocs_response" ]; then
        log_pass "Threat IOCs API responds"
        
        # Check for IOC data fields
        local ioc_fields=("indicators" "type" "source" "confidence" "timestamp")
        for field in "${ioc_fields[@]}"; do
            if echo "$iocs_response" | grep -q "\"$field\""; then
                log_pass "Threat IOCs API includes field: $field"
            else
                log_warn "Threat IOCs API missing field: $field"
            fi
        done
        
        # Validate JSON format
        if echo "$iocs_response" | python3 -m json.tool >/dev/null 2>&1; then
            log_pass "Threat IOCs API returns valid JSON"
        else
            log_fail "Threat IOCs API returns invalid JSON"
        fi
    else
        log_fail "Threat IOCs API not responding"
    fi
    
    # Test threat feeds endpoint
    local feeds_response=$(curl -s "$DASHBOARD_URL/api/threats/feeds" 2>/dev/null || echo "")
    
    if [ -n "$feeds_response" ]; then
        log_pass "Threat feeds API responds"
        
        if echo "$feeds_response" | grep -q "feeds\|sources\|status"; then
            log_pass "Threat feeds API includes feed data"
        else
            log_warn "Threat feeds API may be missing feed data"
        fi
    else
        log_fail "Threat feeds API not responding"
    fi
}

# Test 6: Incident Management API
test_incident_management_api() {
    log_test "Testing Incident Management API"
    
    # Test incidents list endpoint
    local incidents_response=$(curl -s "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
    
    if [ -n "$incidents_response" ]; then
        log_pass "Incidents list API responds"
        
        # Check for incident data fields
        local incident_fields=("incidents" "id" "title" "severity" "status" "timestamp")
        for field in "${incident_fields[@]}"; do
            if echo "$incidents_response" | grep -q "\"$field\""; then
                log_pass "Incidents API includes field: $field"
            else
                log_warn "Incidents API missing field: $field"
            fi
        done
        
        # Validate JSON format
        if echo "$incidents_response" | python3 -m json.tool >/dev/null 2>&1; then
            log_pass "Incidents API returns valid JSON"
        else
            log_fail "Incidents API returns invalid JSON"
        fi
    else
        log_fail "Incidents list API not responding"
    fi
    
    # Test incident creation endpoint
    local create_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"title\":\"Test Incident\",\"description\":\"API test incident\",\"severity\":\"medium\"}" \
        "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
    
    if [ -n "$create_response" ]; then
        log_pass "Incident creation API responds"
        
        if echo "$create_response" | grep -q "success\|created\|id"; then
            log_pass "Incident creation API returns success response"
        else
            log_fail "Incident creation API does not return success response"
        fi
    else
        log_fail "Incident creation API not responding"
    fi
    
    # Test evidence collection endpoint
    local evidence_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"incident_id\":\"TEST_INCIDENT\",\"evidence_type\":\"system_state\"}" \
        "$DASHBOARD_URL/api/incidents/evidence" 2>/dev/null || echo "")
    
    if [ -n "$evidence_response" ]; then
        log_pass "Evidence collection API responds"
        
        if echo "$evidence_response" | grep -q "success\|collected\|started"; then
            log_pass "Evidence collection API returns success response"
        else
            log_fail "Evidence collection API does not return success response"
        fi
    else
        log_fail "Evidence collection API not responding"
    fi
}

# Test 7: Real-time Data Updates
test_realtime_updates() {
    log_test "Testing Real-time Data Updates"
    
    # Test WebSocket endpoint
    if command -v nc &> /dev/null; then
        local ws_response=$(echo -e "GET /socket.io/ HTTP/1.1\r\nHost: localhost:8080\r\n\r\n" | nc localhost 8080 2>/dev/null || echo "")
        
        if [ -n "$ws_response" ]; then
            log_pass "WebSocket endpoint responds"
            
            if echo "$ws_response" | grep -q "socket.io\|websocket\|upgrade"; then
                log_pass "WebSocket upgrade supported"
            else
                log_warn "WebSocket upgrade may not be supported"
            fi
        else
            log_fail "WebSocket endpoint not responding"
        fi
    else
        log_warn "Netcat not available - cannot test WebSocket"
    fi
    
    # Test server-sent events
    local sse_response=$(curl -s -N "$DASHBOARD_URL/api/events" 2>/dev/null || echo "")
    
    if [ -n "$sse_response" ]; then
        log_pass "Server-sent events endpoint responds"
        
        if echo "$sse_response" | grep -q "data:\|event:"; then
            log_pass "SSE format detected"
        else
            log_warn "SSE format may not be correct"
        fi
    else
        log_fail "Server-sent events endpoint not responding"
    fi
}

# Test 8: API Error Handling
test_api_error_handling() {
    log_test "Testing API Error Handling"
    
    # Test invalid endpoint
    local invalid_response=$(curl -s "$DASHBOARD_URL/api/invalid/endpoint" 2>/dev/null || echo "")
    
    if [ -n "$invalid_response" ]; then
        log_pass "Invalid endpoint returns response"
        
        # Check for proper error status
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL/api/invalid/endpoint" 2>/dev/null || echo "000")
        if [ "$status_code" -ge 400 ] && [ "$status_code" -lt 500 ]; then
            log_pass "Invalid endpoint returns proper error status: $status_code"
        else
            log_fail "Invalid endpoint returns improper status: $status_code"
        fi
    else
        log_fail "Invalid endpoint not handled properly"
    fi
    
    # Test invalid JSON input
    local invalid_json_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "invalid json" \
        "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
    
    if [ -n "$invalid_json_response" ]; then
        log_pass "Invalid JSON input handled"
        
        if echo "$invalid_json_response" | grep -q "error\|invalid\|malformed"; then
            log_pass "Invalid JSON returns proper error message"
        else
            log_fail "Invalid JSON does not return proper error message"
        fi
    else
        log_fail "Invalid JSON input not handled properly"
    fi
    
    # Test missing required fields
    local missing_fields_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{}" \
        "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
    
    if [ -n "$missing_fields_response" ]; then
        log_pass "Missing required fields handled"
        
        if echo "$missing_fields_response" | grep -q "required\|missing\|field"; then
            log_pass "Missing fields returns proper error message"
        else
            log_fail "Missing fields does not return proper error message"
        fi
    else
        log_fail "Missing required fields not handled properly"
    fi
}

# Test 9: API Performance
test_api_performance() {
    log_test "Testing API Performance"
    
    # Test response times
    local endpoints=(
        "/api/system/status"
        "/api/behavioral/metrics"
        "/api/threats/iocs"
        "/api/incidents"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local start_time=$(date +%s.%N)
        local response=$(curl -s "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        if [ -n "$response" ]; then
            local response_time_ms=$(echo "$response_time * 1000" | bc -l 2>/dev/null || echo "0")
            if (( $(echo "$response_time_ms < 1000" | bc -l 2>/dev/null || echo "1") )); then
                log_pass "API response time acceptable: $endpoint (${response_time_ms}ms)"
            else
                log_warn "API response time slow: $endpoint (${response_time_ms}ms)"
            fi
        else
            log_fail "API endpoint not responding: $endpoint"
        fi
    done
    
    # Test concurrent requests
    if command -v curl &> /dev/null; then
        local concurrent_requests=5
        local successful_requests=0
        
        for i in $(seq 1 $concurrent_requests); do
            curl -s "$DASHBOARD_URL/api/system/status" >/dev/null 2>&1 && ((successful_requests++)) &
        done
        
        wait
        
        if [ "$successful_requests" -eq "$concurrent_requests" ]; then
            log_pass "API handles concurrent requests: $successful_requests/$concurrent_requests"
        else
            log_fail "API fails with concurrent requests: $successful_requests/$concurrent_requests"
        fi
    else
        log_warn "Cannot test concurrent requests - curl not available"
    fi
}

# Test 10: API Security
test_api_security() {
    log_test "Testing API Security"
    
    # Test authentication requirement
    local protected_response=$(curl -s "$DASHBOARD_URL/api/incidents/create" 2>/dev/null || echo "")
    
    if [ -n "$protected_response" ]; then
        if echo "$protected_response" | grep -q "unauthorized\|authentication\|login"; then
            log_pass "Protected endpoint requires authentication"
        else
            log_fail "Protected endpoint does not require authentication"
        fi
    else
        log_fail "Protected endpoint not responding"
    fi
    
    # Test rate limiting (if implemented)
    local request_count=0
    local rate_limited=false
    
    for i in $(seq 1 20); do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "000")
        if [ "$response" = "429" ]; then
            rate_limited=true
            break
        fi
        ((request_count++))
    done
    
    if [ "$rate_limited" = true ]; then
        log_pass "Rate limiting implemented (triggered after $request_count requests)"
    else
        log_warn "Rate limiting may not be implemented"
    fi
    
    # Test CORS headers
    local cors_response=$(curl -s -I "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
    
    if echo "$cors_response" | grep -q "Access-Control"; then
        log_pass "CORS headers present"
    else
        log_warn "CORS headers may be missing"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment..."
    
    # Stop dashboard if we started it
    if [ -f /tmp/dashboard_test.pid ]; then
        local dashboard_pid=$(cat /tmp/dashboard_test.pid)
        kill $dashboard_pid 2>/dev/null || true
        rm -f /tmp/dashboard_test.pid
    fi
    
    # Clean up temporary files
    rm -f /tmp/dashboard_session.txt
}

# Main test execution
main() {
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}🔗 DASHBOARD API INTEGRATION TESTS 🔗${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${BLUE}Test started: $(date)${NC}"
    echo ""
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run all tests
    test_dashboard_availability
    test_authentication_api
    test_system_status_api
    test_behavioral_api
    test_threat_intelligence_api
    test_incident_management_api
    test_realtime_updates
    test_api_error_handling
    test_api_performance
    test_api_security
    
    # Test results summary
    echo ""
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}📊 TEST RESULTS SUMMARY${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    echo -e "${BLUE}Total Tests: $total_tests${NC}"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL DASHBOARD API INTEGRATION TESTS PASSED!${NC}"
        exit 0
    else
        echo -e "${RED}⚠️ $TESTS_FAILED test(s) failed. Review issues above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"