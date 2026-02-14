#!/bin/bash
# Helper script to run docker-compose with rootless podman configuration

# Set environment variables for rootless execution
export DOCKER_HOST="unix:///run/user/1000/podman/podman.sock"
export DATABASE_URL="sqlite:///data/db.sqlite3" # Use persistent volume path
export CORS_ALLOWED_ORIGINS="http://localhost:5173,http://localhost:3000,http://localhost:8080"

# Execute docker-compose with arguments
docker-compose "$@"
