#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

echo "🔍 Checking and exporting environment variables..."

# Export the environment variables explicitly
export DOMAIN=${DOMAIN:?"DOMAIN is required"}
export EMAIL=${EMAIL:?"EMAIL is required"}
export IMAGE_PATH=${IMAGE_PATH:?"IMAGE_PATH is required"}
export PROTOCOL=${PROTOCOL:-https}

# MongoDB Configuration
export MONGO_USERNAME=${MONGO_USERNAME:-admin}
export MONGO_PASSWORD=${MONGO_PASSWORD:-securepassword}
export MONGO_DATABASE=${MONGO_DATABASE:-app}

# Application Configuration
export NODE_ENV=${NODE_ENV:-production}
export PORT=${PORT:-8080}
export JWT_SECRET=${JWT_SECRET:?"JWT_SECRET is required"}
export JWT_EXPIRES_IN=${JWT_EXPIRES_IN:-24h}

# SMTP Configuration
export SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}
export SMTP_PORT=${SMTP_PORT:-587}
export SMTP_USER=${SMTP_USER:?"SMTP_USER is required"}
export SMTP_PASS=${SMTP_PASS:?"SMTP_PASS is required"}
export SMTP_FROM=${SMTP_FROM:?"SMTP_FROM is required"}

# Discord Configuration
export DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL:-""}

# API URLs (using Traefik routing)
export API_URL=${API_URL:-"${PROTOCOL}://api.${DOMAIN}"}  # For external access
export FRONTEND_URL=${FRONTEND_URL:-"${PROTOCOL}://${DOMAIN}"}

# Frontend Configuration
export APP_NAME=${APP_NAME:-"Task Manager"}

echo "✅ Required variables:"
echo "DOMAIN: $DOMAIN"
echo "EMAIL: $EMAIL"
echo "IMAGE_PATH: $IMAGE_PATH"
echo "JWT_SECRET: [secured]"

echo "✅ Optional variables (with defaults):"
echo "PROTOCOL: $PROTOCOL"
echo "MONGO_USERNAME: $MONGO_USERNAME"
echo "MONGO_DATABASE: $MONGO_DATABASE"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"
echo "JWT_EXPIRES_IN: $JWT_EXPIRES_IN"
echo "API_URL: $API_URL"
echo "FRONTEND_URL: $FRONTEND_URL"
echo "APP_NAME: $APP_NAME"

echo ""
echo "📂 Setting up directories and files..."

# Create directories if they don't exist
mkdir -p data/traefik
mkdir -p data/mongodb
mkdir -p data/traefik/acme

# Initialize acme.json if it doesn't exist
if [ ! -f "data/traefik/acme/acme.json" ]; then
  echo "🔒 Creating acme.json for SSL certificates..."
  touch data/traefik/acme/acme.json
  chmod 600 data/traefik/acme/acme.json
fi

# Check file permissions
echo ""
echo "🔍 Checking file permissions..."
if [ "$(stat -f "%p" data/traefik/acme/acme.json)" = "100600" ]; then
  echo "✅ acme.json has correct permissions (600)"
else
  echo "⚠️  Fixing acme.json permissions..."
  chmod 600 data/traefik/acme/acme.json
fi

# Verify all required directories exist
if [ -d "data/traefik" ] && [ -d "data/mongodb" ]; then
  echo "✅ All required directories exist"
else
  echo "❌ Some required directories are missing"
  exit 1
fi
