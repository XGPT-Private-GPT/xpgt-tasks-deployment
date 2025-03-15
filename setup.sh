#!/bin/bash
set -e

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 Starting initial deployment setup..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️ No .env file found. Creating from template..."
    cp .env.template .env
    echo "📝 Please edit the .env file with your configuration before continuing."
    echo "   Required: DOMAIN, EMAIL"
    echo "   Optional: IMAGE_PATH, MONGO_* settings"
    exit 1
fi

# Source the environment variables
source .env

# Check for required variables
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "❌ DOMAIN and EMAIL must be set in .env file."
    exit 1
fi

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p data/mongodb
mkdir -p data/traefik

# Set permissions for MongoDB data directory
echo "🔒 Setting correct permissions for data directories..."
chmod 777 data/mongodb

# Create Traefik configuration
echo "⚙️ Setting up Traefik configuration..."
cat > data/traefik/traefik.yml << EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  http:
    address: ":80"
  https:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${EMAIL}
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: http
EOF

# Create empty acme.json for Let's Encrypt certificates
touch data/traefik/acme.json
chmod 600 data/traefik/acme.json

echo "✅ Setup complete!"
echo "👉 Run './scripts/http-only.sh' to start in HTTP-only mode"
echo "👉 After testing, run './scripts/transition.sh' to begin HTTPS setup"
