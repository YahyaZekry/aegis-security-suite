#!/usr/bin/env python3
"""
Garuda Security Suite Web Dashboard Test Script
Tests dashboard functionality and API endpoints
"""

import os
import sys
import json
import time
import requests
import sqlite3
from datetime import datetime

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Test configuration
DASHBOARD_URL = "http://localhost:8080"
TEST_USER = "admin"
TEST_PASS = "admin"

def print_test_header(test_name):
    """Print test header"""
    print(f"\n{'='*60}")
    print(f"TEST: {test_name}")
    print(f"{'='*60}")

def print_test_result(test_name, success, message=""):
    """Print test result"""
    status = "✅ PASS" if success else "❌ FAIL"
    print(f"{status} - {test_name}")
    if message:
        print(f"    {message}")

def test_dashboard_accessibility():
    """Test if dashboard is accessible"""
    print_test_header("Dashboard Accessibility")
    
    try:
        # Test main page
        response = requests.get(f"{DASHBOARD_URL}/", timeout=5)
        print_test_result("Main Page Redirect", response.status_code == 302, 
                        f"Status code: {response.status_code}")
        
        # Test login page
        response = requests.get(f"{DASHBOARD_URL}/login", timeout=5)
        print_test_result("Login Page", response.status_code == 200, 
                        f"Status code: {response.status_code}")
        
        return True
        
    except requests.exceptions.RequestException as e:
        print_test_result("Dashboard Connection", False, f"Connection error: {e}")
        return False

def test_authentication():
    """Test authentication functionality"""
    print_test_header("Authentication")
    
    try:
        # Test login with valid credentials
        session = requests.Session()
        login_data = {
            'username': TEST_USER,
            'password': TEST_PASS
        }
        
        response = session.post(f"{DASHBOARD_URL}/login", data=login_data, timeout=5)
        
        if response.status_code == 302:
            print_test_result("Valid Login", True, "Login successful")
            
            # Test accessing protected page
            response = session.get(f"{DASHBOARD_URL}/dashboard", timeout=5)
            print_test_result("Protected Page Access", response.status_code == 200,
                            f"Status code: {response.status_code}")
            
            # Test logout
            response = session.get(f"{DASHBOARD_URL}/logout", timeout=5)
            print_test_result("Logout", response.status_code == 302,
                            f"Status code: {response.status_code}")
            
            return session
        else:
            print_test_result("Valid Login", False, f"Status code: {response.status_code}")
            return None
            
    except requests.exceptions.RequestException as e:
        print_test_result("Authentication Test", False, f"Request error: {e}")
        return None

def test_api_endpoints(session):
    """Test API endpoints"""
    print_test_header("API Endpoints")
    
    try:
        # Test system status API
        response = session.get(f"{DASHBOARD_URL}/api/system/status", timeout=5)
        print_test_result("System Status API", response.status_code == 200,
                        f"Status code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print_test_result("System Status Data", 'status' in data,
                            f"Contains status field: {'status' in data}")
        
        # Test behavioral metrics API
        response = session.get(f"{DASHBOARD_URL}/api/behavioral/metrics", timeout=5)
        print_test_result("Behavioral Metrics API", response.status_code in [200, 404],
                        f"Status code: {response.status_code}")
        
        # Test threats IOCs API
        response = session.get(f"{DASHBOARD_URL}/api/threats/iocs", timeout=5)
        print_test_result("Threats IOCs API", response.status_code in [200, 404],
                        f"Status code: {response.status_code}")
        
        # Test incidents API
        response = session.get(f"{DASHBOARD_URL}/api/incidents", timeout=5)
        print_test_result("Incidents API", response.status_code in [200, 404],
                        f"Status code: {response.status_code}")
        
        return True
        
    except requests.exceptions.RequestException as e:
        print_test_result("API Test", False, f"Request error: {e}")
        return False

def test_database_integration():
    """Test database integration"""
    print_test_header("Database Integration")
    
    try:
        # Test behavioral analysis database
        behavioral_db = "/opt/garuda-security-suite/configs/behavioral_analysis/behavioral_analysis.db"
        if os.path.exists(behavioral_db):
            conn = sqlite3.connect(behavioral_db)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            conn.close()
            print_test_result("Behavioral Database", True, 
                            f"Found {len(tables)} tables")
        else:
            print_test_result("Behavioral Database", False, "Database not found")
        
        # Test incident database
        incident_db = "/opt/garuda-security-suite/configs/incident_response/incidents.db"
        if os.path.exists(incident_db):
            conn = sqlite3.connect(incident_db)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            conn.close()
            print_test_result("Incident Database", True, 
                            f"Found {len(tables)} tables")
        else:
            print_test_result("Incident Database", False, "Database not found")
        
        # Test threat intelligence database
        threat_db = "/opt/garuda-security-suite/configs/threat_intelligence/ioc_database.db"
        if os.path.exists(threat_db):
            conn = sqlite3.connect(threat_db)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            conn.close()
            print_test_result("Threat Database", True, 
                            f"Found {len(tables)} tables")
        else:
            print_test_result("Threat Database", False, "Database not found")
        
        return True
        
    except Exception as e:
        print_test_result("Database Integration", False, f"Error: {e}")
        return False

