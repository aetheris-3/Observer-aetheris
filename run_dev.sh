#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Starting Observer Development Environment ===${NC}"

# Function to kill processes on exit
cleanup() {
    echo -e "\n${BLUE}Shutting down servers...${NC}"
    kill $BACKEND_PID
    kill $FRONTEND_PID
    exit
}

# Trap Ctrl+C and termination signals
trap cleanup SIGINT SIGTERM

# Load environment variables from .env file
if [ -f .env ]; then
    echo -e "${GREEN}Loading .env file...${NC}"
    set -a
    source .env
    set +a
else
    echo -e "${BLUE}No .env file found. Using defaults (create one from .env.example for GitHub OAuth).${NC}"
fi

# Set development defaults (only if not already set by .env)
export DATABASE_URL="${DATABASE_URL:-sqlite:///db.sqlite3}"
export DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-django-insecure-dev-key}"
export DEBUG="${DEBUG:-True}"
export ALLOWED_HOSTS="${ALLOWED_HOSTS:-localhost,127.0.0.1,0.0.0.0}"
export FRONTEND_URL="${FRONTEND_URL:-http://localhost:5173}"

# GitHub OAuth — MUST be set in .env file (no hardcoded secrets)
if [ -z "$GITHUB_CLIENT_ID" ]; then
    echo -e "${BLUE}⚠ GITHUB_CLIENT_ID not set — GitHub OAuth will not work. Add it to .env${NC}"
fi

echo -e "${GREEN}Starting Backend (Django)...${NC}"
source venv/bin/activate
python backend/manage.py runserver 0.0.0.0:8001 &
BACKEND_PID=$!

# Wait a moment for backend
sleep 2

# Start Frontend
echo -e "${GREEN}Starting Frontend (Vite)...${NC}"
cd frontend
npm run dev -- --host &
FRONTEND_PID=$!

echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}   Project is running!                        ${NC}"
echo -e "${BLUE}   Backend: http://localhost:8001             ${NC}"
echo -e "${BLUE}   Frontend: http://localhost:5173            ${NC}"
echo -e "${BLUE}   Press Ctrl+C to stop both servers          ${NC}"
echo -e "${BLUE}==============================================${NC}"

# Keep script running
wait
