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

# Always enable HTTPS support
export IS_HTTPS=true
export TLS_RESOLVER=letsencrypt
echo "🔒 HTTPS enabled with Let's Encrypt (HTTP also supported)"

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers
echo "🚀 Starting services..."
docker compose -f docker-compose/docker-compose.yml up -d

echo "✅ Deployment completed!"
echo "🌐 Application is available at:"
echo "   - https://$DOMAIN (secured with SSL)"
echo "   - http://$DOMAIN"
