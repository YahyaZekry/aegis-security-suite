# Aegis Security Suite

A comprehensive Linux security monitoring and incident response system designed for enterprise environments.

## Overview

Aegis Security Suite provides real-time monitoring, threat detection, behavioral analysis, and incident response capabilities for Linux systems. It combines multiple security tools into a unified platform with both CLI and web-based interfaces.

## Features

- **Real-time Behavioral Monitoring**: Detects anomalous system behavior and potential security threats
- **Threat Intelligence Integration**: Automated threat detection with IOC database
- **Incident Response**: Automated and manual incident response workflows
- **Web Dashboard**: Comprehensive web-based monitoring and management interface
- **Security Scanning**: Integrated ClamAV and RKhunter scanning
- **Comprehensive Logging**: Detailed audit trails and security event logging

## Project Structure

```
aegis-security-suite/
├── README.md                    # This file
├── setup-aegis.sh                # Main installation script
├── uninstall-aegis.sh            # Uninstallation script
│
├── scripts/                     # Core security scripts
│   ├── behavioral-analysis.sh    # Behavioral analysis engine
│   ├── incident-response.sh      # Incident response automation
│   ├── security-daily-scan.sh    # Daily security scanning
│   ├── threat-intelligence-v2.sh # Threat intelligence module
│   ├── scanners/                 # Security scanner modules
│   │   ├── clamav-scanner.sh     # ClamAV integration
│   │   └── rkhunter-scanner.sh   # RKhunter integration
│   └── common-functions.sh       # Shared utility functions
│
├── web-dashboard/               # Web-based dashboard
│   ├── app.py                   # Flask application
│   ├── auth.py                  # Authentication module
│   ├── api/                     # REST API endpoints
│   │   ├── behavioral.py        # Behavioral analysis API
│   │   ├── incidents.py         # Incident management API
│   │   ├── system.py            # System monitoring API
│   │   └── threats.py           # Threat intelligence API
│   ├── static/                  # Static assets (CSS, JS)
│   ├── templates/               # HTML templates
│   └── config/                  # Dashboard configuration
│
├── configs/                     # Configuration files
│   ├── security-config.conf     # Main security configuration
│   ├── behavioral_analysis/     # Behavioral analysis configs
│   ├── incident_response/       # Incident response configs
│   ├── threat_intelligence/     # Threat intelligence configs
│   └── web-dashboard/           # Dashboard-specific configs
│
├── docs/                        # Documentation
│   ├── API.md                   # API documentation
│   ├── INSTALLATION.md          # Installation guide
│   ├── USER_GUIDE.md            # User guide
│   ├── DASHBOARD_GUIDE.md       # Dashboard guide
│   ├── SECURITY_COMPONENTS.md   # Security components overview
│   ├── QUICK_START.md           # Quick start guide
│   └── TROUBLESHOOTING.md       # Troubleshooting guide
│
├── tests/                       # Test framework
│   ├── test-suite.bats           # Main test suite
│   ├── security-tests.bats       # Security-specific tests
│   ├── integration-tests.bats    # Integration tests
│   ├── performance-tests.bats    # Performance tests
│   ├── test-suite-comprehensive.sh  # Comprehensive test suite
│   ├── comprehensive_integration_test.py  # Integration test
│   └── integration_test_suite.py       # Integration test suite
│
├── component-tests/             # Component-specific tests
├── integration-tests/           # Integration test scripts
├── end-to-end-tests/            # End-to-end test scenarios
├── performance-tests/           # Performance testing tools
└── security-tests/              # Security-focused tests
```

## Quick Start

### Prerequisites

- Linux system (Ubuntu 18.04+ or CentOS 7+)
- Root or sudo privileges
- Python 3.6+ (for web dashboard)
- ClamAV and RKhunter (optional but recommended)

### Installation

The Aegis Security Suite is now **user-agnostic** and can be installed by any user without modifications.

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/aegis-security-suite.git
   cd aegis-security-suite
   ```

2. Run the installation script:
   ```bash
   ./setup-aegis.sh
   ```
   
   **Note**: The script automatically detects the current user and configures all paths accordingly. No hardcoded user paths are used.

3. Start the web dashboard (optional):
   ```bash
   cd web-dashboard
   python3 app.py
   ```

#### User-Agnostic Features

- **Dynamic User Detection**: Automatically detects the current user running the installation
- **Flexible Path Resolution**: Supports multiple installation locations (`~/security-suite`, `/opt/aegis-security-suite`, etc.)
- **Service Template Processing**: All systemd services are dynamically configured for the detected user
- **No Hardcoded Paths**: All references use dynamic variables instead of hardcoded user names

### Basic Usage

- **CLI Interface**: Use scripts in the `scripts/` directory
- **Web Dashboard**: Access at `http://localhost:5000`
- **Configuration**: Edit `configs/security-config.conf`
- **Service Management**: Use `./scripts/start-aegis.sh` to manage all services

#### User Environment Variables

The installation automatically sets up the following environment variables:

- `CURRENT_USER`: The detected current user
- `CURRENT_HOME`: The home directory of the current user
- `SECURITY_SUITE_HOME`: The installation directory (dynamically detected)
- `SCRIPTS_DIR`: Path to scripts directory
- `LOGS_DIR`: Path to logs directory
- `CONFIGS_DIR`: Path to configs directory
- `BACKUPS_DIR`: Path to backups directory

## Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [User Guide](docs/USER_GUIDE.md)
- [API Documentation](docs/API.md)
- [Dashboard Guide](docs/DASHBOARD_GUIDE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Testing

Run the comprehensive test suite:
```bash
./tests/test-suite-comprehensive.sh
```

Or run specific test categories:
```bash
# Component tests
./component-tests/test-*.sh

# Integration tests
./tests/test-suite-comprehensive.sh
./tests/integration_test_suite.py
./integration-tests/test-*.sh

# Security tests
./security-tests/test-*.sh
```

## Security Components

### Behavioral Analysis
- Monitors system processes, network connections, and file system changes
- Detects anomalous behavior patterns
- Generates alerts for suspicious activities

### Threat Intelligence
- Integrates with threat feeds and IOC databases
- Automated malware detection
- Real-time threat scoring

### Incident Response
- Automated containment and eradication
- Evidence collection and preservation
- Detailed incident reporting

### Security Scanning
- ClamAV malware scanning
- RKhunter rootkit detection
- Custom vulnerability assessment

## Configuration

Main configuration is handled through `configs/security-config.conf`. Key sections include:

- Behavioral analysis settings
- Threat intelligence sources
- Incident response procedures
- Dashboard configuration
- Logging preferences

## Support

For issues, questions, or contributions:
- GitHub Issues: [Create an issue](https://github.com/your-org/aegis-security-suite/issues)
- Documentation: [docs/](docs/)
- Community: [Discussions](https://github.com/your-org/aegis-security-suite/discussions)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a history of changes and updates.
