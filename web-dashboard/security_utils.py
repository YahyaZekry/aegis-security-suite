#!/usr/bin/env python3
"""
Security Utilities Module for Garuda Security Suite Dashboard
Provides comprehensive security functions including input validation, rate limiting,
API key management, and security logging
"""

import os
import re
import hashlib
import secrets
import time
import json
import sqlite3
import logging
from datetime import datetime, timedelta
from functools import wraps
from flask import request, jsonify, g, current_app
import bleach
from typing import Dict, List, Optional, Tuple, Any

# Configure security logging
security_logger = logging.getLogger('garuda_security')
security_logger.setLevel(logging.INFO)

# Create file handler for security logs
if not security_logger.handlers:
    log_dir = os.environ.get('SECURITY_SUITE_HOME', '/opt/garuda-security-suite')
    log_dir = os.path.join(log_dir, 'logs')
    os.makedirs(log_dir, exist_ok=True)
    
    file_handler = logging.FileHandler(os.path.join(log_dir, 'security.log'))
    file_handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(formatter)
    security_logger.addHandler(file_handler)

class InputValidator:
    """Comprehensive input validation and sanitization"""
    
    @staticmethod
    def sanitize_string(input_string: str, max_length: int = 1000) -> str:
        """Sanitize string input"""
        if not input_string:
            return ""
        
        # Limit length
        if len(input_string) > max_length:
            input_string = input_string[:max_length]
        
        # Remove potentially dangerous characters
        sanitized = bleach.clean(
            input_string,
            tags=[],
            attributes={},
            strip=True
        )
        
        return sanitized.strip()
    
    @staticmethod
    def validate_email(email: str) -> bool:
        """Validate email format"""
        if not email:
            return False
        
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    @staticmethod
    def validate_username(username: str) -> bool:
        """Validate username format"""
        if not username or len(username) < 3 or len(username) > 50:
            return False
        
        # Only allow alphanumeric characters, underscores, and hyphens
        pattern = r'^[a-zA-Z0-9_-]+$'
        return re.match(pattern, username) is not None
    
    @staticmethod
    def validate_ip_address(ip: str) -> bool:
        """Validate IP address format"""
        if not ip:
            return False
        
        # IPv4 validation
        ipv4_pattern = r'^^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        if re.match(ipv4_pattern, ip):
            return True
        
        # IPv6 validation (simplified)
        ipv6_pattern = r'^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'
        return re.match(ipv6_pattern, ip) is not None
    
    @staticmethod
    def validate_json_structure(data: Any, required_fields: List[str]) -> Tuple[bool, str]:
        """Validate JSON structure and required fields"""
        if not isinstance(data, dict):
            return False, "Invalid JSON structure"
        
        missing_fields = [field for field in required_fields if field not in data]
        if missing_fields:
            return False, f"Missing required fields: {', '.join(missing_fields)}"
        
        return True, ""
    
    @staticmethod
    def sanitize_filename(filename: str) -> str:
        """Sanitize filename to prevent path traversal"""
        if not filename:
            return ""
        
        # Remove path separators and dangerous characters
        sanitized = re.sub(r'[<>:"/\\|?*]', '', filename)
        sanitized = re.sub(r'\.\.', '', sanitized)  # Remove path traversal
        sanitized = sanitized.strip()
        
        # Limit length
        if len(sanitized) > 255:
            sanitized = sanitized[:255]
        
        return sanitized

