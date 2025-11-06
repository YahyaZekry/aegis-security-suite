#!/bin/bash
# Authentication and Authorization Security Tests
# Tests authentication mechanisms, session management, and access controls

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

# Test 1: Password Security
test_password_security() {
    log_test "Testing Password Security"
    
    # Check for hardcoded passwords
    local scripts=(
        "$PROJECT_ROOT/scripts/behavioral-analysis.sh"
        "$PROJECT_ROOT/scripts/incident-response.sh"
        "$PROJECT_ROOT/scripts/security-daily-scan.sh"
        "$PROJECT_ROOT/web-dashboard/app.py"
    )
    
    local hardcoded_passwords=0
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            # Check for common password patterns
            if grep -i -E "(password|passwd|pwd).*=.*['\"](admin|password|123456|root|test)" "$script" 2>/dev/null; then
                log_fail "Hardcoded password found in $(basename "$script")"
                ((hardcoded_passwords++))
            else
                log_pass "No hardcoded passwords found in $(basename "$script")"
            fi
        fi
    done
    
    if [ "$hardcoded_passwords" -eq 0 ]; then
        log_pass "No hardcoded passwords found in any scripts"
    else
        log_fail "Hardcoded passwords found in $hardcoded_passwords scripts"
    fi
    
    # Check for password hashing
    if [ -f "$DASHBOARD_DIR/app.py" ]; then
        if grep -q "hashlib\|bcrypt\|sha256\|password_hash" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "Password hashing implemented"
        else
            log_fail "Password hashing not implemented"
        fi
    else
        log_warn "Dashboard app not found - cannot check password hashing"
    fi
}

# Test 2: Session Management Security
test_session_security() {
    log_test "Testing Session Management Security"
    
    if [ -f "$DASHBOARD_DIR/app.py" ]; then
        # Check for secure session configuration
        if grep -q "SECRET_KEY\|session\|cookie" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "Session management implemented"
            
            # Check for secure cookie settings
            if grep -q "secure.*True\|HttpOnly\|SameSite" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
                log_pass "Secure cookie settings found"
            else
                log_fail "Secure cookie settings missing"
            fi
            
            # Check for session timeout
            if grep -q "PERMANENT_SESSION_LIFETIME\|timeout\|expire" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
                log_pass "Session timeout configured"
            else
                log_warn "Session timeout may not be configured"
            fi
        else
            log_fail "Session management not implemented"
        fi
        
        # Check for session fixation protection
        if grep -q "session.*regenerate\|login.*session\|session.*destroy" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "Session fixation protection implemented"
        else
            log_fail "Session fixation protection not implemented"
        fi
    else
        log_fail "Dashboard app not found"
    fi
}

# Test 3: Authentication Bypass Attempts
test_authentication_bypass() {
    log_test "Testing Authentication Bypass Attempts"
    
    # Test SQL injection in login
    local sql_injection_attempts=(
        "' OR '1'='1"
        "admin'--"
        "' UNION SELECT 'admin','password'--"
        "'; DROP TABLE users;--"
    )
    
    for injection in "${sql_injection_attempts[@]}"; do
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$injection\",\"password\":\"test\"}" \
            "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            if echo "$response" | grep -q "success\|token\|authenticated"; then
                log_fail "SQL injection bypass successful: $injection"
            else
                log_pass "SQL injection blocked: $injection"
            fi
        else
            log_warn "No response from login API for SQL injection test"
        fi
    done
    
    # Test directory traversal in login
    local traversal_attempts=(
        "../../../etc/passwd"
        "..\\..\\..\\windows\\system32\\config\\sam"
        "%2e%2e%2f%2e%2e%2fetc%2fpasswd"
    )
    
    for traversal in "${traversal_attempts[@]}"; do
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$traversal\",\"password\":\"test\"}" \
            "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            if echo "$response" | grep -q "success\|token\|authenticated"; then
                log_fail "Directory traversal bypass successful: $traversal"
            else
                log_pass "Directory traversal blocked: $traversal"
            fi
        else
            log_warn "No response from login API for traversal test"
        fi
    done
}

