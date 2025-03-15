#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🔄 Starting gradual transition to HTTPS..."

# Check and export environment variables
echo "📝 Checking environment configuration..."
source ./scripts/check-env.sh

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers in transition mode
echo "🚀 Starting services in transition mode..."
docker compose -f docker-compose/transition.yml up -d

echo "✅ Transition mode activated!"
echo "🌐 Application is now available at both:"
echo "   - http://$DOMAIN (still working)"
echo "   - https://$DOMAIN (being set up)"
echo ""
echo "⏳ Waiting for SSL certificates to be issued..."
echo "👉 Run 'docker compose -f docker-compose/transition.yml logs traefik' to check certificate status"
echo "👉 Once certificates are working, run './scripts/production.sh' for full HTTPS mode"
