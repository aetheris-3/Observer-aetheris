# 🚀 Quick Deployment Reference

**For:** Observer VPS Deployment  
**Status:** Production Ready ✅

---

## 📋 Pre-Flight Checklist

Before you start, have these ready:

- [ ] VPS with Ubuntu 22.04+ (2GB RAM minimum)
- [ ] Domain name (or use IP address)
- [ ] SSH access to VPS
- [ ] GitHub repository URL
- [ ] Strong password for PostgreSQL
- [ ] Django secret key (generate with command below)

---

## ⚡ Quick Start Commands

### 1. Generate Secret Key (Run Locally)
```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```
**Save this output!**

---

### 2. SSH into VPS
```bash
ssh root@your-vps-ip
```

---

### 3. One-Line System Setup
```bash
sudo apt update && sudo apt upgrade -y && \
sudo apt install -y python3 python3-pip python3-venv nodejs npm \
postgresql postgresql-contrib redis-server nginx certbot \
python3-certbot-nginx gcc g++ default-jdk git curl
```

---

### 4. Create User & Clone
```bash
sudo useradd -m -s /bin/bash observer && \
sudo su - observer && \
git clone YOUR-REPO-URL app && \
cd app
```

---

### 5. Database Setup
```bash
# Exit observer user first
exit

# Create database
sudo -u postgres createuser observer_user
sudo -u postgres createdb observer_db -O observer_user
sudo -u postgres psql -c "ALTER USER observer_user PASSWORD 'YOUR-PASSWORD';"

# Back to observer
sudo su - observer
```

---

### 6. Backend Setup
```bash
cd ~/app/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create .env file (see template below)
nano .env
```

**Minimal .env Template:**
```bash
DJANGO_SECRET_KEY=your-generated-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,your.ip.address
DATABASE_URL=postgresql://observer_user:YOUR-PASSWORD@localhost:5432/observer_db
REDIS_URL=redis://localhost:6379
CORS_ALLOWED_ORIGINS=https://yourdomain.com
FRONTEND_URL=https://yourdomain.com
```

```bash
# Run migrations
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic --noinput
```

---

### 7. Frontend Setup
```bash
cd ~/app/frontend
npm install

# Update .env.production
nano .env.production
# Set: VITE_API_URL=https://yourdomain.com/api

npm run build
```

---

### 8. Systemd Service
```bash
exit  # Exit observer user

sudo nano /etc/systemd/system/observer-backend.service
```

**Paste:**
```ini
[Unit]
Description=Observer Backend
After=network.target postgresql.service redis-server.service

[Service]
Type=notify
User=observer
Group=observer
WorkingDirectory=/home/observer/app/backend
Environment="PATH=/home/observer/app/backend/venv/bin"
ExecStart=/home/observer/app/backend/venv/bin/daphne -b 0.0.0.0 -p 8001 config.asgi:application
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable observer-backend
sudo systemctl start observer-backend
```

---

### 9. Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/observer
```

**Minimal Config (replace yourdomain.com):**
```nginx
server {
    listen 80;
    server_name yourdomain.com;

    location / {
        root /home/observer/app/frontend/dist;
        try_files $uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /admin/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /static/ {
        alias /home/observer/app/backend/staticfiles/;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/observer /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

---

### 10. SSL Certificate
```bash
sudo certbot --nginx -d yourdomain.com
# Follow prompts, choose redirect HTTP to HTTPS
```

---

### 11. Firewall
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

---

## ✅ Verification

```bash
# Check services
sudo systemctl status observer-backend
sudo systemctl status nginx
sudo systemctl status postgresql
sudo systemctl status redis-server

# Test site
curl https://yourdomain.com
```

---

## 🔧 Common Issues

### Backend won't start
```bash
sudo journalctl -u observer-backend -n 50
# Check .env file, database connection
```

### WebSocket not working
```bash
# Ensure Nginx has WebSocket config
# Check CORS_ALLOWED_ORIGINS in .env
```

### Static files 404
```bash
cd /home/observer/app/backend
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart observer-backend
```

---

## 📚 Full Documentation

- **Complete Guide:** `DEPLOYMENT_STEPS.md`
- **Production Summary:** `PRODUCTION_READY.md`
- **Checklist:** `CHECKLIST.md`

---

## 🎉 Done!

Visit: `https://yourdomain.com`

**Default Admin:** `/admin`  
**API Docs:** `/api/`

---

**Need help?** Check `DEPLOYMENT_STEPS.md` for detailed troubleshooting.
