#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

echo "⚠️ Rolling back to HTTP-only mode..."

# Stop the current deployment
echo "🛑 Stopping current deployment..."
docker compose -f docker-compose/production.yml down || \
docker compose -f docker-compose/transition.yml down || \
docker compose -f docker-compose/http-only.yml down || true

# Start in HTTP-only mode
echo "🔄 Reverting to HTTP-only mode..."
docker compose -f docker-compose/http-only.yml up -d

echo "✅ Rollback complete!"
echo "🌐 Application is now available at http://$DOMAIN only"
echo "⚠️ HTTPS has been disabled"
echo ""
echo "👉 Run './scripts/http-only.sh' to refresh the HTTP-only deployment"
echo "👉 When ready to try HTTPS again, run './scripts/transition.sh'"
