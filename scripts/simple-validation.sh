#!/bin/bash
# Simple validation script for Garuda Security Suite

echo "========================================"
echo "Garuda Security Suite Simple Validation"
echo "========================================"

# Test 1: Configuration files
echo "Testing configuration files..."
if [ -f "./configs/security-config.conf" ]; then
    echo "✓ Security configuration file exists"
else
    echo "✗ Security configuration file missing"
fi

if [ -f "./web-dashboard/config/dashboard.conf" ]; then
    echo "✓ Dashboard configuration file exists"
else
    echo "✗ Dashboard configuration file missing"
fi

# Test 2: Database files
echo ""
echo "Testing database files..."
if [ -f "./configs/threat_intelligence/ioc_database.db" ]; then
    echo "✓ Threat intelligence database exists"
else
    echo "✗ Threat intelligence database missing"
fi

# Test 3: Scripts
echo ""
echo "Testing scripts..."
scripts=("behavioral-analysis.sh" "behavioral-monitor.sh" "threat-intelligence-v2.sh" "incident-response.sh")
for script in "${scripts[@]}"; do
    if [ -f "./scripts/$script" ]; then
        echo "✓ Script $script exists"
    else
        echo "✗ Script $script missing"
    fi
done

# Test 4: Dashboard files
echo ""
echo "Testing dashboard files..."
if [ -f "./web-dashboard/app.py" ]; then
    echo "✓ Dashboard app.py exists"
else
    echo "✗ Dashboard app.py missing"
fi

if [ -f "./web-dashboard/auth.py" ]; then
    echo "✓ Dashboard auth.py exists"
else
    echo "✗ Dashboard auth.py missing"
fi

# Test 5: API files
echo ""
echo "Testing API files..."
api_files=("system.py" "behavioral.py" "threats.py" "incidents.py")
for api_file in "${api_files[@]}"; do
    if [ -f "./web-dashboard/api/$api_file" ]; then
        echo "✓ API file $api_file exists"
    else
        echo "✗ API file $api_file missing"
    fi
done

# Test 6: Test scripts
echo ""
echo "Testing test scripts..."
test_dirs=("component-tests" "integration-tests" "performance-tests" "security-tests" "end-to-end-tests")
for test_dir in "${test_dirs[@]}"; do
    if [ -d "./$test_dir" ]; then
        count=$(find "./$test_dir" -name "*.sh" | wc -l)
        echo "✓ $test_dir directory exists with $count test scripts"
    else
        echo "✗ $test_dir directory missing"
    fi
done

# Test 7: Service file
echo ""
echo "Testing service file..."
if [ -f "./web-dashboard/garuda-dashboard.service" ]; then
    echo "✓ Systemd service file exists"
else
    echo "✗ Systemd service file missing"
fi

# Test 8: Installation script
echo ""
echo "Testing installation script..."
if [ -f "./web-dashboard/install-service.sh" ]; then
    echo "✓ Service installation script exists"
else
    echo "✗ Service installation script missing"
fi

echo ""
echo "========================================"
echo "Validation completed"
echo "========================================"