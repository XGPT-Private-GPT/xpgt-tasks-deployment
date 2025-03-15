#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🚀 Starting deployment..."

# Create required directories
echo "📁 Creating necessary directories..."
mkdir -p data/traefik/acme
mkdir -p data/mongodb

# Initialize acme.json if it doesn't exist
if [ ! -f "data/traefik/acme/acme.json" ]; then
  echo "🔒 Creating acme.json for SSL certificates..."
  install -m 600 /dev/null data/traefik/acme/acme.json
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
  echo "❌ No .env file found. Please copy .env.template to .env and configure it."
  exit 1
fi

source .env

# Validate PROTOCOL setting
if [ "$PROTOCOL" != "http" ] && [ "$PROTOCOL" != "https" ]; then
  echo "❌ PROTOCOL must be either 'http' or 'https'"
  exit 1
fi

# Set SSL variables based on protocol
if [ "$PROTOCOL" = "https" ]; then
  export IS_HTTPS=true
  export TLS_RESOLVER=letsencrypt
  echo "🔒 Using HTTPS mode with Let's Encrypt"
else
  export IS_HTTPS=false
  export TLS_RESOLVER=""
  echo "ℹ️ Using HTTP mode"
fi

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers
echo "🚀 Starting services..."
docker compose -f docker-compose/docker-compose.yml up -d

echo "✅ Deployment completed!"
echo "🌐 Application should be available at ${PROTOCOL}://$DOMAIN"
if [ "$PROTOCOL" = "http" ]; then
  echo ""
  echo "⚠️ Currently running in HTTP mode. To enable HTTPS:"
  echo "1. Set PROTOCOL=https in .env"
  echo "2. Run this script again"
fi
