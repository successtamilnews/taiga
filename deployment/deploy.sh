#!/bin/bash

# Taiga Production Deployment Script
# Usage: ./deploy.sh [environment] [branch]
# Example: ./deploy.sh production main

set -e

ENVIRONMENT=${1:-staging}
BRANCH=${2:-main}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PROJECT_PATH="/var/www/taiga"
BACKUP_PATH="/var/backups/taiga"

echo "🚀 Starting Taiga deployment for $ENVIRONMENT environment..."

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_PATH

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to handle errors
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    error_exit "This script should not be run as root for security reasons"
fi

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    error_exit "Docker is not installed or not in PATH"
fi

if ! docker info &> /dev/null; then
    error_exit "Docker is not running or user doesn't have permission to access Docker"
fi

# Navigate to project directory
cd $PROJECT_PATH || error_exit "Project directory not found: $PROJECT_PATH"

# Create database backup
log "Creating database backup..."
docker compose -f deployment/docker-compose.prod.yml exec -T mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} taiga_production > $BACKUP_PATH/database_backup_$TIMESTAMP.sql

# Backup current .env file
log "Backing up current environment configuration..."
cp backend/.env $BACKUP_PATH/.env_backup_$TIMESTAMP

# Pull latest code
log "Pulling latest code from branch: $BRANCH"
git fetch origin
git checkout $BRANCH
git pull origin $BRANCH

# Copy environment configuration
log "Setting up environment configuration for $ENVIRONMENT..."
if [[ "$ENVIRONMENT" == "production" ]]; then
    cp deployment/.env.production backend/.env
else
    cp deployment/.env.staging backend/.env
fi

# Install/update backend dependencies
log "Installing backend dependencies..."
docker compose -f deployment/docker-compose.prod.yml exec -T backend composer install --no-dev --optimize-autoloader

# Install/update frontend dependencies and build
log "Building frontend application..."
docker compose -f deployment/docker-compose.prod.yml exec -T frontend npm ci
docker compose -f deployment/docker-compose.prod.yml exec -T frontend npm run build

# Run database migrations
log "Running database migrations..."
docker compose -f deployment/docker-compose.prod.yml exec -T backend php artisan migrate --force

# Clear and cache Laravel configurations
log "Optimizing Laravel application..."
docker compose -f deployment/docker-compose.prod.yml exec -T backend php artisan config:cache
docker compose -f deployment/docker-compose.prod.yml exec -T backend php artisan route:cache
docker compose -f deployment/docker-compose.prod.yml exec -T backend php artisan view:cache

# Restart services to apply changes
log "Restarting application services..."
docker compose -f deployment/docker-compose.prod.yml restart backend frontend

# Restart queue workers
log "Restarting queue workers..."
docker compose -f deployment/docker-compose.prod.yml restart queue-worker

# Run health checks
log "Running health checks..."
sleep 10  # Wait for services to start

# Check backend health
if ! curl -f http://localhost:8000/api/health &> /dev/null; then
    error_exit "Backend health check failed"
fi

# Check frontend health
if ! curl -f http://localhost:3000/api/health &> /dev/null; then
    error_exit "Frontend health check failed"
fi

# Clean up old backups (keep last 7 days)
log "Cleaning up old backups..."
find $BACKUP_PATH -name "*.sql" -mtime +7 -delete
find $BACKUP_PATH -name ".env_backup_*" -mtime +7 -delete

# Clean up old Docker images
log "Cleaning up old Docker images..."
docker image prune -f

log "✅ Deployment completed successfully!"
log "🌐 Website: http://localhost:3000"
log "🔧 API: http://localhost:8000"
log "📊 Admin Panel: http://localhost:8000/admin"

# Send deployment notification (optional)
if [[ -n "$SLACK_WEBHOOK" ]]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚀 Taiga $ENVIRONMENT deployment completed successfully at $(date)\"}" \
        $SLACK_WEBHOOK
fi

log "Deployment script finished at $(date)"