def test_security_suite_integration():
    """Test security suite integration"""
    print_test_header("Security Suite Integration")
    
    try:
        # Check security suite home
        security_home = os.environ.get('SECURITY_SUITE_HOME', '/opt/garuda-security-suite')
        print_test_result("Security Suite Home", os.path.exists(security_home),
                        f"Path: {security_home}")
        
        # Check configuration file
        config_file = os.path.join(security_home, "configs", "security-config.conf")
        print_test_result("Security Config", os.path.exists(config_file),
                        f"Path: {config_file}")
        
        # Check scripts directory
        scripts_dir = os.path.join(security_home, "scripts")
        print_test_result("Scripts Directory", os.path.exists(scripts_dir),
                        f"Path: {scripts_dir}")
        
        # Check key scripts
        key_scripts = [
            "behavioral-analysis.sh",
            "behavioral-monitor.sh",
            "threat-intelligence-v2.sh",
            "incident-response.sh",
            "security-daily-scan.sh"
        ]
        
        for script in key_scripts:
            script_path = os.path.join(scripts_dir, script)
            print_test_result(f"Script: {script}", os.path.exists(script_path),
                            f"Path: {script_path}")
        
        return True
        
    except Exception as e:
        print_test_result("Security Suite Integration", False, f"Error: {e}")
        return False

def test_static_files():
    """Test static files accessibility"""
    print_test_header("Static Files")
    
    try:
        # Test CSS file
        response = requests.get(f"{DASHBOARD_URL}/static/css/dashboard.css", timeout=5)
        print_test_result("CSS File", response.status_code == 200,
                        f"Status code: {response.status_code}")
        
        # Test JavaScript file
        response = requests.get(f"{DASHBOARD_URL}/static/js/dashboard.js", timeout=5)
        print_test_result("JavaScript File", response.status_code == 200,
                        f"Status code: {response.status_code}")
        
        return True
        
    except requests.exceptions.RequestException as e:
        print_test_result("Static Files Test", False, f"Request error: {e}")
        return False

def test_websocket_connection():
    """Test WebSocket connection"""
    print_test_header("WebSocket Connection")
    
    try:
        import socketio
        
        # Create SocketIO client
        sio = socketio.Client()
        
        connected = False
        connection_error = None
        
        @sio.event
        def connect():
            nonlocal connected
            connected = True
            print_test_result("WebSocket Connection", True, "Connected successfully")
            sio.disconnect()
        
        @sio.event
        def connect_error(data):
            nonlocal connection_error
            connection_error = str(data)
        
        # Connect to dashboard
        sio.connect(DASHBOARD_URL, wait_timeout=5)
        
        if not connected and not connection_error:
            print_test_result("WebSocket Connection", False, "Connection timeout")
        elif connection_error:
            print_test_result("WebSocket Connection", False, f"Error: {connection_error}")
        
        return connected
        
    except ImportError:
        print_test_result("WebSocket Test", False, "python-socketio not available")
        return False
    except Exception as e:
        print_test_result("WebSocket Test", False, f"Error: {e}")
        return False

def generate_test_report(results):
    """Generate test report"""
    print_test_header("Test Summary")
    
    total_tests = len(results)
    passed_tests = sum(1 for result in results.values() if result)
    failed_tests = total_tests - passed_tests
    
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {passed_tests}")
    print(f"Failed: {failed_tests}")
    print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
    
    if failed_tests == 0:
        print("\n🎉 All tests passed! Dashboard is working correctly.")
    else:
        print(f"\n⚠️  {failed_tests} test(s) failed. Please check the issues above.")
    
    # Save report to file
    report = {
        'timestamp': datetime.now().isoformat(),
        'total_tests': total_tests,
        'passed_tests': passed_tests,
        'failed_tests': failed_tests,
        'success_rate': (passed_tests/total_tests)*100,
        'results': results
    }
    
    report_file = f"dashboard_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(report_file, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\n📄 Detailed report saved to: {report_file}")

def main():
    """Main test function"""
    print("🔍 Garuda Security Suite Dashboard Test")
    print(f"Testing dashboard at: {DASHBOARD_URL}")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    results = {}
    
    # Run tests
    results['dashboard_accessibility'] = test_dashboard_accessibility()
    
    if results['dashboard_accessibility']:
        session = test_authentication()
        if session:
            results['authentication'] = True
            results['api_endpoints'] = test_api_endpoints(session)
            results['static_files'] = test_static_files()
            results['websocket'] = test_websocket_connection()
        else:
            results['authentication'] = False
            results['api_endpoints'] = False
            results['static_files'] = False
            results['websocket'] = False
    else:
        results['authentication'] = False
        results['api_endpoints'] = False
        results['static_files'] = False
        results['websocket'] = False
    
    results['database_integration'] = test_database_integration()
    results['security_suite_integration'] = test_security_suite_integration()
    
    # Generate report
    generate_test_report(results)
    
    # Return exit code based on results
    failed_tests = sum(1 for result in results.values() if not result)
    return 0 if failed_tests == 0 else 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)