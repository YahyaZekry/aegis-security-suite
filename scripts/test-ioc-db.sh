#!/bin/bash
# Simple IOC Database Test

# Set paths
SECURITY_SUITE_HOME="$(dirname "$(dirname "$0)")"
THREAT_DB_DIR="$SECURITY_SUITE_HOME/configs/threat_intelligence"
IOC_DATABASE="$THREAT_DB_DIR/ioc_database.db"

echo "Testing threat intelligence database..."

# Check if database exists
if [ ! -f "$IOC_DATABASE" ]; then
    echo "ERROR: IOC database not found: $IOC_DATABASE"
    exit 1
fi

# Test database integrity
if sqlite3 "$IOC_DATABASE" "PRAGMA integrity_check;" | grep -q "ok"; then
    echo "SUCCESS: IOC database integrity: OK"
else
    echo "ERROR: IOC database integrity: FAILED"
    exit 1
fi

# Add test IOCs
echo "Adding test IOCs..."
sqlite3 "$IOC_DATABASE" "INSERT OR IGNORE INTO ioc_ips (ip_address, source, threat_type, confidence, feed_url) VALUES ('192.168.1.100', 'test', 'test_ip', 95, 'test_feed');"
sqlite3 "$IOC_DATABASE" "INSERT OR IGNORE INTO ioc_domains (domain, source, threat_type, confidence, feed_url) VALUES ('malicious.example.com', 'test', 'test_domain', 90, 'test_feed');"
sqlite3 "$IOC_DATABASE" "INSERT OR IGNORE INTO ioc_urls (url, source, threat_type, confidence, feed_url) VALUES ('https://malicious.example.com/bad', 'test', 'test_url', 85, 'test_feed');"
sqlite3 "$IOC_DATABASE" "INSERT OR IGNORE INTO ioc_hashes (file_hash, hash_type, source, threat_type, confidence, feed_url) VALUES ('d41d8cd98f00b204e9800998ecf8427e', 'md5', 'test', 'test_hash', 95, 'test_feed');"

# Verify test IOCs were added
ip_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_ips WHERE source = 'test'")
domain_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_domains WHERE source = 'test'")
url_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_urls WHERE source = 'test'")
hash_count=$(sqlite3 "$IOC_DATABASE" "SELECT COUNT(*) FROM ioc_hashes WHERE source = 'test'")

echo "Test IOCs added: $ip_count IPs, $domain_count domains, $url_count URLs, $hash_count hashes"

if [ $ip_count -gt 0 ] && [ $domain_count -gt 0 ] && [ $url_count -gt 0 ] && [ $hash_count -gt 0 ]; then
    echo "SUCCESS: IOC database test: PASSED"
    exit 0
else
    echo "ERROR: IOC database test: FAILED"
    exit 1
fi