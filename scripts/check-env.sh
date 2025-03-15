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

# API URLs
export API_URL=${API_URL:-"${PROTOCOL}://api.${DOMAIN}"}
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
echo "📂 Checking directories..."
if [ -d "data/traefik" ]; then
  echo "✅ data/traefik directory exists"
else
  echo "❌ data/traefik directory is missing"
fi

if [ -d "data/mongodb" ]; then
  echo "✅ data/mongodb directory exists"
else
  echo "❌ data/mongodb directory is missing"
fi

echo ""
echo "📄 Checking Traefik configuration..."
if [ -f "data/traefik/traefik.yml" ]; then
  echo "✅ Traefik configuration file exists"
else
  echo "❌ Traefik configuration file is missing"
fi
