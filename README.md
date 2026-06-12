# 🛡️ Aegis Security Suite

> Linux security monitoring & incident response — real-time behavioral analysis, threat intelligence, automated response, and a web dashboard.

## 🚀 Quick Start

```bash
git clone https://github.com/YahyaZekry/aegis-security-suite.git
cd aegis-security-suite
sudo ./setup-aegis.sh
```

Start the dashboard: `python3 web-dashboard/app.py` → **http://localhost:5000**

Manage services: `./scripts/start-aegis.sh`

## 📁 Structure

```
aegis-security-suite/
├── setup-aegis.sh               # 🔧 Installer
├── uninstall-aegis.sh           # 🗑️ Uninstaller
├── scripts/                     # ⚙️ Core security modules
│   ├── start-aegis.sh           # 🎛️ Service manager
│   ├── common-functions.sh      # 📚 Shared lib
│   ├── behavioral-analysis-optimized.sh  # 🧠 Behavioral engine
│   ├── incident-response.sh     # 🚨 Incident handler
│   ├── threat-intelligence-optimized.sh  # 🌐 Threat intel
│   ├── security-daily-scan.sh   # 📅 Daily scans
│   ├── scanners/                # 🦠 ClamAV, RKhunter wrappers
│   └── *.service *.timer        # ⏱️ systemd units
├── web-dashboard/               # 💻 Flask app
│   ├── app.py
│   ├── auth.py
│   └── api/                     # 📡 behavioral, incidents, system, threats
├── configs/                     # ⚡ security-config.conf + DBs
├── docs/                        # 📖 API, install, user guide, etc.
├── tests/                       # ✅ bats + Python test suites
├── component-tests/
├── integration-tests/
├── end-to-end-tests/
├── performance-tests/
└── security-tests/
```

## 🧪 Tests

```bash
# Full suite
./tests/test-suite-comprehensive.sh

# Individual suites (requires bats)
bats tests/test-suite.bats
bats tests/security-tests.bats
```

## ✨ Features

- 🧠 **Behavioral Monitoring** — process, network, filesystem anomaly detection via systemd service
- 🌐 **Threat Intelligence** — IOC database ingestion, scheduled feed updates, threat scoring
- 🚨 **Incident Response** — automated quarantine/block/isolate per severity level, evidence collection
- 💻 **Web Dashboard** — Flask + SocketIO, MFA, REST API, real-time monitoring
- 🦠 **Security Scanning** — ClamAV, RKhunter, Chkrootkit, Lynis wrappers with unified reporting
- ⏱️ **System Services** — systemd units with resource limits, dynamic path resolution, sudo hardening

## ⚙️ Config

Edit `configs/security-config.conf` — scanning schedules, directories, notification preferences, security tool selection.

## 📡 API

REST endpoints at `/api/auth/`, `/api/behavioral/`, `/api/incidents/`, `/api/system/`, `/api/threats/`. See `docs/API.md`.

## 📄 License

MIT
