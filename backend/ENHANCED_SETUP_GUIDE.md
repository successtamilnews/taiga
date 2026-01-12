# Enhanced Backend Services Setup Guide

This guide covers the complete setup and configuration of the enhanced backend services for the Taiga multi-vendor ecommerce platform.

## 🚀 Overview

The enhanced backend includes:
- **WebSocket Server**: Real-time communication for orders, chat, delivery tracking
- **Analytics Service**: Comprehensive user behavior and business intelligence tracking  
- **Logging Service**: Multi-category logging with real-time monitoring
- **Performance Monitoring**: Advanced metrics and alerting

## 📋 Prerequisites

### System Requirements
- PHP 8.2+
- Laravel 11+
- Redis 6.0+
- MySQL/PostgreSQL
- Composer
- Node.js (for frontend integration)

### PHP Extensions
```bash
# Required extensions
php -m | grep -E "(redis|curl|json|mbstring|openssl|pdo|tokenizer|xml|ctype|fileinfo)"

# Install missing extensions (Ubuntu/Debian)
sudo apt-get install php-redis php-curl php-mbstring php-xml
```

## ⚙️ Installation Steps

### 1. Install Dependencies

```bash
cd /path/to/taiga/backend

# Install PHP dependencies
composer install

# Install WebSocket dependencies
composer require ratchet/pawl ratchet/rfc6455 firebase/php-jwt
```

### 2. Environment Configuration

```bash
# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=taiga_ecommerce
DB_USERNAME=your_username
DB_PASSWORD=your_password

# Configure Redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=null
REDIS_DATABASE=0

# WebSocket Configuration
WEBSOCKET_HOST=127.0.0.1
WEBSOCKET_PORT=8080
WEBSOCKET_JWT_SECRET=your_secure_jwt_secret_here
WEBSOCKET_API_SECRET=your_secure_api_secret_here

# Analytics Configuration
ANALYTICS_ENABLED=true
ANALYTICS_REAL_TIME_ENABLED=true
ANALYTICS_RETENTION_DAYS=90

# Logging Configuration
LOG_REAL_TIME_ENABLED=true
LOG_PERFORMANCE_TRACKING=true
LOG_SECURITY_EVENTS=true
LOG_AUDIT_ENABLED=true
```

### 3. Database Setup

```bash
# Run migrations
php artisan migrate

# Create audit log tables
php artisan migrate --path=database/migrations/2024_01_15_000001_create_audit_logs_table.php
php artisan migrate --path=database/migrations/2024_01_15_000002_create_security_logs_table.php
php artisan migrate --path=database/migrations/2024_01_15_000003_create_order_audit_logs_table.php
php artisan migrate --path=database/migrations/2024_01_15_000004_create_payment_audit_logs_table.php

# Seed database (optional)
php artisan db:seed
```

### 4. Cache and Queue Setup

```bash
# Clear and rebuild caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Create queue tables
php artisan queue:table
php artisan migrate
```

### 5. File Permissions

```bash
# Set proper permissions
chmod -R 775 storage/
chmod -R 775 bootstrap/cache/
chown -R www-data:www-data storage/
chown -R www-data:www-data bootstrap/cache/

# Create log directories
mkdir -p storage/logs/analytics
mkdir -p storage/logs/websocket
mkdir -p storage/logs/performance
```

## 🔧 Configuration Validation

Run the configuration validation command to ensure everything is set up correctly:

```bash
php artisan config:validate

# Attempt automatic fixes for common issues
php artisan config:validate --fix
```

## 🌐 WebSocket Server

### Starting the Server

```bash
# Development (foreground)
php artisan websocket:serve --host=127.0.0.1 --port=8080

# Production (background)
php artisan websocket:serve --host=0.0.0.0 --port=8080 --daemon

# Using the startup script
chmod +x scripts/websocket-server.sh
./scripts/websocket-server.sh start
```

### Server Management

```bash
# Check status
./scripts/websocket-server.sh status

# View logs
./scripts/websocket-server.sh logs

# Restart server
./scripts/websocket-server.sh restart

# Stop server
./scripts/websocket-server.sh stop
```

### Production Deployment with Supervisor

Create `/etc/supervisor/conf.d/taiga-websocket.conf`:

```ini
[program:taiga-websocket]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/taiga/backend/artisan websocket:serve --host=0.0.0.0 --port=8080 --daemon
directory=/path/to/taiga/backend
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/taiga-websocket.log
user=www-data
numprocs=1
```

```bash
# Update supervisor
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start taiga-websocket
```

## 📊 Queue Workers

### Start Queue Workers

```bash
# Default queue
php artisan queue:work --queue=default

# Analytics queue
php artisan queue:work --queue=analytics

# WebSocket queue  
php artisan queue:work --queue=websocket

# Notifications queue
php artisan queue:work --queue=notifications

# All queues
php artisan queue:work --queue=default,analytics,websocket,notifications
```

