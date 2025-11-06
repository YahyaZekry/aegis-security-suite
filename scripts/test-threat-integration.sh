#!/bin/bash
# Test Threat Intelligence Integration
# Simple test script to verify IOC database and API functionality

source "$(dirname "$0")/common-functions.sh"

# Load configuration
SECURITY_SUITE_HOME="$(dirname "$(dirname "$0")"
source "$SECURITY_SUITE_HOME/configs/security-config.conf" 2>/dev/null || {
    THREAT_DB_DIR="$SECURITY_SUITE_HOME/configs/threat_intelligence"
    IOC_DATABASE="$THREAT_DB_DIR/ioc_database.db"
}

# Test IOC database functionality
test_ioc_database() {
    log_info "Testing IOC database functionality..."
    
    # Check if database exists
    if [ ! -f "$IOC_DATABASE" ]; then
        log_error "IOC database not found: $IOC_DATABASE"
        return 1
    fi
    
    # Test database integrity
    if sqlite3 "$IOC_DATABASE" "PRAGMA integrity_check;" | grep -q "ok"; then
        log_success "IOC database integrity: OK"
    else
        log_error "IOC database integrity: FAILED"
        return 1
    fi
    
    # Add test IOCs
    log_info "Adding test IOCs..."
    
    sqlite3 "$IOC_DATABASE" << EOF
INSERT OR IGNORE INTO ioc_ips (ip_address, source, threat_type, confidence, feed_url)
VALUES ('192.168.1.100', 'test', 'test_ip', 95, 'test_feed');

INSERT OR IGNORE INTO ioc_domains (domain, source, threat_type, confidence, feed_url)
VALUES ('malicious.example.com', 'test', 'test_domain', 90, 'test_feed');

INSERT OR IGNORE INTO ioc_urls (url, source, threat_type, confidence, feed_url)
VALUES ('https://malicious.example.com/bad', 'test', 'test_url', 85, 'test_feed');

INSERT OR IGNORE INTO ioc_hashes (file_hash, hash_type, source, threat_type, confidence, feed_url)
VALUES ('d41d8cd98f00b204e9800998ecf8427e', 'md5', 'test', 'test_hash', 95, 'test_feed');
EOF
    
    # Verify test IOCs were added
    local ip_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_ips WHERE source = 'test'")
    local domain_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_domains WHERE source = 'test'")
    local url_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_urls WHERE source = 'test'")
    local hash_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_hashes WHERE source = 'test'")
    
    log_info "Test IOCs added: $ip_count IPs, $domain_count domains, $url_count URLs, $hash_count hashes"
    
    if [ $ip_count -gt 0 ] && [ $domain_count -gt 0 ] && [ $url_count -gt 0 ] && [ $hash_count -gt 0 ]; then
        log_success "IOC database test: PASSED"
        return 0
    else
        log_error "IOC database test: FAILED"
        return 1
    fi
}

# Test threat feed functionality
test_threat_feeds() {
    log_info "Testing threat feed functionality..."
    
    # Add test feeds to database
    sqlite3 "$IOC_DATABASE" << EOF
INSERT OR REPLACE INTO threat_feeds (feed_name, feed_url, feed_type, status, active)
VALUES 
('test_feed_1', 'https://example.com/feed1.txt', 'test', 'active', 1),
('test_feed_2', 'https://example.com/feed2.txt', 'test', 'active', 1);
EOF
    
    # Get feed status
    local feed_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM threat_feeds WHERE feed_type = 'test'")
    
    if [ $feed_count -ge 2 ]; then
        log_success "Threat feeds test: PASSED ($feed_count test feeds found)"
        return 0
    else
        log_error "Threat feeds test: FAILED ($feed_count test feeds found)"
        return 1
    fi
}

# Test API integration
test_api_integration() {
    log_info "Testing API integration..."
    
    # Test if web dashboard is running
    if curl -s http://localhost:8080/api/threats/iocs/stats 2>/dev/null | grep -q "total_iocs"; then
        log_success "API integration test: PASSED"
        return 0
    else
        log_warning "API integration test: FAILED (web dashboard may not be running)"
        return 1
    fi
}

# Test IOC validation
test_ioc_validation() {
    log_info "Testing IOC validation..."
    
    # Test IP validation
    if curl -s -X POST http://localhost:8080/api/threats/iocs \
        -H "Content-Type: application/json" \
        -d '{"ioc_value": "192.168.1.1", "ioc_type": "ip", "description": "Test IP", "severity": "medium", "source": "test"}' \
        2>/dev/null | grep -q "success.*true"; then
        log_success "IP IOC validation test: PASSED"
    else
        log_warning "IP IOC validation test: FAILED"
    fi
    
    # Test domain validation
    if curl -s -X POST http://localhost:8080/api/threats/iocs \
        -H "Content-Type: application/json" \
        -d '{"ioc_value": "malicious.example.com", "ioc_type": "domain", "description": "Test Domain", "severity": "high", "source": "test"}' \
        2>/dev/null | grep -q "success.*true"; then
        log_success "Domain IOC validation test: PASSED"
    else
        log_warning "Domain IOC validation test: FAILED"
    fi
}

# Main test execution
main() {
    log_info "Starting threat intelligence integration tests..."
    
    local tests_passed=0
    local tests_total=4
    
    # Run tests
    test_ioc_database && ((tests_passed++))
    test_threat_feeds && ((tests_passed++))
    test_api_integration && ((tests_passed++))
    test_ioc_validation && ((tests_passed++))
    
    # Summary
    log_info "Test Summary: $tests_passed/$tests_total tests passed"
    
    if [ "$tests_passed" -eq "$tests_total" ]; then
        log_success "All threat intelligence tests PASSED"
        return 0
    else
        log_error "Some threat intelligence tests FAILED"
        return 1
    fi
}

# Run main function
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi