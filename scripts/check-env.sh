#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

echo "🔍 Checking environment variables..."
echo "DOMAIN: $DOMAIN"
echo "IMAGE_PATH: $IMAGE_PATH"
echo "MONGO_USERNAME: $MONGO_USERNAME"
echo "MONGO_PASSWORD: $MONGO_PASSWORD"
echo "MONGO_DATABASE: $MONGO_DATABASE"
echo "NODE_ENV: $NODE_ENV"

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