# Test 4: Brute Force Protection
test_brute_force_protection() {
    log_test "Testing Brute Force Protection"
    
    # Test multiple failed login attempts
    local failed_attempts=0
    local blocked=false
    
    for i in {1..20}; do
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"testuser$i\",\"password\":\"wrongpassword\"}" \
            "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
        
        if [ -n "$response" ]; then
            if echo "$response" | grep -q "blocked\|rate.*limit\|too.*many"; then
                blocked=true
                break
            elif echo "$response" | grep -q "error\|invalid\|failed"; then
                ((failed_attempts++))
            fi
        fi
        
        sleep 0.1  # Small delay between attempts
    done
    
    if [ "$blocked" = true ]; then
        log_pass "Brute force protection activated after $failed_attempts attempts"
    else
        log_warn "Brute force protection may not be implemented (tested $failed_attempts attempts)"
    fi
    
    # Test account lockout
    if [ "$failed_attempts" -gt 10 ]; then
        # Try with the same username again to see if locked
        local lockout_response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"testuser1\",\"password\":\"wrongpassword\"}" \
            "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
        
        if echo "$lockout_response" | grep -q "locked\|disabled\|temporarily"; then
            log_pass "Account lockout implemented"
        else
            log_warn "Account lockout may not be implemented"
        fi
    fi
}

