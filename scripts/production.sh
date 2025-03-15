#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🔒 Starting fully secure HTTPS deployment..."

# Check and export environment variables
echo "📝 Checking environment configuration..."
source ./scripts/check-env.sh

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers in production mode
echo "🚀 Starting services in production mode (HTTPS only)..."
docker compose -f docker-compose/production.yml up -d

echo "✅ Production mode activated!"
echo "🔒 Application is now available only at https://$DOMAIN with full HTTPS security"
echo "⚠️ HTTP traffic will be automatically redirected to HTTPS"
echo ""
echo "👉 Run 'docker compose -f docker-compose/production.yml logs' to check service status"
echo "👉 If you need to roll back, run './scripts/rollback.sh'"
