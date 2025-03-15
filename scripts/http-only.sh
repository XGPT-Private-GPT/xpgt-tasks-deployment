#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🔧 Starting HTTP-only deployment..."

# Check and export environment variables
echo "📝 Checking environment configuration..."
source ./scripts/check-env.sh

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest



# Start the containers in HTTP-only mode
echo "🚀 Starting services in HTTP-only mode..."
docker compose -f docker-compose/http-only.yml --env-file .env up -d

echo "✅ HTTP-only deployment completed!"
echo "🌐 Application should be available at http://$DOMAIN"
echo ""
echo "⚠️ This is running in HTTP-only mode for initial testing."
echo "👉 Once you've verified everything works, run ./scripts/transition.sh to safely enable HTTPS."
