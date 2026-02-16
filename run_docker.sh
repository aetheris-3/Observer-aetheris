#!/bin/bash
# Helper script to run docker-compose with standard Docker configuration

# Set environment variables
# Removed DOCKER_HOST override to use default Docker socket
export DATABASE_URL="sqlite:///data/db.sqlite3" # Use persistent volume path
export CORS_ALLOWED_ORIGINS="http://localhost:5173,http://localhost:3000,http://localhost:8080"

# Execute docker-compose with arguments
docker-compose "$@"
