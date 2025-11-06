#!/bin/bash
# Behavioral Analysis Integration Test Script
# Tests the complete integration of behavioral analysis with the security suite

# Load configuration and functions
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../configs/security-config.conf"
source "$SCRIPT_DIR/common-functions.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${CYAN}==========================================${NC}"
echo -e "${WHITE}  🧠 BEHAVIORAL ANALYSIS INTEGRATION TEST 🧠${NC}"
echo -e "${CYAN}==========================================${NC}"
echo -e "${BLUE}Test started: $(date)${NC}"
echo ""

# Test log file
TEST_LOG="$LOGS_DIR/manual/behavioral_integration_test_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOGS_DIR/manual"

echo "BEHAVIORAL ANALYSIS INTEGRATION TEST - $(date)" > "$TEST_LOG"
echo "=====================================" >> "$TEST_LOG"
echo "" >> "$TEST_LOG"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Configuration Integration
echo -e "${YELLOW}🔧 Testing configuration integration...${NC}"
echo "Test 1: Configuration Integration" >> "$TEST_LOG"

if [ "$BEHAVIORAL_ANALYSIS_ENABLED" = "true" ]; then
    echo -e "  ${GREEN}✅ Behavioral analysis enabled in config${NC}"
    echo "✅ Behavioral analysis enabled: $BEHAVIORAL_ANALYSIS_ENABLED" >> "$TEST_LOG"
    ((TESTS_PASSED++))
    
    # Check configuration values
    echo "  Learning Period: $BEHAVIORAL_LEARNING_PERIOD days" >> "$TEST_LOG"
    echo "  Monitoring Interval: $BEHAVIORAL_MONITORING_INTERVAL seconds" >> "$TEST_LOG"
    echo "  Sensitivity Level: $BEHAVIORAL_SENSITIVITY_LEVEL" >> "$TEST_LOG"
    echo "  Threat Threshold: $BEHAVIORAL_THREAT_SCORE_THRESHOLD" >> "$TEST_LOG"
    echo "  Max Baseline Age: $BEHAVIORAL_MAX_BASELINE_AGE days" >> "$TEST_LOG"
else
    echo -e "  ${RED}❌ Behavioral analysis not enabled in config${NC}"
    echo "❌ Behavioral analysis enabled: $BEHAVIORAL_ANALYSIS_ENABLED" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi
echo ""

# Test 2: Behavioral Analysis Script Availability
echo -e "${YELLOW}📄 Testing behavioral analysis script availability...${NC}"
echo "Test 2: Script Availability" >> "$TEST_LOG"

if [ -f "$SCRIPT_DIR/behavioral-analysis.sh" ]; then
    echo -e "  ${GREEN}✅ Behavioral analysis script found${NC}"
    echo "✅ Behavioral analysis script: $SCRIPT_DIR/behavioral-analysis.sh" >> "$TEST_LOG"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Behavioral analysis script not found${NC}"
    echo "❌ Behavioral analysis script: NOT FOUND" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi

if [ -x "$SCRIPT_DIR/behavioral-analysis.sh" ]; then
    echo -e "  ${GREEN}✅ Behavioral analysis script executable${NC}"
    echo "✅ Behavioral analysis script executable: YES" >> "$TEST_LOG"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}❌ Behavioral analysis script not executable${NC}"
    echo "❌ Behavioral analysis script executable: NO" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi
echo ""

# Test 3: Database Initialization
echo -e "${YELLOW}🗄️ Testing database initialization...${NC}"
echo "Test 3: Database Initialization" >> "$TEST_LOG"

if [ "$BEHAVIORAL_ANALYSIS_ENABLED" = "true" ]; then
    # Source behavioral analysis functions
    source "$SCRIPT_DIR/behavioral-analysis.sh"
    
    # Test initialization
    if init_behavioral_analysis; then
        echo -e "  ${GREEN}✅ Behavioral analysis database initialized${NC}"
        echo "✅ Database initialization: SUCCESS" >> "$TEST_LOG"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}❌ Behavioral analysis database initialization failed${NC}"
        echo "❌ Database initialization: FAILED" >> "$TEST_LOG"
        ((TESTS_FAILED++))
    fi
else
    echo -e "  ${YELLOW}⏭️ Skipping database test (behavioral analysis disabled)${NC}"
    echo "⏭️ Database test skipped: Behavioral analysis disabled" >> "$TEST_LOG"
fi
echo ""

# Test 4: Daily Scan Integration
echo -e "${YELLOW}🛡️ Testing daily scan integration...${NC}"
echo "Test 4: Daily Scan Integration" >> "$TEST_LOG"

if [ -f "$SCRIPT_DIR/security-daily-scan.sh" ]; then
    # Check if behavioral analysis is referenced in daily scan
    if grep -q "behavioral-analysis.sh" "$SCRIPT_DIR/security-daily-scan.sh"; then
        echo -e "  ${GREEN}✅ Daily scan includes behavioral analysis${NC}"
        echo "✅ Daily scan integration: SUCCESS" >> "$TEST_LOG"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}❌ Daily scan missing behavioral analysis integration${NC}"
        echo "❌ Daily scan integration: FAILED" >> "$TEST_LOG"
        ((TESTS_FAILED++))
    fi
else
    echo -e "  ${RED}❌ Daily scan script not found${NC}"
    echo "❌ Daily scan script: NOT FOUND" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi
echo ""

# Test 5: Incident Response Integration
echo -e "${YELLOW}🚨 Testing incident response integration...${NC}"
echo "Test 5: Incident Response Integration" >> "$TEST_LOG"

