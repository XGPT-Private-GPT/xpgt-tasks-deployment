#!/usr/bin/env bash
set -e

# XGPTWorks Docker Deployment Installer
# Version: 1.0.0

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}║  ${GREEN}XGPTWorks Docker Deployment Installer${BLUE}                        ║${NC}"
echo -e "${BLUE}║                                                               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check dependencies
check_dependency() {
  if ! command -v $1 &> /dev/null; then
    echo -e "${RED}Error: $1 is not installed. Please install $1 first.${NC}"
    return 1
  fi
  return 0
}

# Ensure Docker is installed
check_dependency "docker" || {
  echo -e "${YELLOW}Would you like to install Docker now? [y/N]${NC}"
  read -p "> " install_docker
  if [[ $install_docker =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
  else
    echo -e "${YELLOW}Please install Docker first and then run this script again.${NC}"
    exit 1
  fi
}

# Ensure Docker Compose is installed (built into Docker CLI in newer versions)
docker compose version &> /dev/null || {
  echo -e "${RED}Error: Docker Compose is not available.${NC}"
  echo -e "${YELLOW}Please install Docker Compose plugin or update Docker to a newer version.${NC}"
  exit 1
}

# Create deployment directory
echo -e "${BLUE}Creating deployment directory...${NC}"
DEPLOY_DIR="tasks-xgpt-works"
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

# Create main docker-compose.production.yml file
echo -e "${BLUE}Creating docker-compose.production.yml...${NC}"
cat > docker-compose.production.yml << 'EOF'
version: "3.8"

services:
  # Traefik reverse proxy
  traefik:
    image: traefik:v2.9
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--api.insecure=true"  # Enable dashboard - secure this in production
      - "--certificatesresolvers.myresolver.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      # Redirect HTTP to HTTPS
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - letsencrypt:/letsencrypt
    restart: always

  # MongoDB service
  mongodb:
    image: mongo:latest
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USERNAME:-root}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD:-change_this_password}
    restart: always

  # Backend service
  backend:
    image: ${IMAGE_PATH}/backend:latest
    environment:
      - NODE_ENV=production
      - PORT=8080
      - MONGODB_URI=mongodb://${MONGO_USERNAME:-root}:${MONGO_PASSWORD:-change_this_password}@mongodb:27017/${MONGO_DATABASE:-tasks-xgpt-works}?authSource=admin
    volumes:
      - uploads:/app/uploads
    depends_on:
      - mongodb
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=PathPrefix(`/api`)"
      - "traefik.http.services.backend.loadbalancer.server.port=8080"
      - "traefik.http.routers.backend-secure.rule=Host(`${DOMAIN}`) && PathPrefix(`/api`)"
      - "traefik.http.routers.backend-secure.entrypoints=websecure"
      - "traefik.http.routers.backend-secure.tls=true"
      - "traefik.http.routers.backend-secure.tls.certresolver=myresolver"
    restart: always

  # Frontend service
  frontend:
    image: ${IMAGE_PATH}/frontend:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=PathPrefix(`/`)"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend.priority=1"
      - "traefik.http.routers.frontend-secure.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.frontend-secure.entrypoints=websecure"
      - "traefik.http.routers.frontend-secure.tls=true"
      - "traefik.http.routers.frontend-secure.tls.certresolver=myresolver"
      - "traefik.http.routers.frontend-secure.priority=1"
    restart: always

volumes:
  mongodb_data:
  uploads:
  letsencrypt:
EOF

# Create HTTP-only docker-compose file
echo -e "${BLUE}Creating docker-compose.http-only.yml...${NC}"
cat > docker-compose.http-only.yml << 'EOF'
version: "3.8"