class RateLimiter:
    """Rate limiting implementation for API endpoints"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.ensure_db()
    
    def ensure_db(self):
        """Ensure rate limiting database exists"""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS rate_limits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ip_address TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            request_count INTEGER DEFAULT 1,
            window_start TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """)
        
        cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_rate_limits_ip_endpoint 
        ON rate_limits(ip_address, endpoint)
        """)
        
        conn.commit()
        conn.close()
    
    def is_allowed(self, ip_address: str, endpoint: str, limit: int = 100, window: int = 60) -> Tuple[bool, Dict]:
        """Check if request is allowed based on rate limit"""
        now = datetime.now()
        window_start = (now - timedelta(seconds=window)).isoformat()
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Clean old entries
        cursor.execute("DELETE FROM rate_limits WHERE window_start < ?", (window_start,))
        
        # Check current rate
        cursor.execute("""
        SELECT request_count, window_start FROM rate_limits 
        WHERE ip_address = ? AND endpoint = ? AND window_start >= ?
        ORDER BY window_start DESC LIMIT 1
        """, (ip_address, endpoint, window_start))
        
        result = cursor.fetchone()
        
        if result:
            request_count, current_window_start = result
            if request_count >= limit:
                conn.close()
                return False, {
                    'error': 'Rate limit exceeded',
                    'limit': limit,
                    'window': window,
                    'current_count': request_count,
                    'retry_after': window
                }
            else:
                # Update existing record
                cursor.execute("""
                UPDATE rate_limits SET request_count = request_count + 1 
                WHERE ip_address = ? AND endpoint = ? AND window_start = ?
                """, (ip_address, endpoint, current_window_start))
        else:
            # Create new record
            cursor.execute("""
            INSERT INTO rate_limits (ip_address, endpoint, request_count, window_start, created_at)
            VALUES (?, ?, 1, ?, ?)
            """, (ip_address, endpoint, now.isoformat(), now.isoformat()))
        
        conn.commit()
        conn.close()
        
        return True, {'remaining': limit - (result[0] if result else 0)}

class APIKeyManager:
    """API key management for external integrations"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.ensure_db()
    
    def ensure_db(self):
        """Ensure API keys database exists"""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS api_keys (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key_name TEXT NOT NULL UNIQUE,
            api_key TEXT NOT NULL UNIQUE,
            permissions TEXT NOT NULL,
            is_active BOOLEAN DEFAULT 1,
            created_at TEXT NOT NULL,
            last_used TEXT,
            usage_count INTEGER DEFAULT 0,
            created_by TEXT
        )
        """)
        
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS api_key_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            api_key_id INTEGER NOT NULL,
            ip_address TEXT,
            endpoint TEXT,
            user_agent TEXT,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (api_key_id) REFERENCES api_keys (id)
        )
        """)
        
        conn.commit()
        conn.close()
    
    def generate_api_key(self, key_name: str, permissions: List[str], created_by: str) -> Dict:
        """Generate new API key"""
        api_key = f"garuda_{secrets.token_urlsafe(32)}"
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            cursor.execute("""
            INSERT INTO api_keys (key_name, api_key, permissions, created_at, created_by)
            VALUES (?, ?, ?, ?, ?)
            """, (key_name, api_key, json.dumps(permissions), datetime.now().isoformat(), created_by))
            
            conn.commit()
            
            return {
                'success': True,
                'api_key': api_key,
                'key_name': key_name,
                'permissions': permissions
            }
        except sqlite3.IntegrityError:
            return {'success': False, 'error': 'Key name already exists'}
        finally:
            conn.close()
    
    def validate_api_key(self, api_key: str, required_permission: str = None) -> Optional[Dict]:
        """Validate API key and check permissions"""
        if not api_key or not api_key.startswith('garuda_'):
            return None
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
        SELECT id, key_name, permissions, is_active, usage_count 
        FROM api_keys 
        WHERE api_key = ? AND is_active = 1
        """, (api_key,))
        
        result = cursor.fetchone()
        
        if not result:
            conn.close()
            return None
        
        key_id, key_name, permissions_json, is_active, usage_count = result
        permissions = json.loads(permissions_json)
        
        # Check specific permission if required
        if required_permission and required_permission not in permissions:
            conn.close()
            return None
        
        # Update usage
        cursor.execute("""
        UPDATE api_keys SET last_used = ?, usage_count = usage_count + 1 
        WHERE id = ?
        """, (datetime.now().isoformat(), key_id))
        
        # Log usage
        cursor.execute("""
        INSERT INTO api_key_usage (api_key_id, ip_address, endpoint, user_agent, timestamp)
        VALUES (?, ?, ?, ?, ?)
        """, (key_id, request.remote_addr if request else None, 
               request.endpoint if request else None,
               request.headers.get('User-Agent') if request else None,
               datetime.now().isoformat()))
        
        conn.commit()
        conn.close()
        
        return {
            'key_id': key_id,
            'key_name': key_name,
            'permissions': permissions
        }
    
    def revoke_api_key(self, key_name: str) -> Dict:
        """Revoke API key"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("UPDATE api_keys SET is_active = 0 WHERE key_name = ?", (key_name,))
        affected_rows = cursor.rowcount
        
        conn.commit()
        conn.close()
        
        if affected_rows > 0:
            return {'success': True, 'message': 'API key revoked'}
        else:
            return {'success': False, 'error': 'API key not found'}

