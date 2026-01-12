# Taiga Production Deployment Guide

## 🚀 Quick Deployment Steps

### 1. Server Preparation
```bash
# Run on fresh Ubuntu/Debian server
wget https://raw.githubusercontent.com/your-repo/taiga/main/deployment/server-setup.sh
chmod +x server-setup.sh
./server-setup.sh
```

### 2. Configuration
```bash
cd /var/www/taiga
cp deployment/.env.production.template deployment/.env.production
# Edit deployment/.env.production with your values
nano deployment/.env.production
```

### 3. Deploy
```bash
./deployment/deploy.sh production main
```

## 📋 Detailed Deployment Checklist

### Pre-Deployment Requirements

#### Infrastructure Setup
- [ ] **Server**: Ubuntu 20.04+ / Debian 11+ with 4GB+ RAM, 2+ CPU cores
- [ ] **Domain**: Domain name pointed to server IP
- [ ] **SSL**: Let's Encrypt certificates configured
- [ ] **Database**: Production MySQL/PostgreSQL instance
- [ ] **Redis**: Redis server for caching and queues
- [ ] **Storage**: AWS S3 / CloudFlare R2 bucket configured
- [ ] **Email**: SMTP service (SendGrid, Mailgun, AWS SES)

#### Payment Gateway Setup
- [ ] **Google Pay**: Production merchant account and credentials
- [ ] **Apple Pay**: Developer account and merchant certificates
- [ ] **Sampath Bank**: Live IPG credentials and endpoints

### Environment Configuration

#### Production .env Setup
```bash
# Copy template and configure
cp deployment/.env.production.template backend/.env

# Required changes:
# - APP_KEY: Generate new key
# - Database credentials
# - Payment gateway credentials
# - SMTP configuration
# - Storage credentials
# - Domain URLs
```

#### Security Configuration
```bash
# Generate new app key
docker compose exec backend php artisan key:generate

# Set secure cookie settings
SESSION_SECURE_COOKIE=true
SANCTUM_STATEFUL_DOMAINS=yourdomain.com

# Configure rate limiting
THROTTLE_REQUESTS_PER_MINUTE=60
```

### Database Setup

#### Production Database
```sql
-- Create database and user
CREATE DATABASE taiga_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'taiga_user'@'%' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON taiga_production.* TO 'taiga_user'@'%';
FLUSH PRIVILEGES;
```

#### Run Migrations
```bash
# Migrate database
docker compose -f deployment/docker-compose.prod.yml exec backend php artisan migrate --force

# Seed initial data (optional)
docker compose -f deployment/docker-compose.prod.yml exec backend php artisan db:seed --class=ProductionSeeder
```

### SSL & Security

#### Let's Encrypt Setup
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Generate certificates
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

#### Firewall Configuration
```bash
# Configure UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### Performance Optimization

#### Redis Configuration
```bash
# Edit redis.conf
maxmemory 256mb
maxmemory-policy allkeys-lru

# Password protection
requirepass your-redis-password
```

#### PHP Optimization (backend/deployment/php/php.prod.ini)
```ini
memory_limit = 256M
max_execution_time = 60
upload_max_filesize = 10M
post_max_size = 10M

opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=4000
opcache.validate_timestamps=0
```

#### Database Optimization
```sql
-- MySQL configuration
set global innodb_buffer_pool_size = 1073741824; -- 1GB
set global query_cache_size = 268435456; -- 256MB
set global query_cache_type = 1;
```

### Monitoring & Logging

#### Health Checks
```bash
# API health check endpoint
curl -f https://yourdomain.com/api/health

# Database connection check
curl -f https://yourdomain.com/api/health/database

# Storage check
curl -f https://yourdomain.com/api/health/storage
```

#### Log Management
```bash
# View application logs
docker compose logs -f backend

# View nginx logs
docker compose logs -f nginx

# View queue worker logs
docker compose logs -f queue-worker
```

#### Monitoring Setup
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Set up log rotation
sudo nano /etc/logrotate.d/taiga
```

### Backup Strategy

#### Database Backup
```bash
# Create backup script
cat > /usr/local/bin/backup-taiga-db << 'EOF'
#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
docker compose exec -T mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} taiga_production > /var/backups/taiga/db_backup_${TIMESTAMP}.sql
gzip /var/backups/taiga/db_backup_${TIMESTAMP}.sql
EOF

chmod +x /usr/local/bin/backup-taiga-db

# Schedule daily backups
echo "0 2 * * * /usr/local/bin/backup-taiga-db" | crontab -
```