services:
  # Traefik reverse proxy - HTTP ONLY MODE
  traefik:
    image: traefik:v2.9
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--api.insecure=true"
    ports:
      - "80:80"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: always

  # MongoDB service
  mongodb:
    image: mongo:latest
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USERNAME:-root}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD:-change_this_password}
    restart: always

  # Backend service
  backend:
    image: ${IMAGE_PATH}/backend:latest
    environment:
      - NODE_ENV=production
      - PORT=8080
      - MONGODB_URI=mongodb://${MONGO_USERNAME:-root}:${MONGO_PASSWORD:-change_this_password}@mongodb:27017/${MONGO_DATABASE:-tasks-xgpt-works}?authSource=admin
    volumes:
      - uploads:/app/uploads
    depends_on:
      - mongodb
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.backend.rule=PathPrefix(`/api`)"
      - "traefik.http.services.backend.loadbalancer.server.port=8080"
    restart: always

  # Frontend service
  frontend:
    image: ${IMAGE_PATH}/frontend:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=PathPrefix(`/`)"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend.priority=1"
    restart: always

volumes:
  mongodb_data:
  uploads:
EOF

# Create transition docker-compose file
echo -e "${BLUE}Creating docker-compose.transition.yml...${NC}"
cat > docker-compose.transition.yml << 'EOF'
version: "3.8"

services:
  # Traefik reverse proxy - TRANSITION MODE (HTTPS available but not forced)
  traefik:
    image: traefik:v2.9
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--api.insecure=true"
      - "--certificatesresolvers.myresolver.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      # NO HTTP to HTTPS redirect during transition
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - letsencrypt:/letsencrypt
    restart: always

  # MongoDB service
  mongodb:
    image: mongo:latest
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USERNAME:-root}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD:-change_this_password}
    restart: always

  # Backend service
  backend:
    image: ${IMAGE_PATH}/backend:latest
    environment:
      - NODE_ENV=production
      - PORT=8080
      - MONGODB_URI=mongodb://${MONGO_USERNAME:-root}:${MONGO_PASSWORD:-change_this_password}@mongodb:27017/${MONGO_DATABASE:-tasks-xgpt-works}?authSource=admin
    volumes:
      - uploads:/app/uploads
    depends_on:
      - mongodb
    labels:
      - "traefik.enable=true"
      # HTTP route
      - "traefik.http.routers.backend.rule=PathPrefix(`/api`)"
      - "traefik.http.services.backend.loadbalancer.server.port=8080"
      # HTTPS route
      - "traefik.http.routers.backend-secure.rule=Host(`${DOMAIN}`) && PathPrefix(`/api`)"
      - "traefik.http.routers.backend-secure.entrypoints=websecure"
      - "traefik.http.routers.backend-secure.tls=true"
      - "traefik.http.routers.backend-secure.tls.certresolver=myresolver"
    restart: always

  # Frontend service
  frontend:
    image: ${IMAGE_PATH}/frontend:latest
    labels:
      - "traefik.enable=true"
      # HTTP route
      - "traefik.http.routers.frontend.rule=PathPrefix(`/`)"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"
      - "traefik.http.routers.frontend.priority=1"
      # HTTPS route
      - "traefik.http.routers.frontend-secure.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.frontend-secure.entrypoints=websecure"
      - "traefik.http.routers.frontend-secure.tls=true"
      - "traefik.http.routers.frontend-secure.tls.certresolver=myresolver"
      - "traefik.http.routers.frontend-secure.priority=1"
    restart: always

volumes:
  mongodb_data:
  uploads:
  letsencrypt:
EOF

# Create .env template
echo -e "${BLUE}Creating .env template...${NC}"
cat > .env.template << 'EOF'
# Domain settings (required)
DOMAIN=your-domain.com                          # Your domain name
ACME_EMAIL=your-email@example.com               # Email for Let's Encrypt

# Docker image settings (required - where to pull images from)
IMAGE_PATH=ghcr.io/xgpt-private-gpt/tasks-xgpt-works    # Path to Docker images

# GitHub Container Registry auth (required for private repositories only)
# GITHUB_TOKEN=your_github_personal_access_token         # Only needed for private repos

# MongoDB settings (optional - defaults will be used if not specified)
# MONGO_USERNAME=root
# MONGO_PASSWORD=change_this_password
# MONGO_DATABASE=tasks-xgpt-works
EOF

# Create first-time setup script
echo -e "${BLUE}Creating first-time-setup.sh...${NC}"
cat > first-time-setup.sh << 'EOF'
#!/bin/bash
set -e

# Source environment variables
source .env

