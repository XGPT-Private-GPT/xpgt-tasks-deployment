# Deployment Guide

This directory contains everything needed to deploy the application using Docker containers.

## Quick Start

```bash
# 1. Initialize the deployment environment
./setup.sh

# 2. Edit the .env file with your domain and settings
nano .env

# 3. Start with HTTP-only mode first (for testing)
./scripts/http-only.sh

# 4. When ready, start HTTPS transition
./scripts/transition.sh

# 5. Once certificates are working, enable full HTTPS
./scripts/production.sh
```

## Directory Structure

```
deploy/
├── docker-compose/       # Docker Compose configuration files
│   ├── http-only.yml     # HTTP-only configuration (initial setup)
│   ├── transition.yml    # Dual HTTP/HTTPS configuration
│   └── production.yml    # Full HTTPS with HTTP redirect
├── scripts/              # Deployment scripts
│   ├── http-only.sh      # Start HTTP-only deployment
│   ├── transition.sh     # Start transition to HTTPS
│   ├── production.sh     # Start production HTTPS deployment
│   └── rollback.sh       # Emergency rollback to HTTP
├── data/                 # Persistent data (created by setup.sh)
│   ├── mongodb/          # MongoDB data
│   └── traefik/          # Traefik configuration
├── .env                  # Environment configuration
├── .env.template         # Template for .env file
├── setup.sh              # Initial setup script
└── README.md             # This file
```

## Deployment Steps

### 1. Initial Setup

Run the `setup.sh` script to initialize the deployment environment:

```bash
./setup.sh
```

This will:
- Create a `.env` file from template if it doesn't exist
- Create necessary data directories
- Set up Traefik configuration

### 2. Configure Environment

Edit the `.env` file with your specific settings:

```bash
nano .env
```

Required settings:
- `DOMAIN`: Your domain name (e.g., example.com)
- `EMAIL`: Your email for Let's Encrypt certificates
- `IMAGE_PATH`: Path to Docker images (e.g., ghcr.io/username/repo-name)

### 3. Deployment Stages

#### HTTP-Only Mode (Initial Testing)

Start with HTTP-only mode to test the application:

```bash
./scripts/http-only.sh
```

This mode:
- Uses HTTP only (no HTTPS)
- Doesn't require SSL certificates
- Useful for initial setup and testing

#### Transition Mode (HTTP and HTTPS)

When ready to implement HTTPS, run:

```bash
./scripts/transition.sh
```

This mode:
- Runs both HTTP and HTTPS simultaneously
- Begins the process of acquiring SSL certificates
- Allows testing HTTPS without breaking HTTP access

#### Production Mode (HTTPS with Redirect)

Once certificates are working, switch to full production mode:

```bash
./scripts/production.sh
```

This mode:
- Forces HTTPS for all traffic
- Automatically redirects HTTP to HTTPS
- Provides the most secure configuration

### 4. Rollback (If Needed)

If you encounter issues with HTTPS, you can roll back to HTTP-only mode:

```bash
./scripts/rollback.sh
```

## Monitoring

- Traefik dashboard: https://traefik.yourdomain.com/
- Container logs: `docker logs [container_name]`
- All logs: `docker compose -f docker-compose/[current_config].yml logs` 