# Test 5: Authorization Testing
test_authorization() {
    log_test "Testing Authorization Controls"
    
    # Test accessing protected endpoints without authentication
    local protected_endpoints=(
        "/api/behavioral/metrics"
        "/api/threats/iocs"
        "/api/incidents"
        "/dashboard"
        "/config"
    )
    
    local unauthorized_access=0
    for endpoint in "${protected_endpoints[@]}"; do
        local response=$(curl -s "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "")
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARD_URL$endpoint" 2>/dev/null || echo "000")
        
        if [ "$status_code" = "401" ] || [ "$status_code" = "403" ]; then
            log_pass "Protected endpoint properly secured: $endpoint ($status_code)"
        elif [ "$status_code" = "302" ]; then
            log_pass "Protected endpoint redirects to login: $endpoint ($status_code)"
        elif [ "$status_code" = "200" ]; then
            log_fail "Protected endpoint accessible without auth: $endpoint ($status_code)"
            ((unauthorized_access++))
        else
            log_warn "Unexpected response for protected endpoint: $endpoint ($status_code)"
        fi
    done
    
    if [ "$unauthorized_access" -eq 0 ]; then
        log_pass "All protected endpoints properly secured"
    else
        log_fail "$unauthorized_access protected endpoints accessible without authentication"
    fi
}

# Test 6: Session Hijacking Protection
test_session_hijacking() {
    log_test "Testing Session Hijacking Protection"
    
    # Test session cookie security
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"admin\",\"password\":\"admin\"}" \
        -c /tmp/test_cookies.txt \
        "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
    
    if [ -n "$login_response" ]; then
        # Check cookie security attributes
        if [ -f /tmp/test_cookies.txt ]; then
            local cookie_content=$(cat /tmp/test_cookies.txt)
            
            if echo "$cookie_content" | grep -q "Secure\; HttpOnly"; then
                log_pass "Session cookies have security attributes"
            else
                log_fail "Session cookies missing security attributes"
            fi
            
            # Test session fixation
            local session_id=$(echo "$cookie_content" | grep -o "session=[^;]*" | cut -d'=' -f2 || echo "")
            if [ -n "$session_id" ]; then
                # Try to access with manipulated session
                local manipulated_response=$(curl -s -H "Cookie: session=$session_id" "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
                
                if [ -n "$manipulated_response" ]; then
                    if echo "$manipulated_response" | grep -q "error\|unauthorized\|invalid"; then
                        log_pass "Session manipulation detected and blocked"
                    else
                        log_fail "Session manipulation not detected"
                    fi
                else
                    log_warn "No response for session manipulation test"
                fi
            else
                log_warn "No session ID found in cookies"
            fi
            
            rm -f /tmp/test_cookies.txt
        else
            log_fail "No cookies saved from login"
        fi
    else
        log_warn "Login failed - cannot test session security"
    fi
}

# Test 7: Multi-Factor Authentication
test_mfa() {
    log_test "Testing Multi-Factor Authentication"
    
    if [ -f "$DASHBOARD_DIR/app.py" ]; then
        # Check for MFA implementation
        if grep -q "2fa\|totp\|otp\|multi.*factor\|mfa" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "Multi-factor authentication implemented"
            
            # Check for TOTP/OTP validation
            if grep -q "pyotp\|totp\|otp.*verify\|google.*authenticator" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
                log_pass "TOTP/OTP validation implemented"
            else
                log_warn "TOTP/OTP validation may not be implemented"
            fi
            
            # Check for backup codes
            if grep -q "backup.*code\|recovery.*code\|emergency.*code" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
                log_pass "Backup/recovery codes implemented"
            else
                log_warn "Backup/recovery codes may not be implemented"
            fi
        else
            log_warn "Multi-factor authentication not implemented (may be optional)"
        fi
    else
        log_fail "Dashboard app not found"
    fi
}

# Test 8: Password Policy Enforcement
test_password_policy() {
    log_test "Testing Password Policy Enforcement"
    
    if [ -f "$DASHBOARD_DIR/app.py" ]; then
        # Check for password policy implementation
        if grep -q "password.*policy\|password.*require\|password.*strength\|password.*complexity" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "Password policy implemented"
            
            # Test weak password rejection
            local weak_passwords=("123456" "password" "admin" "qwerty" "abc123")
            local weak_rejected=0
            
            for weak_pass in "${weak_passwords[@]}"; do
                local response=$(curl -s -X POST \
                    -H "Content-Type: application/json" \
                    -d "{\"username\":\"testuser\",\"password\":\"$weak_pass\"}" \
                    "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
                
                if echo "$response" | grep -q "weak\|complexity\|require\|invalid"; then
                    ((weak_rejected++))
                fi
            done
            
            if [ "$weak_rejected" -gt 0 ]; then
                log_pass "Weak passwords rejected: $weak_rejected/${#weak_passwords[@]}"
            else
                log_warn "Weak password rejection may not be implemented"
            fi
        else
            log_warn "Password policy not implemented"
        fi
        
        # Check for password change functionality
        if grep -q "change.*password\|update.*password\|reset.*password" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "Password change/reset functionality implemented"
        else
            log_warn "Password change/reset functionality may not be implemented"
        fi
    else
        log_fail "Dashboard app not found"
    fi
}

# Test 9: API Key Security
test_api_key_security() {
    log_test "Testing API Key Security"
    
    if [ -f "$DASHBOARD_DIR/app.py" ]; then
        # Check for API key implementation
        if grep -q "api.*key\|apikey\|token.*auth\|bearer" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
            log_pass "API key authentication implemented"
            
            # Check for API key validation
            if grep -q "validate.*key\|verify.*token\|check.*apikey" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
                log_pass "API key validation implemented"
            else
                log_fail "API key validation not implemented"
            fi
            
            # Check for API key rotation
            if grep -q "rotate.*key\|expire.*key\|renew.*token" "$DASHBOARD_DIR/app.py" 2>/dev/null; then
                log_pass "API key rotation implemented"
            else
                log_warn "API key rotation may not be implemented"
            fi
        else
            log_warn "API key authentication not implemented"
        fi
    else
        log_fail "Dashboard app not found"
    fi
}

# Test 10: Logout and Session Termination
test_logout_security() {
    log_test "Testing Logout and Session Termination"
    
    # Test login first
    local login_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"admin\",\"password\":\"admin\"}" \
        -c /tmp/logout_test_cookies.txt \
        "$DASHBOARD_URL/api/login" 2>/dev/null || echo "")
    
    if [ -n "$login_response" ]; then
        # Test logout
        local logout_response=$(curl -s -X POST \
            -b /tmp/logout_test_cookies.txt \
            "$DASHBOARD_URL/api/logout" 2>/dev/null || echo "")
        
        if [ -n "$logout_response" ]; then
            if echo "$logout_response" | grep -q "success\|logged.*out\|session.*ended"; then
                log_pass "Logout successful"
            else
                log_fail "Logout response unclear"
            fi
            
            # Test session invalidation after logout
            local protected_response=$(curl -s -b /tmp/logout_test_cookies.txt \
                "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "")
            local status_code=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/logout_test_cookies.txt \
                "$DASHBOARD_URL/api/system/status" 2>/dev/null || echo "000")
            
            if [ "$status_code" = "401" ] || [ "$status_code" = "403" ]; then
                log_pass "Session properly invalidated after logout"
            elif [ "$status_code" = "302" ]; then
                log_pass "Session properly redirected after logout"
            else
                log_fail "Session not properly invalidated after logout: $status_code"
            fi
        else
            log_fail "Logout endpoint not responding"
        fi
        
        rm -f /tmp/logout_test_cookies.txt
    else
        log_warn "Login failed - cannot test logout security"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up authentication test environment..."
    
    # Clean up temporary files
    rm -f /tmp/test_cookies.txt
    rm -f /tmp/logout_test_cookies.txt
}

# Main test execution
main() {
    echo -e "${WHITE}========================================${NC}"
    echo -e "${WHITE}🔐 AUTHENTICATION SECURITY TESTS 🔐${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${BLUE}Test started: $(date)${NC}"
    echo ""
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run all tests
    test_password_security
    test_session_security
    test_authentication_bypass
    test_brute_force_protection
    test_authorization
    test_session_hijacking
    test_mfa
    test_password_policy
    test_api_key_security
    test_logout_security
    
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
        echo -e "${GREEN}🎉 ALL AUTHENTICATION SECURITY TESTS PASSED!${NC}"
        exit 0
    else
        echo -e "${RED}⚠️ $TESTS_FAILED test(s) failed. Review issues above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"