class SecurityLogger:
    """Comprehensive security event logging"""
    
    @staticmethod
    def log_security_event(event_type: str, details: Dict, severity: str = 'INFO'):
        """Log security event"""
        # Safely get request context
        ip_address = None
        user_agent = None
        user_id = None
        
        try:
            if request:
                ip_address = request.remote_addr
                user_agent = request.headers.get('User-Agent')
        except RuntimeError:
            # Working outside of application context
            pass
        
        try:
            if hasattr(g, 'current_user'):
                user_id = getattr(g, 'current_user', {}).get('user_id')
        except RuntimeError:
            # Working outside of application context
            pass
        
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'event_type': event_type,
            'severity': severity,
            'ip_address': ip_address,
            'user_agent': user_agent,
            'user_id': user_id,
            'details': details
        }
        
        # Log to file
        security_logger.info(f"{event_type}: {json.dumps(log_entry)}")
        
        # Log to database if available
        try:
            auth_db_path = os.path.join(os.environ.get('SECURITY_SUITE_HOME', '/opt/garuda-security-suite'),
                                      'configs', 'web-dashboard', 'auth.db')
            
            if os.path.exists(auth_db_path):
                conn = sqlite3.connect(auth_db_path)
                cursor = conn.cursor()
                
                cursor.execute("""
                INSERT INTO auth_audit (user_id, action, ip_address, user_agent, timestamp, success, details)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    log_entry['user_id'],
                    event_type,
                    log_entry['ip_address'],
                    log_entry['user_agent'],
                    log_entry['timestamp'],
                    severity != 'ERROR',
                    json.dumps(details)
                ))
                
                conn.commit()
                conn.close()
        except Exception as e:
            security_logger.error(f"Failed to log to database: {e}")

# Initialize rate limiter and API key manager
RATE_LIMIT_DB = os.path.join(os.environ.get('SECURITY_SUITE_HOME', '/opt/garuda-security-suite'),
                             'configs', 'web-dashboard', 'rate_limits.db')
API_KEY_DB = os.path.join(os.environ.get('SECURITY_SUITE_HOME', '/opt/garuda-security-suite'),
                          'configs', 'web-dashboard', 'api_keys.db')

rate_limiter = RateLimiter(RATE_LIMIT_DB)
api_key_manager = APIKeyManager(API_KEY_DB)

# Decorators for security
def require_api_key(required_permission: str = None):
    """Decorator to require valid API key"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            api_key = request.headers.get('X-API-Key')
            
            if not api_key:
                SecurityLogger.log_security_event('api_key_missing', {
                    'endpoint': request.endpoint,
                    'method': request.method
                }, 'WARNING')
                return jsonify({'error': 'API key required'}), 401
            
            key_info = api_key_manager.validate_api_key(api_key, required_permission)
            
            if not key_info:
                SecurityLogger.log_security_event('api_key_invalid', {
                    'endpoint': request.endpoint,
                    'method': request.method,
                    'api_key_prefix': api_key[:10] + '...' if api_key else None
                }, 'WARNING')
                return jsonify({'error': 'Invalid or insufficient API key'}), 401
            
            # Store key info in Flask g
            g.api_key_info = key_info
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def rate_limit(limit: int = 100, window: int = 60):
    """Decorator to apply rate limiting"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            ip_address = request.remote_addr
            endpoint = request.endpoint or 'unknown'
            
            allowed, info = rate_limiter.is_allowed(ip_address, endpoint, limit, window)
            
            if not allowed:
                SecurityLogger.log_security_event('rate_limit_exceeded', {
                    'endpoint': endpoint,
                    'ip_address': ip_address,
                    'limit': limit,
                    'window': window
                }, 'WARNING')
                
                return jsonify({
                    'error': 'Rate limit exceeded',
                    'retry_after': info.get('retry_after', window)
                }), 429
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def validate_input(required_fields: List[str] = None, optional_fields: List[str] = None):
    """Decorator to validate and sanitize input"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if request.is_json:
                data = request.get_json()
            elif request.form:
                data = request.form.to_dict()
            else:
                data = {}
            
            # Validate required fields
            if required_fields:
                for field in required_fields:
                    if field not in data or not data[field]:
                        SecurityLogger.log_security_event('input_validation_failed', {
                            'endpoint': request.endpoint,
                            'missing_field': field,
                            'provided_data': list(data.keys())
                        }, 'WARNING')
                        return jsonify({'error': f'Missing required field: {field}'}), 400
            
            # Sanitize all string inputs
            sanitized_data = {}
            for key, value in data.items():
                if isinstance(value, str):
                    sanitized_data[key] = InputValidator.sanitize_string(value)
                else:
                    sanitized_data[key] = value
            
            # Store sanitized data in Flask g
            g.sanitized_data = sanitized_data
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def secure_headers(f):
    """Decorator to add security headers"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        response = f(*args, **kwargs)
        
        if hasattr(response, 'headers'):
            # Add comprehensive security headers
            response.headers['X-Content-Type-Options'] = 'nosniff'
            response.headers['X-Frame-Options'] = 'DENY'
            response.headers['X-XSS-Protection'] = '1; mode=block'
            response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
            response.headers['Content-Security-Policy'] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline'; "
                "style-src 'self' 'unsafe-inline'; "
                "img-src 'self' data: https:; "
                "font-src 'self'; "
                "connect-src 'self' ws: wss:; "
                "frame-ancestors 'none'; "
                "base-uri 'self'; "
                "form-action 'self'"
            )
            response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
            response.headers['Permissions-Policy'] = (
                'geolocation=(), microphone=(), camera=(), '
                'payment=(), usb=(), magnetometer=(), gyroscope=()'
            )
            response.headers['X-Permitted-Cross-Domain-Policies'] = 'none'
            response.headers['X-Download-Options'] = 'noopen'
        
        return response
    return decorated_function