echo "🔧 Starting first-time HTTP-only setup..."

# Log in to GitHub Container Registry (only if GITHUB_TOKEN is provided)
if [ ! -z "$GITHUB_TOKEN" ]; then
  echo "🔑 Logging in to GitHub Container Registry..."
  echo $GITHUB_TOKEN | docker login ghcr.io -u $(echo $IMAGE_PATH | cut -d '/' -f 2) --password-stdin
fi

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers in HTTP-only mode
echo "🚀 Starting services in HTTP-only mode..."
docker compose -f docker-compose.http-only.yml up -d

echo "✅ First-time setup completed!"
echo "🌐 Application should be available at http://$DOMAIN"
echo ""
echo "⚠️ This is running in HTTP-only mode for initial testing."
echo "👉 Once you've verified everything works, run ./transition-to-https.sh to safely enable HTTPS."
EOF
chmod +x first-time-setup.sh

# Create transition script
echo -e "${BLUE}Creating transition-to-https.sh...${NC}"
cat > transition-to-https.sh << 'EOF'
#!/bin/bash
set -e

# Source environment variables
source .env

echo "🔄 Starting gradual transition to HTTPS..."

# Pull the latest images if needed
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers in transition mode
echo "🚀 Starting services in transition mode..."
docker compose -f docker-compose.transition.yml up -d

echo "✅ Transition mode activated!"
echo "🌐 Application is now available at both:"
echo "   - http://$DOMAIN (still working)"
echo "   - https://$DOMAIN (being set up)"
echo ""
echo "⏳ Waiting for SSL certificates to be issued..."
echo "👉 Run 'docker compose -f docker-compose.transition.yml logs traefik' to check certificate status"
echo "👉 Once certificates are working, run './deploy.sh' to enable full HTTPS-only mode"
EOF
chmod +x transition-to-https.sh

# Create deployment script
echo -e "${BLUE}Creating deploy.sh...${NC}"
cat > deploy.sh << 'EOF'
#!/bin/bash
set -e

# Source environment variables
source .env

# Log in to GitHub Container Registry (only if GITHUB_TOKEN is provided)
if [ ! -z "$GITHUB_TOKEN" ]; then
  echo "🔑 Logging in to GitHub Container Registry..."
  echo $GITHUB_TOKEN | docker login ghcr.io -u $(echo $IMAGE_PATH | cut -d '/' -f 2) --password-stdin
fi

# Pull the latest images
echo "🔄 Pulling latest images..."
docker pull ${IMAGE_PATH}/backend:latest
docker pull ${IMAGE_PATH}/frontend:latest

# Start the containers
echo "🚀 Starting services with full HTTPS..."
docker compose -f docker-compose.production.yml up -d

echo "✅ Deployment completed!"
echo "🌐 Application should be available at https://$DOMAIN"
EOF
chmod +x deploy.sh

# Create emergency rollback script
echo -e "${BLUE}Creating emergency-rollback.sh...${NC}"
cat > emergency-rollback.sh << 'EOF'
#!/bin/bash
set -e

# Source environment variables
source .env

echo "🚨 Performing emergency rollback to HTTP-only mode..."

# Stop the current deployment
docker compose -f docker-compose.production.yml down 2>/dev/null || true
docker compose -f docker-compose.transition.yml down 2>/dev/null || true
docker compose -f docker-compose.http-only.yml down 2>/dev/null || true

# Start the containers in HTTP-only mode
echo "🚀 Starting services in HTTP-only mode..."
docker compose -f docker-compose.http-only.yml up -d

echo "✅ Emergency rollback completed!"
echo "🌐 Application should be available at http://$DOMAIN"
echo ""
echo "⚠️ This is running in HTTP-only mode for emergency recovery."
echo "👉 Once issues are resolved, try the transition process again with ./transition-to-https.sh"
EOF
chmod +x emergency-rollback.sh

# Configure environment
echo -e "${BLUE}Setting up environment...${NC}"
cp .env.template .env

