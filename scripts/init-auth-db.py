#!/usr/bin/env python3
"""
Initialize authentication database for Garuda Security Suite
"""

import os
import sys

# Add the web-dashboard directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'web-dashboard'))

# Set environment variable
os.environ['SECURITY_SUITE_HOME'] = '/mnt/AirFryer/Projects/Linux/garuda-security-suite'

# Import and initialize
from auth import ensure_auth_db

if ensure_auth_db():
    print("Authentication database initialized successfully")
else:
    print("Failed to initialize authentication database")
    sys.exit(1)