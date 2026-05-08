# DevOps Engineering Assessment

A production-style web application deployed on a bare Ubuntu Linux server using Nginx, Gunicorn, systemd, and shell/Python scripts — no Docker, no CI/CD platforms, no automation frameworks.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Git Branching Strategy](#git-branching-strategy)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [Nginx Configuration](#nginx-configuration)
- [Cron Jobs](#cron-jobs)
- [Log Management](#log-management)
- [Design Decisions](#design-decisions)

---

## Architecture Overview
Client (Browser)
│
▼
Nginx (Port 443 - HTTPS)
│
├──► /health, /api1  ──► Gunicorn (127.0.0.1:8000) ──► FastAPI
│
├──► /api2  ──► 403 Forbidden (external access blocked)
│         └──► localhost only + rate limited
│
└──► /  ──► React Static Build (frontend/build/)
Cron (every 5 min) ──► api2_poller.py ──► /api2 (localhost) ──► logs/api2.log
Cron (nightly 2am) ──► log_archival.sh ──► compress + archive logs
---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | FastAPI (Python) |
| Frontend | React JS |
| Web Server | Nginx 1.28 |
| App Server | Gunicorn + UvicornWorker |
| Process Manager | systemd |
| Scheduler | cron |
| OS | Ubuntu 22.04 LTS (AWS EC2) |
| Version Control | Git |

---

## Project Structure
devops-assignment/
├── backend/
│   ├── app.py               # FastAPI application
│   ├── requirements.txt     # Python dependencies
│   └── venv/                # Python virtual environment
├── frontend/
│   ├── src/
│   │   └── App.js           # React app calling /api1
│   ├── public/
│   ├── build/               # Production build served by Nginx
│   └── package.json
├── nginx/
│   ├── devops-assessment.conf  # Nginx site configuration
│   └── gunicorn.service        # systemd unit file
├── scripts/
│   ├── api2_poller.py       # Cron script polling /api2
│   └── log_archival.sh      # Log compression and archival
├── logs/
│   ├── api2.log             # api2 poller logs
│   ├── cron.log             # Cron execution logs
│   ├── archival.log         # Archival script logs
│   ├── gunicorn-access.log  # Gunicorn access logs
│   └── gunicorn-error.log   # Gunicorn error logs
├── docs/
│   └── s3-archival.md       # S3 archival documentation
└── README.md
---

## Git Branching Strategy

This project follows a simplified Git Flow:
main         ← production-ready code only
└── develop      ← integration branch
├── feature/backend    ← FastAPI development
├── feature/frontend   ← React development
├── feature/nginx      ← Nginx configuration
└── feature/scripts    ← Cron and archival scripts

**Rules:**
- All development happens in `feature/*` branches
- Feature branches merge into `develop` via pull request
- `develop` merges into `main` only when fully tested
- Commit messages follow conventional commits format:
  - `feat:` new feature
  - `fix:` bug fix
  - `chore:` maintenance tasks
  - `docs:` documentation updates

---

## Prerequisites

- Ubuntu 22.04 LTS EC2 instance (t2.micro or higher)
- Security Group: ports 22, 80, 443 open
- Python 3.10+
- Node.js 20.x
- Nginx
- Git

---

## Deployment Guide

### 1. Clone the Repository

```bash
git clone https://github.com/Tushar8117/devops-assignment.git
cd devops-assignment
```

### 2. Backend Setup

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Start Gunicorn as systemd Service

```bash
# Copy service file
sudo cp nginx/gunicorn.service /etc/systemd/system/gunicorn.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# Verify
sudo systemctl status gunicorn
```

### 4. Build React Frontend

```bash
cd frontend
npm install
npm run build
```

### 5. Configure Nginx

```bash
# Generate self-signed SSL certificate
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt \
  -subj "/C=IN/ST=Maharashtra/L=NaviMumbai/O=DevOpsAssessment/CN=<YOUR_EC2_IP>"

# Copy Nginx config
sudo cp nginx/devops-assessment.conf /etc/nginx/sites-available/devops-assessment
sudo ln -s /etc/nginx/sites-available/devops-assessment /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Set Up Cron Jobs

```bash
# Make scripts executable
chmod +x scripts/api2_poller.py
chmod +x scripts/log_archival.sh

# Open crontab
sudo crontab -e
```

Poll /api2 every 5 minutes
*/5 * * * * /usr/bin/python3 /home/ubuntu/devops-assignment/scripts/api2_poller.py >> /home/ubuntu/devops-assignment/logs/cron.log 2>&1
Archive logs nightly at 2am
0 2 * * * /bin/bash /home/ubuntu/devops-assignment/scripts/log_archival.sh

### 7. Create Log Directory

```bash
mkdir -p /home/ubuntu/devops-assignment/logs
```

---

## Nginx Configuration

| Feature | Details |
|---------|---------|
| HTTP → HTTPS | 301 redirect on port 80 |
| SSL | Self-signed certificate (TLS 1.2/1.3) |
| Reverse Proxy | `/health`, `/api1` → Gunicorn:8000 |
| Static Serving | React build with 30-day cache headers |
| `/api2` Access | Blocked externally, localhost only |
| Rate Limiting | 5 requests/min on `/api2` via `limit_req` |

---

## Cron Jobs

| Script | Schedule | Purpose |
|--------|----------|---------|
| `api2_poller.py` | Every 5 minutes | Polls `/api2`, writes timestamped logs |
| `log_archival.sh` | Daily at 2am | Compresses and archives logs older than 7 days |

---

## Log Management

| Log File | Source |
|----------|--------|
| `logs/api2.log` | api2 poller responses |
| `logs/cron.log` | Cron execution output |
| `logs/archival.log` | Archival script activity |
| `logs/gunicorn-access.log` | Gunicorn access log |
| `logs/gunicorn-error.log` | Gunicorn error log |

**Log Rotation:** `api2_poller.py` rotates `api2.log` when it exceeds 1MB, keeping last 5 files.

**Log Archival:** `log_archival.sh` runs nightly, compresses logs older than 7 days using `tar.gz`, and moves them to `/mnt/log-archive` (EBS) or fallback `/home/ubuntu/devops-assignment/log-archive`.

---

## Design Decisions

### Why EBS instead of S3 for log archival?
AWS S3 access is restricted in the current network environment. Logs are archived to a local EBS-backed directory. Full S3 implementation is documented in `docs/s3-archival.md` for environments where S3 access is available.

### Why Gunicorn with UvicornWorker?
FastAPI is an ASGI framework. Gunicorn alone is a WSGI server. Using `uvicorn.workers.UvicornWorker` gives us Gunicorn's process management with Uvicorn's ASGI performance.

### Why self-signed SSL?
This is an internal assessment environment. Self-signed certificates provide encrypted transport without requiring a domain name. In production, Let's Encrypt (Certbot) would be used.

### Why no Docker/CI-CD?
Per assessment constraints — all deployment, configuration, and automation uses only Nginx, shell scripts, Python, cron, systemd, and Git.
