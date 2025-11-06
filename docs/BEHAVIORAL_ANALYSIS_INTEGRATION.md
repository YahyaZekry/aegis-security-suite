# Behavioral Analysis Integration with Garuda Security Suite

## Overview

This document describes the integration of the behavioral analysis engine with the main Garuda Security Suite workflow. The behavioral analysis engine monitors system behavior, detects anomalies, and triggers automated responses based on configured thresholds.

## Integration Components

### 1. Configuration Integration

**File: `configs/security-config.conf`**

Added behavioral analysis configuration variables:
- `BEHAVIORAL_ANALYSIS_ENABLED`: Enable/disable behavioral analysis
- `BEHAVIORAL_LEARNING_PERIOD`: Days for baseline learning (default: 7)
- `BEHAVIORAL_MONITORING_INTERVAL`: Monitoring interval in seconds (default: 60)
- `BEHAVIORAL_SENSITIVITY_LEVEL`: Detection sensitivity (low/medium/high)
- `BEHAVIORAL_THREAT_SCORE_THRESHOLD`: Threat score threshold for alerts (0-100)
- `BEHAVIORAL_MAX_BASELINE_AGE`: Maximum baseline age in days (default: 30)
- `BEHAVIORAL_PROCESS_WHITELIST`: Processes to ignore
- `BEHAVIORAL_PROCESS_BLACKLIST`: Suspicious processes to flag
- `BEHAVIORAL_NETWORK_WHITELIST`: Network connections to ignore
- `BEHAVIORAL_NETWORK_BLACKLIST`: Suspicious network connections to flag

### 2. Daily Scan Integration

**File: `src/core/scripts/security-daily-scan.sh`**

Modified to include behavioral analysis in daily security scans:
- Loads behavioral analysis functions if enabled
- Initializes behavioral analysis system
- Creates baseline if not exists
- Collects system metrics, process behavior, network behavior, and file access patterns
- Detects anomalies and calculates threat scores
- Triggers incident response when threat score exceeds threshold
- Generates behavioral analysis reports

### 3. Setup Script Integration

**File: `setup-security-suite.sh`**

Enhanced setup process to include behavioral analysis:
- Added behavioral analysis configuration menu option
- Added behavioral analysis configuration function
- Creates behavioral analysis directories during setup
- Copies and initializes behavioral analysis script
- Generates systemd service and timer for continuous monitoring
- Includes behavioral analysis settings in configuration file

### 4. Incident Response Integration

**File: `src/core/scripts/incident-response.sh`**

Modified to integrate with behavioral analysis:
- Loads behavioral analysis functions if available
- Can handle behavioral anomaly incidents
- Supports automated response for behavioral threats
- Collects evidence for behavioral incidents

### 5. Continuous Monitoring Service

**File: `src/core/scripts/behavioral-monitor.sh`**

New service for continuous behavioral monitoring:
- Runs behavioral analysis in background
- Configurable monitoring duration and interval
- Collects metrics and detects anomalies
- Triggers incident response for high threat scores
- Generates monitoring logs
- Integrated with systemd timer for automatic execution

### 6. Systemd Service Integration

**Services Created:**
- `behavioral-monitor.service`: Executes behavioral monitoring script
- `behavioral-monitor.timer`: Runs monitoring every 15 minutes

**Timer Configuration:**
- Schedule: `*:*:00/15` (every 15 minutes)
- Persistent: true (runs missed intervals on restart)
- Enabled when behavioral analysis is enabled in configuration

## Workflow Integration

### Daily Security Scan Workflow

1. **Initialization Phase**
   - Load security suite configuration
   - Initialize behavioral analysis if enabled
   - Check/create behavioral baseline if needed

2. **Scanning Phase**
   - Execute traditional security scans (ClamAV, etc.)
   - Collect behavioral metrics during scan
   - Monitor system behavior in real-time

3. **Analysis Phase**
   - Detect behavioral anomalies
   - Calculate threat scores
   - Compare against configured thresholds

4. **Response Phase**
   - Trigger incident response for high threat scores
   - Generate behavioral analysis reports
   - Send notifications for detected anomalies

### Continuous Monitoring Workflow

1. **Service Start**
   - Systemd timer starts behavioral monitoring service
   - Service initializes behavioral analysis system

2. **Monitoring Loop**
   - Collect system metrics at configured intervals
   - Analyze process behavior
   - Monitor network connections
   - Track file access patterns

3. **Anomaly Detection**
   - Real-time anomaly detection
   - Threat score calculation
   - Threshold-based alerting

4. **Automated Response**
   - Incident response integration
   - Evidence collection
   - Notification system integration

## Configuration Options

### Sensitivity Levels

- **Low**: Fewer false positives, less sensitive detection
  - CPU deviation: 50%, Memory: 50%, Network: 100%, Process: 20%, File: 50%
- **Medium**: Balanced detection (default)
  - CPU deviation: 30%, Memory: 30%, Network: 50%, Process: 15%, File: 30%
- **High**: More sensitive, more false positives
  - CPU deviation: 20%, Memory: 20%, Network: 30%, Process: 10%, File: 20%

### Threat Score Thresholds

