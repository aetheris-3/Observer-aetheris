#!/bin/bash

# ==========================================
# Observer Backend Startup Script
# ==========================================

# ------------------------------------------
# 1. ADMIN CONFIGURATION
# ------------------------------------------
# All configuration is loaded from ../.env file.
# See .env.example for required variables.
#
# GitHub Admin credentials (for session archiving):
#   GITHUB_ADMIN_USERNAME — Your GitHub username
#   GITHUB_ADMIN_TOKEN    — Personal Access Token with 'repo' scope
#     HOW TO GET TOKEN:
#     1. Go to GitHub Settings -> Developer Settings -> Personal access tokens -> Tokens (classic)
#     2. Generate new token
#     3. Select 'repo' scope (Full control of private repositories)
#     4. Add it to your .env file

# ------------------------------------------
# 2. START SERVER
# ------------------------------------------
echo "Starting Observer Backend..."



# Run database migrations just in case
# Ensure we are in the backend directory
cd "$(dirname "$0")"

# Start Database (Docker directly)
echo "Starting Database..."

# Load environment variables from .env if present
if [ -f ../.env ]; then
    echo "Loading .env file..."
    set -a
    source ../.env
    set +a
else
    echo "⚠ No .env file found. Copy .env.example to .env and fill in your values."
fi

# Validate admin config
if [ -n "$GITHUB_ADMIN_USERNAME" ]; then
    echo "Admin User: $GITHUB_ADMIN_USERNAME"
else
    echo "⚠ GITHUB_ADMIN_USERNAME not set — session archiving will be disabled."
fi

DB_USER=${POSTGRES_USER:-consoleshare_user}
DB_PASS=${POSTGRES_PASSWORD:-consoleshare_password}
DB_NAME=${POSTGRES_DB:-consoleshare}

# Remove existing container to ensure config update (e.g. auth method)
docker rm -f consoleshare-db >/dev/null 2>&1 || true

# Run new container
docker run -d \
    --name consoleshare-db \
    --restart unless-stopped \
    -p 127.0.0.1:5434:5432 \
    -e POSTGRES_USER=$DB_USER \
    -e POSTGRES_PASSWORD=$DB_PASS \
    -e POSTGRES_DB=$DB_NAME \
    -e POSTGRES_HOST_AUTH_METHOD=trust \
    -v postgres_data:/var/lib/postgresql/data \
    postgres:15-alpine

# Use credentials from .env but force localhost:5434 for local Docker DB
export DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5434/${DB_NAME}"

# Build Frontend
echo "Building Frontend..."
cd ../frontend
npm install
npm run build
cd ../backend

# Run database migrations just in case
source venv/bin/activate
python3 manage.py migrate
python3 manage.py collectstatic --noinput

# Start the server with Daphne (Production-ready)
echo "Starting Daphne Server on 0.0.0.0:8000..."
daphne -b 0.0.0.0 -p 8000 config.asgi:application