### Production Queue Management

Create `/etc/supervisor/conf.d/taiga-queue.conf`:

```ini
[program:taiga-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/taiga/backend/artisan queue:work --queue=default,analytics,websocket,notifications --sleep=3 --tries=3 --max-time=3600
directory=/path/to/taiga/backend
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/taiga-queue.log
user=www-data
numprocs=4
```

## 🔒 Security Configuration

### API Rate Limiting

Add to `config/cors.php` or create middleware:

```php
// Rate limiting for WebSocket connections
'websocket' => [
    'max_connections_per_ip' => 10,
    'message_rate_limit' => 100, // per minute
],

// API rate limiting
'api' => [
    'requests_per_minute' => 60,
    'burst_limit' => 10,
],
```

### CORS Configuration

Update `config/cors.php` for WebSocket support:

```php
'allowed_origins' => [
    'http://localhost:3000',    // Next.js website
    'http://localhost:8080',    // WebSocket
    'capacitor://localhost',    // Mobile apps
    'ionic://localhost',        // Mobile apps
],

'exposed_headers' => [
    'X-Request-ID',
    'X-Response-Time',
],
```

## 📈 Monitoring and Maintenance

### Health Checks

```bash
# Application health
curl http://localhost:8000/up

# WebSocket server health
curl http://localhost:8080/health

# Redis health
redis-cli ping

# Database health
php artisan tinker --execute="DB::connection()->getPdo();"
```

### Log Monitoring

```bash
# Real-time application logs
tail -f storage/logs/laravel.log

# WebSocket logs
tail -f storage/logs/websocket.log

# Analytics logs
tail -f storage/logs/analytics.log

# System logs
journalctl -u nginx -f
journalctl -u mysql -f
```

### Performance Monitoring

```bash
# Monitor WebSocket connections
redis-cli monitor | grep websocket

# Monitor queue status
php artisan queue:monitor

# Monitor cache performance
redis-cli info stats
```

## 🚨 Troubleshooting

### Common Issues

#### WebSocket Server Won't Start

```bash
# Check port availability
netstat -tulpn | grep :8080
lsof -i :8080

# Check firewall
sudo ufw status
sudo ufw allow 8080

# Check process limits
ulimit -n
```

#### Redis Connection Issues

```bash
# Check Redis status
redis-cli ping
sudo systemctl status redis

# Check Redis memory
redis-cli info memory

# Check Redis connections
redis-cli client list
```

#### Database Performance

```bash
# Check slow queries
mysql> SHOW PROCESSLIST;
mysql> SELECT * FROM information_schema.PROCESSLIST WHERE TIME > 10;

# Optimize tables
php artisan optimize:clear
composer dump-autoload --optimize
```

#### Queue Issues

```bash
# Check failed jobs
php artisan queue:failed

# Retry failed jobs
php artisan queue:retry all

# Clear all jobs
php artisan queue:flush
```

### Performance Optimization

#### Redis Optimization

```redis
# Add to redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

#### MySQL Optimization

```sql
-- Add to my.cnf
innodb_buffer_pool_size = 1G
query_cache_type = 1
query_cache_size = 256M
max_connections = 200
```

#### PHP Optimization

```ini
; Add to php.ini
memory_limit = 256M
max_execution_time = 30
opcache.enable = 1
opcache.memory_consumption = 128
opcache.max_accelerated_files = 10000
```

## 📚 API Documentation

### WebSocket API

Connect to WebSocket server:
```javascript
const ws = new WebSocket('ws://localhost:8080?token=YOUR_JWT_TOKEN&type=customer');
```

### Analytics API

```bash
# Record event
curl -X POST http://localhost:8000/api/analytics/events \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "product_viewed",
    "event_data": {"product_id": 123}
  }'

# Get real-time analytics
curl -X GET http://localhost:8000/api/analytics/real-time \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Logging API

```bash
# Log custom event
curl -X POST http://localhost:8000/api/logging/events \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "security",
    "level": "warning",
    "message": "Suspicious login attempt",
    "context": {"ip": "192.168.1.100"}
  }'

# Get real-time logs (admin only)
curl -X GET http://localhost:8000/api/logging/real-time \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## 🎯 Next Steps

1. **Testing**: Run comprehensive tests for all features
2. **Load Testing**: Test WebSocket server with multiple concurrent connections
3. **Monitoring Setup**: Configure dashboards and alerting
4. **Documentation**: Update API documentation
5. **Deployment**: Deploy to production environment

## 📞 Support

For issues and questions:
- Check logs: `storage/logs/`
- Validate configuration: `php artisan config:validate`
- Check system status: Health check endpoints
- Review this documentation
- Contact system administrator

---

**Note**: This setup guide covers the enhanced backend services. Ensure all mobile applications and frontend components are updated to use the new APIs and WebSocket endpoints.