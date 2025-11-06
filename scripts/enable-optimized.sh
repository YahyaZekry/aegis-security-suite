#!/bin/bash
# Enable Optimized Components Script

SCRIPT_DIR="$(dirname "$0")"
SECURITY_SUITE_HOME="$(dirname "$SCRIPT_DIR")"

echo "Enabling optimized Garuda Security Suite components..."

# Stop existing services
systemctl --user stop garuda-behavioral-monitor 2>/dev/null || true
systemctl --user stop garuda-dashboard 2>/dev/null || true

# Enable optimized behavioral monitoring
ln -sf "behavioral-monitor-optimized.sh" "$SCRIPT_DIR/behavioral-monitor-optimized"
ln -sf "behavioral-analysis-optimized.sh" "$SCRIPT_DIR/behavioral-analysis-optimized"

# Enable optimized threat intelligence
ln -sf "threat-intelligence-optimized.sh" "$SCRIPT_DIR/threat-intelligence.sh"

# Enable optimized web dashboard
ln -sf "app-optimized.py" "$SCRIPT_DIR/../web-dashboard/app-optimized"

# Start optimized services
systemctl --user daemon-reload
systemctl --user enable memory-monitor.service
systemctl --user start memory-monitor.service

echo "Optimized components enabled successfully"
echo "Run 'systemctl --user status' to check service status"
