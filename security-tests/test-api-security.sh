#!/bin/bash
# API Security and Rate Limiting Tests
# Tests API security measures, rate limiting, and access controls

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

# Test 1: API Authentication Requirements
test_api_authentication() {
    log_test "Testing API Authentication Requirements"
    
    # Test endpoints that should require authentication
    local protected_endpoints=(
        "/api/system/status"
        "/api/behavioral/metrics"
        "/api/threats/iocs"
        "/api/incidents"
        "/api/config/update"
    )
    
    for endpoint in "${protected_endpoints[@]}"; do
        local response=$(curl -s "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "000")
        
        log_info "Endpoint: $endpoint - Status: $status_code"
        
        # Check for proper authentication requirement
        if [ "$status_code" = "401" ]; then
            log_pass "API endpoint requires authentication: $endpoint"
        elif [ "$status_code" = "403" ]; then
            log_pass "API endpoint properly forbidden: $endpoint"
        elif [ "$status_code" = "302" ]; then
            log_pass "API endpoint redirects to login: $endpoint"
        elif [ "$status_code" = "200" ]; then
            log_fail "API endpoint accessible without authentication: $endpoint"
        else
            log_warn "Unexpected status code for $endpoint: $status_code"
        fi
    done
}

# Test 2: Rate Limiting
test_rate_limiting() {
    log_test "Testing Rate Limiting"
    
    local endpoint="/api/system/status"
    local max_requests=50
    local rate_limited=false
    local rate_limit_threshold=20
    
    # Make rapid requests
    for i in $(seq 1 $max_requests); do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "000")
        
        if [ "$response" = "429" ]; then
            rate_limited=true
            log_info "Rate limiting triggered after $i requests"
            break
        elif [ "$response" = "503" ]; then
            rate_limited=true
            log_info "Service unavailable (rate limiting) after $i requests"
            break
        fi
        
        # Small delay to avoid overwhelming the system
        sleep 0.01
    done
    
    if [ "$rate_limited" = true ]; then
        log_pass "Rate limiting is implemented"
    else
        log_warn "Rate limiting may not be implemented (tested $max_requests requests)"
    fi
    
    # Test rate limiting recovery
    log_info "Testing rate limiting recovery..."
    sleep 2
    
    local recovery_response=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "000")
    
    if [ "$recovery_response" != "429" ] && [ "$recovery_response" != "503" ]; then
        log_pass "Rate limiting recovery works"
    else
        log_warn "Rate limiting recovery may not work properly"
    fi
}

# Test 3: API Key Security
test_api_key_security() {
    log_test "Testing API Key Security"
    
    # Test with invalid API key
    local invalid_key="invalid_api_key_12345"
    local response=$(curl -s -H "X-API-Key: $invalid_key" "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: $invalid_key" "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "000")
    
    log_info "Invalid API key test - Status: $status_code"
    
    if [ "$status_code" = "401" ] || [ "$status_code" = "403" ]; then
        log_pass "Invalid API key properly rejected"
    else
        log_fail "Invalid API key not properly rejected"
    fi
    
    # Test with missing API key (if API key auth is implemented)
    response=$(curl -s "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "401" ] || [ "$status_code" = "403" ]; then
        log_pass "Missing API key properly rejected"
    else
        log_warn "API key authentication may not be implemented"
    fi
}

# Test 4: HTTP Method Security
test_http_method_security() {
    log_test "Testing HTTP Method Security"
    
    local endpoint="/api/incidents"
    local methods=("GET" "POST" "PUT" "DELETE" "PATCH" "HEAD" "OPTIONS")
    
    for method in "${methods[@]}"; do
        local response=$(curl -s -X "$method" -o /dev/null -w "%{http_code}" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "000")
        
        log_info "Method $method on $endpoint - Status: $response"
        
        # Check for appropriate method handling
        case "$method" in
            "GET")
                if [ "$response" = "401" ] || [ "$response" = "403" ]; then
                    log_pass "GET method properly secured"
                else
                    log_warn "GET method may not be properly secured"
                fi
                ;;
            "POST")
                if [ "$response" = "401" ] || [ "$response" = "403" ]; then
                    log_pass "POST method properly secured"
                else
                    log_warn "POST method may not be properly secured"
                fi
                ;;
            "PUT"|"DELETE"|"PATCH")
                if [ "$response" = "401" ] || [ "$response" = "403" ] || [ "$response" = "405" ]; then
                    log_pass "$method method properly secured/rejected"
                else
                    log_fail "$method method should be secured or rejected"
                fi
                ;;
            "HEAD"|"OPTIONS")
                if [ "$response" = "401" ] || [ "$response" = "403" ] || [ "$response" = "405" ]; then
                    log_pass "$method method properly handled"
                else
                    log_warn "$method method handling may need improvement"
                fi
                ;;
        esac
    done
}