#### File System Backup
```bash
# Backup uploaded files
aws s3 sync s3://your-bucket /var/backups/taiga/files/

# Backup configuration
tar -czf /var/backups/taiga/config_$(date +%Y%m%d).tar.gz /var/www/taiga/backend/.env
```

### CI/CD Pipeline

#### GitHub Actions Setup
1. Add repository secrets:
   - `PRODUCTION_HOST`: Server IP address
   - `PRODUCTION_USER`: SSH username
   - `PRODUCTION_SSH_KEY`: Private SSH key
   - `MYSQL_ROOT_PASSWORD`: Database root password

2. Configure deployment workflow in `.github/workflows/deploy.yml`

#### Manual Deployment
```bash
# Pull latest code
cd /var/www/taiga
git pull origin main

# Deploy
./deployment/deploy.sh production main
```

### Mobile App Deployment

#### Android (Google Play Store)
```bash
# Build production APK
cd mobile/user_app
flutter build apk --release --build-number=$BUILD_NUMBER

# Upload to Play Store Console
# Use Google Play Console or fastlane
```

#### iOS (App Store)
```bash
# Build for iOS
cd mobile/user_app
flutter build ios --release --build-number=$BUILD_NUMBER

# Upload to App Store Connect
# Use Xcode or fastlane
```

### Post-Deployment Verification

#### Functional Tests
- [ ] **User Registration**: Test account creation flow
- [ ] **Login/Authentication**: Verify login functionality
- [ ] **Product Catalog**: Check product listings and search
- [ ] **Shopping Cart**: Test add/remove items
- [ ] **Checkout Process**: Complete test purchase
- [ ] **Payment Processing**: Test all payment gateways
- [ ] **Order Management**: Verify order tracking
- [ ] **Admin Panel**: Check backend functionality
- [ ] **Vendor Dashboard**: Test vendor features
- [ ] **Mobile Apps**: Verify app functionality

#### Performance Tests
- [ ] **Load Testing**: Test with expected traffic
- [ ] **Database Performance**: Check query execution times
- [ ] **API Response Times**: Monitor API endpoint performance
- [ ] **File Upload**: Test large file uploads
- [ ] **Caching**: Verify Redis cache is working

#### Security Verification
- [ ] **SSL Certificate**: Verify HTTPS is enforced
- [ ] **API Security**: Test authentication and authorization
- [ ] **File Permissions**: Check proper file system permissions
- [ ] **Database Security**: Verify database access restrictions
- [ ] **Input Validation**: Test for XSS and SQL injection

### Maintenance Tasks

#### Regular Updates
```bash
# Weekly security updates
sudo apt update && sudo apt upgrade -y

# Monthly Laravel updates
composer update

# Quarterly dependency updates
npm audit fix
```

#### Performance Monitoring
```bash
# Monitor server resources
htop
iotop
df -h

# Monitor application performance
docker stats
```

#### Backup Verification
```bash
# Test backup restoration
mysql -u root -p taiga_test < /var/backups/taiga/latest_backup.sql

# Verify backup integrity
gzip -t /var/backups/taiga/*.sql.gz
```

## 🚨 Troubleshooting

### Common Issues

#### Database Connection Issues
```bash
# Check database status
docker compose ps mysql
docker compose logs mysql

# Test connection
docker compose exec backend php artisan tinker
DB::connection()->getPdo();
```

#### SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate
sudo certbot renew --dry-run
```

#### Performance Issues
```bash
# Check queue workers
docker compose ps queue-worker
docker compose logs queue-worker

# Clear caches
docker compose exec backend php artisan cache:clear
docker compose exec backend php artisan config:clear
```

### Emergency Procedures

#### Quick Rollback
```bash
# Restore from backup
cd /var/www/taiga
git reset --hard HEAD~1
./deployment/deploy.sh production main
```

#### Database Restoration
```bash
# Restore database backup
gunzip < /var/backups/taiga/latest_backup.sql.gz | docker compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} taiga_production
```

---

## 📞 Production Support

- **Documentation**: Available in `/docs` directory
- **Logs**: Check with `docker compose logs [service]`
- **Monitoring**: Set up alerts for critical metrics
- **Backup**: Automated daily backups configured

**Your Taiga platform is production-ready! 🚀**