# Prompt for configuration
echo -e "${YELLOW}Would you like to configure your .env file now? [Y/n]${NC}"
read -p "> " configure_env
if [[ ! $configure_env =~ ^[Nn]$ ]]; then
  echo -e "${GREEN}Please enter your domain name (e.g., example.com):${NC}"
  read -p "> " domain_name
  if [ ! -z "$domain_name" ]; then
    sed -i.bak "s/DOMAIN=your-domain.com/DOMAIN=$domain_name/g" .env && rm -f .env.bak
  fi
  
  echo -e "${GREEN}Please enter your email address for Let's Encrypt:${NC}"
  read -p "> " email_address
  if [ ! -z "$email_address" ]; then
    sed -i.bak "s/ACME_EMAIL=your-email@example.com/ACME_EMAIL=$email_address/g" .env && rm -f .env.bak
  fi
  
  echo -e "${GREEN}Please enter your Docker image path (default: ghcr.io/xgpt-private-gpt/tasks-xgpt-works):${NC}"
  read -p "> " image_path
  if [ ! -z "$image_path" ]; then
    sed -i.bak "s|IMAGE_PATH=ghcr.io/xgpt-private-gpt/tasks-xgpt-works|IMAGE_PATH=$image_path|g" .env && rm -f .env.bak
  fi
  
  echo -e "${GREEN}Is this a private repository requiring authentication? [y/N]${NC}"
  read -p "> " is_private
  if [[ $is_private =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Please enter your GitHub Personal Access Token:${NC}"
    read -p "> " github_token
    if [ ! -z "$github_token" ]; then
      sed -i.bak "s/# GITHUB_TOKEN=your_github_personal_access_token/GITHUB_TOKEN=$github_token/g" .env && rm -f .env.bak
    fi
  fi
  
  echo -e "${GREEN}Would you like to customize MongoDB settings? [y/N]${NC}"
  read -p "> " customize_mongo
  if [[ $customize_mongo =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}MongoDB username (default: root):${NC}"
    read -p "> " mongo_user
    if [ ! -z "$mongo_user" ]; then
      sed -i.bak "s/# MONGO_USERNAME=root/MONGO_USERNAME=$mongo_user/g" .env && rm -f .env.bak
    fi
    
    echo -e "${GREEN}MongoDB password:${NC}"
    read -p "> " mongo_pass
    if [ ! -z "$mongo_pass" ]; then
      sed -i.bak "s/# MONGO_PASSWORD=change_this_password/MONGO_PASSWORD=$mongo_pass/g" .env && rm -f .env.bak
    fi
    
    echo -e "${GREEN}MongoDB database name (default: tasks-xgpt-works):${NC}"
    read -p "> " mongo_db
    if [ ! -z "$mongo_db" ]; then
      sed -i.bak "s/# MONGO_DATABASE=tasks-xgpt-works/MONGO_DATABASE=$mongo_db/g" .env && rm -f .env.bak
    fi
  fi
fi

# Provide deployment instructions
echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${YELLOW}Deployment Instructions:${NC}"
echo ""
echo -e "${GREEN}Step 1: Start with HTTP-only mode for testing:${NC}"
echo -e "  ./first-time-setup.sh"
echo ""
echo -e "${GREEN}Step 2: Once HTTP works, enable HTTPS alongside HTTP:${NC}"
echo -e "  ./transition-to-https.sh"
echo ""
echo -e "${GREEN}Step 3: Finally, switch to full HTTPS mode:${NC}"
echo -e "  ./deploy.sh"
echo ""
echo -e "${RED}Emergency rollback if needed:${NC}"
echo -e "  ./emergency-rollback.sh"
echo -e "${BLUE}=========================================================${NC}"
echo ""
echo -e "${GREEN}For detailed documentation, visit:${NC}"
echo -e "https://github.com/xgpt-private-gpt/tasks-xgpt-works/blob/main/DEPLOYMENT.md"
echo ""

# Offer to start deployment
echo -e "${YELLOW}Would you like to start the HTTP-only deployment now? [Y/n]${NC}"
read -p "> " start_deploy
if [[ ! $start_deploy =~ ^[Nn]$ ]]; then
  echo -e "${BLUE}Starting HTTP-only deployment...${NC}"
  ./first-time-setup.sh
fi
