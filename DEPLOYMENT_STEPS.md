# 🚀 Observer - VPS Deployment Guide

**Status:** ✅ Application is production-ready  
**Last Updated:** 2026-02-16 13:32 IST

---

## 📋 Pre-Deployment Checklist

Before deploying to VPS, ensure you have:

- [ ] VPS with Ubuntu 22.04+ (minimum 2GB RAM, 2 CPU cores recommended)
- [ ] Domain name (optional but recommended for SSL)
- [ ] GitHub repository access
- [ ] Strong passwords ready for database and Django secret key

---

## 🔧 Manual Configuration Tasks

### 1. Generate Django Secret Key

Run this command to generate a secure secret key:

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

**Save this key** - you'll need it for the `.env` file.

---

### 2. Prepare Environment Variables

Create a `.env` file with these variables (replace placeholders with actual values):

```bash
# Django Settings
DJANGO_SECRET_KEY=<your-generated-secret-key>
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com,your.vps.ip.address

# Database (PostgreSQL)
DATABASE_URL=postgresql://observer_user:your-strong-password@localhost:5432/observer_db

# Redis
REDIS_URL=redis://localhost:6379

# CORS & Frontend
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
FRONTEND_URL=https://yourdomain.com

# GitHub OAuth (Optional - for student GitHub integration)
GITHUB_CLIENT_ID=your-github-oauth-client-id
GITHUB_CLIENT_SECRET=your-github-oauth-client-secret
GITHUB_REDIRECT_URI=https://yourdomain.com/auth/github/callback

# GitHub Admin (Optional - for archiver feature)
GITHUB_ADMIN_USERNAME=your-github-username
GITHUB_ADMIN_TOKEN=your-github-personal-access-token
```

---

### 3. Configure GitHub OAuth (Optional)

If you want to enable GitHub integration for students:

1. Go to https://github.com/settings/developers
2. Click "New OAuth App"
3. Fill in:
   - **Application name:** Observer Code Platform
   - **Homepage URL:** `https://yourdomain.com`
   - **Authorization callback URL:** `https://yourdomain.com/auth/github/callback`
4. Click "Register application"
5. Copy the **Client ID** and **Client Secret** to your `.env` file

---

### 4. Create GitHub Personal Access Token (Optional)

For the archiver feature to save student code to GitHub:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name: "Observer Archiver"
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
5. Click "Generate token"
6. Copy the token to your `.env` file as `GITHUB_ADMIN_TOKEN`

---

## 🖥️ VPS Deployment Steps

### Step 1: Provision VPS

**Recommended Specs:**
- **OS:** Ubuntu 22.04 LTS
- **RAM:** 2GB minimum (4GB recommended)
- **CPU:** 2 cores
- **Storage:** 20GB minimum
- **Providers:** DigitalOcean, Linode, Vultr, AWS EC2, etc.

---

### Step 2: Initial Server Setup

SSH into your VPS and run:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install system dependencies
sudo apt install -y python3 python3-pip python3-venv nodejs npm \
    postgresql postgresql-contrib redis-server nginx certbot \
    python3-certbot-nginx gcc g++ default-jdk git curl

# Verify installations
python3 --version  # Should be 3.10+
node --version     # Should be 18+
psql --version     # Should be 14+
redis-cli --version
```

---

### Step 3: Create Application User

```bash
# Create user
sudo useradd -m -s /bin/bash observer
sudo usermod -aG sudo observer

# Switch to observer user
sudo su - observer
```

---

### Step 4: Clone Repository

```bash
# Clone your repository
cd /home/observer
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git app
cd app

# Verify structure
ls -la
# Should see: backend/, frontend/, CHECKLIST.md, etc.
```

---

### Step 5: Set Up PostgreSQL Database

```bash
# Exit observer user temporarily
exit

# Create database and user
sudo -u postgres createuser observer_user
sudo -u postgres createdb observer_db -O observer_user
sudo -u postgres psql -c "ALTER USER observer_user PASSWORD 'YOUR-STRONG-PASSWORD';"

# Verify connection
sudo -u postgres psql -c "\l" | grep observer_db

# Switch back to observer user
sudo su - observer
```

---

### Step 6: Set Up Redis

```bash
# Exit observer user
exit

# Enable and start Redis
sudo systemctl enable redis-server
sudo systemctl start redis-server
sudo systemctl status redis-server

# Test Redis
redis-cli ping  # Should return "PONG"

# Switch back to observer user
sudo su - observer
```

---

### Step 7: Configure Backend

```bash
cd /home/observer/app/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file (use the template from Step 2 above)
nano .env
# Paste your environment variables and save (Ctrl+X, Y, Enter)

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
# Follow prompts to create admin account

# Collect static files
python manage.py collectstatic --noinput

# Test server (optional)
python manage.py runserver 0.0.0.0:8000
# Press Ctrl+C to stop
```

---

### Step 8: Configure Frontend

```bash
cd /home/observer/app/frontend

# Install dependencies
npm install

# Update .env.production with your domain
nano .env.production
# Update VITE_API_URL to your domain or IP
# Example: VITE_API_URL=https://yourdomain.com/api

# Build for production
npm run build

# Verify build
ls -la dist/
# Should see index.html, assets/, etc.
```

---

### Step 9: Set Up Systemd Services

#### Backend Service (Daphne for ASGI)

```bash
# Exit observer user
exit