# Test 5: CORS Security
test_cors_security() {
    log_test "Testing CORS Security"
    
    local endpoint="/api/system/status"
    
    # Test preflight request
    local response=$(curl -s -I -X OPTIONS \
        -H "Origin: http://evil.com" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: Content-Type" \
        "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
    
    if [ -n "$response" ]; then
        # Check for CORS headers
        if echo "$response" | grep -qi "access-control-allow-origin"; then
            local allowed_origin=$(echo "$response" | grep -i "access-control-allow-origin" | cut -d':' -f2- | tr -d ' \r\n')
            
            if [ "$allowed_origin" = "*" ]; then
                log_fail "CORS allows all origins (security risk)"
            elif echo "$allowed_origin" | grep -q "http://evil.com"; then
                log_fail "CORS allows malicious origin"
            else
                log_pass "CORS properly restricts origins"
            fi
        else
            log_pass "CORS headers not present (may be intentional)"
        fi
        
        # Check for methods restriction
        if echo "$response" | grep -qi "access-control-allow-methods"; then
            local allowed_methods=$(echo "$response" | grep -i "access-control-allow-methods" | cut -d':' -f2- | tr -d ' \r\n')
            
            if echo "$allowed_methods" | grep -qi "DELETE\|PUT\|PATCH"; then
                log_warn "CORS allows dangerous methods: $allowed_methods"
            else
                log_pass "CORS methods properly restricted"
            fi
        fi
    else
        log_warn "No response to CORS preflight request"
    fi
    
    # Test actual cross-origin request
    response=$(curl -s -H "Origin: http://evil.com" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
    
    if [ -n "$response" ]; then
        # Check if response includes data (should not for cross-origin)
        if echo "$response" | grep -q "status\|cpu\|memory"; then
            log_fail "Cross-origin request returns data"
        else
            log_pass "Cross-origin request properly handled"
        fi
    fi
}

# Test 6: Request Size Limits
test_request_size_limits() {
    log_test "Testing Request Size Limits"
    
    # Create large payload
    local large_payload=$(printf 'A%.0s' {1..100000})  # 100KB
    
    # Test POST with large payload
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"data\":\"$large_payload\"}" \
        -o /dev/null -w "%{http_code}" \
        "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "000")
    
    log_info "Large payload test - Status: $response"
    
    if [ "$response" = "413" ]; then
        log_pass "Large request properly rejected"
    elif [ "$response" = "401" ] || [ "$response" = "403" ]; then
        log_pass "Large request rejected due to authentication (acceptable)"
    elif [ "$response" = "200" ]; then
        log_warn "Large request accepted (may need size limits)"
    else
        log_warn "Unexpected response to large request: $response"
    fi
    
    # Test with extremely large payload
    local huge_payload=$(printf 'B%.0s' {1..1000000})  # 1MB
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"data\":\"$huge_payload\"}" \
        -o /dev/null -w "%{http_code}" \
        "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "000")
    
    log_info "Huge payload test - Status: $response"
    
    if [ "$response" = "413" ]; then
        log_pass "Huge request properly rejected"
    elif [ "$response" = "401" ] || [ "$response" = "403" ]; then
        log_pass "Huge request rejected due to authentication (acceptable)"
    elif [ "$response" = "200" ]; then
        log_fail "Huge request accepted (security risk)"
    else
        log_warn "Unexpected response to huge request: $response"
    fi
}

# Test 7: JSON Security
test_json_security() {
    log_test "Testing JSON Security"
    
    # Test malformed JSON
    local malformed_json='{"username":"test","password":}'
    
    local response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$malformed_json" \
        "$DASHBOARD_URL/login" 2>/dev/null || echo "")
    
    if [ -n "$response" ]; then
        if echo "$response" | grep -q "error\|invalid\|malformed\|parse"; then
            log_pass "Malformed JSON properly rejected"
        else
            log_fail "Malformed JSON not properly rejected"
        fi
    fi
    
    # Test JSON with dangerous content
    local dangerous_json='{"username":"admin","password":{"$ne":""}}'
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$dangerous_json" \
        "$DASHBOARD_URL/login" 2>/dev/null || echo "")
    
    if [ -n "$response" ]; then
        if echo "$response" | grep -q "success\|authenticated\|token"; then
            log_fail "Dangerous JSON content accepted"
        else
            log_pass "Dangerous JSON content rejected"
        fi
    fi
    
    # Test JSON injection
    local injection_json='{"username":"test","password":"test","admin":true}'
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$injection_json" \
        "$DASHBOARD_URL/login" 2>/dev/null || echo "")
    
    if [ -n "$response" ]; then
        if echo "$response" | grep -q "success\|authenticated\|token"; then
            log_fail "JSON injection may have succeeded"
        else
            log_pass "JSON injection blocked"
        fi
    fi
}

# Test 8: API Versioning Security
test_api_versioning_security() {
    log_test "Testing API Versioning Security"
    
    # Test different API versions
    local versions=("v1" "v2" "v3" "1.0" "2.0" "latest")
    
    for version in "${versions[@]}"; do
        local response=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL/api/$version/system/status" 2>/dev/null || echo "000")
        
        log_info "API version $version - Status: $response"
        
        if [ "$response" = "404" ]; then
            log_pass "Unsupported API version $version returns 404"
        elif [ "$response" = "401" ] || [ "$response" = "403" ]; then
            log_pass "API version $version properly secured"
        elif [ "$response" = "200" ]; then
            log_pass "API version $version is supported"
        else
            log_warn "Unexpected response for API version $version: $response"
        fi
    done
    
    # Test version enumeration
    response=$(curl -s "$DASHBOARD_URL/api/versions" 2>/dev/null || echo "")
    
    if [ -n "$response" ]; then
        if echo "$response" | grep -q "v1\|v2\|1.0\|2.0"; then
            log_warn "API version enumeration may be possible"
        else
            log_pass "API version enumeration properly restricted"
        fi
    else
        log_pass "API version endpoint not exposed"
    fi
}

# Test 9: Error Message Security
test_error_message_security() {
    log_test "Testing Error Message Security"
    
    # Test various error conditions
    local error_tests=(
        "invalid_endpoint"
        "malformed_json"
        "missing_fields"
        "invalid_method"
        "large_request"
    )
    
    for test in "${error_tests[@]}"; do
        local response=""
        local status_code=""
        
        case "$test" in
            "invalid_endpoint")
                response=$(curl -s "$DASHBOARD_URL/api/invalid/endpoint" 2>/dev/null || echo "")
                status_code=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL/api/invalid/endpoint" 2>/dev/null || echo "000")
                ;;
            "malformed_json")
                response=$(curl -s -X POST -H "Content-Type: application/json" -d '{"invalid":}' "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
                status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{"invalid":}' "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "000")
                ;;
            "missing_fields")
                response=$(curl -s -X POST -H "Content-Type: application/json" -d '{}' "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
                status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{}' "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "000")
                ;;
            "invalid_method")
                response=$(curl -s -X TRACE "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
                status_code=$(curl -s -o /dev/null -w "%{http_code}" -X TRACE "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "000")
                ;;
            "large_request")
                local large_data=$(printf 'A%.0s' {1..10000})
                response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"data\":\"$large_data\"}" "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
                status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"data\":\"$large_data\"}" "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "000")
                ;;
        esac
        
        if [ -n "$response" ]; then
            # Check for information leakage in error messages
            if echo "$response" | grep -qi "stack.*trace\|exception\|error.*line\|internal.*server\|database.*error\|file.*path\|sql.*syntax"; then
                log_fail "Error message leaks sensitive information: $test"
            else
                log_pass "Error message properly sanitized: $test"
            fi
            
            # Check for consistent error format
            if echo "$response" | grep -q '{"error"\|"message"\|"status"'; then
                log_pass "Error message uses consistent format: $test"
            else
                log_warn "Error message format may be inconsistent: $test"
            fi
        fi
        
        log_info "Error test $test - Status: $status_code"
    done
}

# Test 10: API Documentation Security
test_api_documentation_security() {
    log_test "Testing API Documentation Security"
    
    # Test for exposed API documentation
    local doc_endpoints=(
        "/api/docs"
        "/api/swagger"
        "/api/openapi"
        "/api/documentation"
        "/docs"
        "/swagger"
        "/openapi.json"
    )
    
    for endpoint in "${doc_endpoints[@]}"; do
        local response=$(curl -s "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "000")
        
        log_info "Documentation endpoint $endpoint - Status: $status_code"
        
        if [ "$status_code" = "200" ]; then
            if echo "$response" | grep -q "swagger\|openapi\|api.*documentation"; then
                log_warn "API documentation exposed: $endpoint"
                
                # Check if documentation requires authentication
                if echo "$response" | grep -q "login\|authenticate\|unauthorized"; then
                    log_pass "API documentation requires authentication"
                else
                    log_fail "API documentation accessible without authentication"
                fi
            else
                log_pass "Endpoint $endpoint exists but is not API documentation"
            fi
        elif [ "$status_code" = "401" ] || [ "$status_code" = "403" ]; then
            log_pass "Documentation endpoint properly secured: $endpoint"
        elif [ "$status_code" = "404" ]; then
            log_pass "Documentation endpoint not exposed: $endpoint"
        else
            log_warn "Unexpected response for documentation endpoint $endpoint: $status_code"
        fi
    done
}

# Main test execution
main() {
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}🔒 API SECURITY AND RATE LIMITING TESTS 🔒${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${BLUE}Test started: $(date)${NC}"
    echo ""
    
    # Run all tests
    test_api_authentication
    test_rate_limiting
    test_api_key_security
    test_http_method_security
    test_cors_security
    test_request_size_limits
    test_json_security
    test_api_versioning_security
    test_error_message_security
    test_api_documentation_security
    
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
        echo -e "${GREEN}🎉 ALL API SECURITY TESTS PASSED!${NC}"
        exit 0
    else
        echo -e "${RED}⚠️ $TESTS_FAILED test(s) failed. Review issues above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"