- **0-49**: Low priority monitoring
- **50-69**: Medium priority alerts
- **70-89**: High priority alerts (default threshold)
- **90-100**: Critical priority alerts

## Testing and Validation

### Integration Test Script

**File: `src/core/scripts/test-behavioral-integration.sh`**

Comprehensive test suite that validates:
- Configuration integration
- Script availability and permissions
- Database initialization
- Daily scan integration
- Incident response integration
- Monitoring service creation
- Systemd timer configuration
- Directory structure

### Test Results

All integration tests pass successfully:
- Behavioral analysis properly configured
- Scripts integrated with main security workflow
- Incident response system enhanced
- Continuous monitoring service operational
- Systemd timers configured correctly

## Usage Instructions

### Initial Setup

1. Run the setup script:
   ```bash
   ./setup-security-suite.sh
   ```

2. Configure behavioral analysis:
   - Select option 7: "Behavioral Analysis Configuration"
   - Enable behavioral analysis monitoring
   - Configure learning period, monitoring interval, sensitivity level
   - Set threat score threshold and baseline management

### Daily Operation

Behavioral analysis runs automatically with daily security scans:
- Monitors system behavior during scan
- Detects anomalies and triggers responses
- Generates reports in `configs/behavioral_analysis/`

### Continuous Monitoring

For real-time behavioral monitoring:
```bash
# Start monitoring service
systemctl --user start behavioral-monitor.timer

# Check status
systemctl --user status behavioral-monitor.service

# View logs
journalctl --user -u behavioral-monitor.service -f
```

### Manual Analysis

Run behavioral analysis manually:
```bash
# Initialize system
./src/core/scripts/behavioral-analysis.sh init

# Create baseline
./src/core/scripts/behavioral-analysis.sh baseline 7

# Monitor system
./src/core/scripts/behavioral-analysis.sh monitor 3600 60

# Generate report
./src/core/scripts/behavioral-analysis.sh report text 24
```

## File Structure

```
security-suite/
├── configs/
│   ├── security-config.conf          # Main configuration
│   └── behavioral_analysis/          # Behavioral analysis data
│       ├── behavioral_data.db        # SQLite database
│       └── behavioral_report_*.txt  # Generated reports
├── scripts/
│   ├── behavioral-analysis.sh         # Main behavioral analysis script
│   ├── behavioral-monitor.sh         # Continuous monitoring service
│   ├── security-daily-scan.sh       # Enhanced with behavioral analysis
│   ├── incident-response.sh          # Enhanced for behavioral incidents
│   └── test-behavioral-integration.sh  # Integration test
└── logs/
    └── manual/
        ├── behavioral_monitor_*.log    # Monitoring logs
        └── behavioral_integration_test_*.log  # Test logs
```

## Benefits of Integration

1. **Enhanced Security**: Behavioral analysis adds a layer of security that detects threats based on system behavior patterns, not just signatures.

2. **Proactive Detection**: Identifies potential zero-day threats and anomalous behavior that signature-based tools might miss.

3. **Automated Response**: Integrates with incident response system for automatic containment and evidence collection.

4. **Continuous Monitoring**: Provides real-time threat detection rather than periodic scans only.

5. **Comprehensive Reporting**: Generates detailed behavioral reports for security analysis and compliance.

6. **Configurable Sensitivity**: Allows tuning of detection sensitivity to balance false positives vs. missed threats.

## Troubleshooting

### Common Issues

1. **Behavioral Analysis Not Starting**
   - Check if `BEHAVIORAL_ANALYSIS_ENABLED=true` in config
   - Verify `src/core/scripts/behavioral-analysis.sh` exists and is executable
   - Check SQLite3 is installed: `which sqlite3`

2. **Database Issues**
   - Ensure proper permissions on `configs/behavioral_analysis/` directory
   - Check disk space for database growth
   - Verify database integrity: `sqlite3 behavioral_data.db ".schema"`

3. **High False Positive Rate**
   - Adjust sensitivity level in configuration
   - Review and whitelist legitimate processes/network connections
   - Update baseline with more recent normal behavior data

4. **Monitoring Timer Not Running**
   - Check systemd user services: `systemctl --user list-timers`
   - Verify timer is enabled: `systemctl --user is-enabled behavioral-monitor.timer`
   - Check service logs: `journalctl --user -u behavioral-monitor.service`

## Security Considerations

1. **Data Privacy**: Behavioral analysis collects system metrics but not user data content
2. **Performance Impact**: Monitoring interval can be adjusted to balance security vs. system performance
3. **Storage Requirements**: Behavioral database grows over time; implement cleanup policies
4. **Access Control**: Ensure proper permissions on behavioral analysis files and directories

## Future Enhancements

1. **Machine Learning**: Enhanced pattern recognition and predictive analysis
2. **Network Behavior Analysis**: Deeper inspection of network traffic patterns
3. **User Behavior Profiling**: Per-user behavioral baselines for multi-user systems
4. **Cloud Integration**: Export behavioral data to cloud SIEM systems
5. **API Integration**: REST API for behavioral analysis data and alerts

---

**Integration completed successfully on: October 31, 2025**

**Version: 1.0**