# Create systemd service file
sudo nano /etc/systemd/system/observer-backend.service
```

Paste this content:

```ini
[Unit]
Description=Observer Backend (Daphne ASGI Server)
After=network.target postgresql.service redis-server.service

[Service]
Type=notify
User=observer
Group=observer
WorkingDirectory=/home/observer/app/backend
Environment="PATH=/home/observer/app/backend/venv/bin"
ExecStart=/home/observer/app/backend/venv/bin/daphne -b 0.0.0.0 -p 8001 config.asgi:application
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Save and enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable observer-backend
sudo systemctl start observer-backend
sudo systemctl status observer-backend
```

---

### Step 10: Configure Nginx Reverse Proxy

```bash
sudo nano /etc/nginx/sites-available/observer
```

Paste this configuration (replace `yourdomain.com` with your actual domain):

```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Certbot will add SSL configuration here
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    # SSL certificates (will be added by Certbot)
    # ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Frontend (React build)
    location / {
        root /home/observer/app/frontend/dist;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeouts for long-running requests
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Django Admin
    location /admin/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket connections
    location /ws/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket timeouts
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Static files (Django)
    location /static/ {
        alias /home/observer/app/backend/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Media files (if any)
    location /media/ {
        alias /home/observer/app/backend/media/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
```

Enable the site:

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/observer /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

---

### Step 11: Set Up SSL with Let's Encrypt

```bash
# Install Certbot (if not already installed)
sudo apt install certbot python3-certbot-nginx -y

# Obtain SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Choose whether to redirect HTTP to HTTPS (recommended: Yes)

# Verify auto-renewal
sudo certbot renew --dry-run

# Certificate will auto-renew via cron
```

---

### Step 12: Configure Firewall

```bash
# Enable UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Verify
sudo ufw status
```

---

### Step 13: Final Verification

```bash
# Check all services are running
sudo systemctl status observer-backend
sudo systemctl status nginx
sudo systemctl status postgresql
sudo systemctl status redis-server

# Check logs if any issues
sudo journalctl -u observer-backend -n 50 --no-pager
sudo tail -f /var/log/nginx/error.log

# Test the application
curl https://yourdomain.com
curl https://yourdomain.com/api/health/  # If you have a health endpoint
```

---

## 🔍 Post-Deployment Checks

### 1. Test Frontend
- Visit `https://yourdomain.com`
- Should see the login/register page
- Check browser console for errors (F12)

### 2. Test Backend API
- Visit `https://yourdomain.com/admin`
- Login with superuser credentials
- Verify admin panel works

### 3. Test WebSocket
- Create a session as teacher
- Join as student
- Verify real-time code synchronization works

### 4. Test Code Execution
- Run Python code
- Run JavaScript code
- Verify output appears correctly
- Check interactive console works

---

## 🛠️ Maintenance Commands

### Update Application

```bash
# Switch to observer user
sudo su - observer
cd /home/observer/app

# Pull latest changes
git pull origin main

# Update backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput

# Update frontend
cd ../frontend
npm install
npm run build

# Restart services
exit
sudo systemctl restart observer-backend
sudo systemctl reload nginx
```

### View Logs

```bash
# Backend logs
sudo journalctl -u observer-backend -f

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

### Database Backup

```bash
# Create backup
sudo -u postgres pg_dump observer_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
sudo -u postgres psql observer_db < backup_20260216_133000.sql
```

---

## 🚨 Troubleshooting

### Backend won't start
```bash
# Check logs
sudo journalctl -u observer-backend -n 100 --no-pager

# Common issues:
# - Missing environment variables in .env
# - Database connection failed (check DATABASE_URL)
# - Redis not running (sudo systemctl start redis-server)
# - Port 8001 already in use (sudo lsof -i :8001)
```

### WebSocket not connecting
```bash
# Check Nginx WebSocket configuration
sudo nginx -t

# Verify backend is listening
sudo netstat -tlnp | grep 8001

# Check browser console for WebSocket errors
# Common fix: Ensure CORS_ALLOWED_ORIGINS includes your domain
```

### Static files not loading
```bash
# Recollect static files
cd /home/observer/app/backend
source venv/bin/activate
python manage.py collectstatic --noinput

# Check Nginx static file permissions
sudo chmod -R 755 /home/observer/app/backend/staticfiles/
```

---

## 📊 Performance Optimization (Optional)

### 1. Enable Gzip Compression in Nginx

Add to `/etc/nginx/nginx.conf` in the `http` block:

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
```

### 2. Set Up PostgreSQL Connection Pooling

Install pgBouncer:

```bash
sudo apt install pgbouncer -y
```

### 3. Monitor with Uptime Kuma or Similar

```bash
# Install Uptime Kuma (optional monitoring)
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1
```

---

## ✅ Deployment Complete!

Your Observer application should now be live at `https://yourdomain.com`

**Next Steps:**
1. Create teacher and student accounts
2. Test all features thoroughly
3. Set up monitoring and backups
4. Share the platform with your users!

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review logs: `sudo journalctl -u observer-backend -n 100`
3. Verify all environment variables are set correctly
4. Ensure all services are running: `sudo systemctl status observer-backend nginx postgresql redis-server`

**Good luck with your deployment! 🚀**
