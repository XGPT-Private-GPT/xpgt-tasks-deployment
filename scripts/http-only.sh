#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

echo "🔧 Starting HTTP-only deployment..."

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ghcr.io/xgpt-private-gpt/tasks-xgpt-works/backend:latest
docker pull ghcr.io/xgpt-private-gpt/tasks-xgpt-works/frontend:latest

# Start the containers in HTTP-only mode
echo "🚀 Starting services in HTTP-only mode..."
docker compose -f docker-compose/http-only.yml up -d

echo "✅ HTTP-only deployment completed!"
echo "🌐 Application should be available at http://$DOMAIN"
echo ""
echo "⚠️ This is running in HTTP-only mode for initial testing."
echo "👉 Once you've verified everything works, run ./scripts/transition.sh to safely enable HTTPS."