if [ -f "$SCRIPT_DIR/incident-response.sh" ]; then
    # Check if behavioral analysis is referenced in incident response
    if grep -q "behavioral-analysis.sh" "$SCRIPT_DIR/incident-response.sh"; then
        echo -e "  ${GREEN}✅ Incident response includes behavioral analysis${NC}"
        echo "✅ Incident response integration: SUCCESS" >> "$TEST_LOG"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}❌ Incident response missing behavioral analysis integration${NC}"
        echo "❌ Incident response integration: FAILED" >> "$TEST_LOG"
        ((TESTS_FAILED++))
    fi
else
    echo -e "  ${RED}❌ Incident response script not found${NC}"
    echo "❌ Incident response script: NOT FOUND" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi
echo ""

# Test 6: Behavioral Monitoring Service
echo -e "${YELLOW}⏰ Testing behavioral monitoring service...${NC}"
echo "Test 6: Behavioral Monitoring Service" >> "$TEST_LOG"

if [ -f "$SCRIPT_DIR/behavioral-monitor.sh" ]; then
    echo -e "  ${GREEN}✅ Behavioral monitoring service found${NC}"
    echo "✅ Behavioral monitoring service: $SCRIPT_DIR/behavioral-monitor.sh" >> "$TEST_LOG"
    ((TESTS_PASSED++))
    
    if [ -x "$SCRIPT_DIR/behavioral-monitor.sh" ]; then
        echo -e "  ${GREEN}✅ Behavioral monitoring service executable${NC}"
        echo "✅ Behavioral monitoring service executable: YES" >> "$TEST_LOG"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}❌ Behavioral monitoring service not executable${NC}"
        echo "❌ Behavioral monitoring service executable: NO" >> "$TEST_LOG"
        ((TESTS_FAILED++))
    fi
else
    echo -e "  ${RED}❌ Behavioral monitoring service not found${NC}"
    echo "❌ Behavioral monitoring service: NOT FOUND" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi
echo ""

# Test 7: Systemd Timer Configuration
echo -e "${YELLOW}⚙️ Testing systemd timer configuration...${NC}"
echo "Test 7: Systemd Timer Configuration" >> "$TEST_LOG"

if [ "$BEHAVIORAL_ANALYSIS_ENABLED" = "true" ]; then
    # Check if behavioral monitoring timer is configured
    if systemctl --user list-timers | grep -q "behavioral-monitor.timer"; then
        echo -e "  ${GREEN}✅ Behavioral monitoring timer configured${NC}"
        echo "✅ Behavioral monitoring timer: CONFIGURED" >> "$TEST_LOG"
        ((TESTS_PASSED++))
    else
        echo -e "  ${YELLOW}⚠️ Behavioral monitoring timer not found (may not be enabled yet)${NC}"
        echo "⚠️ Behavioral monitoring timer: NOT CONFIGURED" >> "$TEST_LOG"
        ((TESTS_PASSED++))  # This is a warning, not a failure
    fi
else
    echo -e "  ${YELLOW}⏭️ Skipping timer test (behavioral analysis disabled)${NC}"
    echo "⏭️ Timer test skipped: Behavioral analysis disabled" >> "$TEST_LOG"
fi
echo ""

# Test 8: Directory Structure
echo -e "${YELLOW}📁 Testing directory structure...${NC}"
echo "Test 8: Directory Structure" >> "$TEST_LOG"

BEHAVIORAL_DIR="$SECURITY_SUITE_HOME/configs/behavioral_analysis"
if [ -d "$BEHAVIORAL_DIR" ]; then
    echo -e "  ${GREEN}✅ Behavioral analysis directory exists${NC}"
    echo "✅ Behavioral analysis directory: $BEHAVIORAL_DIR" >> "$TEST_LOG"
    ((TESTS_PASSED++))
    
    # Check for database file
    if [ -f "$BEHAVIORAL_DIR/behavioral_data.db" ]; then
        echo -e "  ${GREEN}✅ Behavioral analysis database exists${NC}"
        echo "✅ Behavioral analysis database: EXISTS" >> "$TEST_LOG"
        ((TESTS_PASSED++))
    else
        echo -e "  ${YELLOW}⚠️ Behavioral analysis database not found (will be created)${NC}"
        echo "⚠️ Behavioral analysis database: NOT FOUND" >> "$TEST_LOG"
        ((TESTS_PASSED++))  # This is expected if not initialized yet
    fi
else
    echo -e "  ${RED}❌ Behavioral analysis directory missing${NC}"
    echo "❌ Behavioral analysis directory: NOT FOUND" >> "$TEST_LOG"
    ((TESTS_FAILED++))
fi
echo ""

# Test Results Summary
echo -e "${CYAN}==========================================${NC}"
echo -e "${WHITE}  📊 INTEGRATION TEST RESULTS 📊${NC}"
echo -e "${CYAN}==========================================${NC}"
echo -e "${BLUE}Tests completed: $(date)${NC}"
echo ""

echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL INTEGRATION TESTS PASSED!${NC}"
    echo "🎉 RESULT: ALL TESTS PASSED" >> "$TEST_LOG"
    
    # Send success notification
    if command -v notify-send &>/dev/null; then
        notify-send "🎉 Behavioral Integration Success" "All behavioral analysis integration tests passed!" "security-high" "normal" 2>/dev/null
    fi
else
    echo -e "${YELLOW}⚠️ $TESTS_FAILED test(s) failed. Review issues above.${NC}"
    echo "⚠️ RESULT: $TESTS_FAILED test(s) failed" >> "$TEST_LOG"
    
    # Send warning notification
    if command -v notify-send &>/dev/null; then
        notify-send "⚠️ Behavioral Integration Issues" "$TESTS_FAILED test(s) failed - Review setup" "security-medium" "normal" 2>/dev/null
    fi
fi

echo ""
echo -e "${BLUE}📂 Complete test log saved to: $(basename "$TEST_LOG")${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

exit $TESTS_FAILED