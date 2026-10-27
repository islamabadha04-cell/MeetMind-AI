#!/bin/bash
# ==============================================================================
# MeetMind AI — Production Server 1-Click Deployment Script
# Suitable for Ubuntu 22.04 / 24.04 LTS (AWS EC2, DigitalOcean, Hetzner, etc.)
# ==============================================================================

set -e

echo "🚀 Starting MeetMind AI Production Server Deployment..."

# 1. Update OS packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git nginx python3-pip python3-venv certbot python3-certbot-nginx

# 2. Setup Project Directory
APP_DIR="/var/www/meetmind"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# 3. Setup Python Backend Virtual Environment
cd $APP_DIR/backend
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 4. Setup Systemd Service for FastAPI (Gunicorn / Uvicorn workers)
cat <<EOF | sudo tee /etc/systemd/system/meetmind-backend.service
[Unit]
Description=MeetMind AI FastAPI Backend Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$APP_DIR/backend
ExecStart=$APP_DIR/backend/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 4
Restart=always
RestartSec=5
EnvironmentFile=$APP_DIR/backend/.env

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable meetmind-backend
sudo systemctl restart meetmind-backend

# 5. Setup Nginx Reverse Proxy with HTTPS & Static Web Caching
cat <<EOF | sudo tee /etc/nginx/sites-available/meetmind
server {
    listen 80;
    server_name your-domain.com;

    # Static Web App & PWA
    root $APP_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API Proxy to FastAPI
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/meetmind /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

echo "✅ Deployment Complete! Run: sudo certbot --nginx -d your-domain.com for free SSL."
