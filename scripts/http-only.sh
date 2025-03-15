#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

echo "🔧 Starting HTTP-only deployment..."

# Create necessary directories if they don't exist
echo "📁 Creating necessary directories..."
mkdir -p data/traefik
mkdir -p data/mongodb

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Export the environment variables explicitly
export DOMAIN
export IMAGE_PATH
export MONGO_USERNAME
export MONGO_PASSWORD
export MONGO_DATABASE
export NODE_ENV

# Start the containers in HTTP-only mode
echo "🚀 Starting services in HTTP-only mode..."
docker compose -f docker-compose/http-only.yml --env-file .env up -d

echo "✅ HTTP-only deployment completed!"
echo "🌐 Application should be available at http://$DOMAIN"
echo ""
echo "⚠️ This is running in HTTP-only mode for initial testing."
echo "👉 Once you've verified everything works, run ./scripts/transition.sh to safely enable HTTPS."
