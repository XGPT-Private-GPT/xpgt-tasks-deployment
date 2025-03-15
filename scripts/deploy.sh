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

# Check if .env file exists and is readable
if [ ! -f ".env" ]; then
  echo "❌ No .env file found. Please copy .env.template to .env and configure it."
  exit 1
fi

if [ ! -r ".env" ]; then
  echo "❌ .env file is not readable. Please check permissions."
  exit 1
fi

echo "📝 Loading environment variables..."
set -a
if ! source .env; then
  echo "❌ Failed to source .env file"
  exit 1
fi
set +a

# Verify required environment variables
required_vars=("DOMAIN" "IMAGE_PATH" "JWT_SECRET" "SMTP_USER" "SMTP_PASS" "SMTP_FROM" "DISCORD_WEBHOOK_URL")
missing_vars=0

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Required variable $var is not set in .env"
    missing_vars=1
  fi
done

if [ $missing_vars -eq 1 ]; then
  echo "Please set all required variables in .env and try again."
  exit 1
fi

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
