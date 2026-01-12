#!/bin/bash

# Server Setup Script for Taiga Production Environment
# Run this script on a fresh Ubuntu/Debian server to prepare it for deployment

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

log "🔧 Starting server setup for Taiga production deployment..."

# Update system packages
log "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install essential packages
log "Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    fail2ban \
    ufw \
    htop \
    vim \
    certbot \
    python3-certbot-nginx

# Install Docker
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose
log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Configure firewall
log "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configure fail2ban
log "Configuring fail2ban..."
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create project directory
log "Creating project directory..."
sudo mkdir -p /var/www/taiga
sudo chown -R $USER:$USER /var/www/taiga

# Create backup directory
log "Creating backup directory..."
sudo mkdir -p /var/backups/taiga
sudo chown -R $USER:$USER /var/backups/taiga

# Clone repository
log "Cloning Taiga repository..."
cd /var/www/taiga
git clone <your-repository-url> .

# Create environment file
log "Creating production environment file..."
cp deployment/.env.production.template deployment/.env.production

# Set up SSL certificates (Let's Encrypt)
log "Setting up SSL certificates..."
read -p "Enter your domain name (e.g., yourdomain.com): " DOMAIN_NAME
read -p "Enter your email for Let's Encrypt: " EMAIL

sudo certbot certonly --standalone -d $DOMAIN_NAME -d www.$DOMAIN_NAME --email $EMAIL --agree-tos --no-eff-email

# Configure Nginx
log "Configuring Nginx..."
cat > /etc/nginx/sites-available/taiga << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/taiga /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Set up automatic SSL renewal
log "Setting up automatic SSL renewal..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

# Create deployment user
log "Creating deployment user..."
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo usermod -aG www-data deploy

# Set up SSH key for deployment user
log "Setting up SSH key for deployment user..."
sudo mkdir -p /home/deploy/.ssh
echo "Please add your deployment public key to /home/deploy/.ssh/authorized_keys"

# Create system service for Taiga
log "Creating systemd service..."
cat > /etc/systemd/system/taiga.service << EOF
[Unit]
Description=Taiga Multi-Vendor Ecommerce Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/var/www/taiga
ExecStart=/usr/local/bin/docker-compose -f deployment/docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f deployment/docker-compose.prod.yml down
User=deploy
Group=deploy

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable taiga
sudo systemctl daemon-reload

# Set up log rotation
log "Setting up log rotation..."
cat > /etc/logrotate.d/taiga << EOF
/var/log/taiga/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 deploy deploy
    postrotate
        docker-compose -f /var/www/taiga/deployment/docker-compose.prod.yml restart
    endscript
}
EOF

# Set up monitoring (optional)
log "Setting up basic monitoring..."
cat > /usr/local/bin/taiga-health-check << EOF
#!/bin/bash
if ! curl -f http://localhost:8000/api/health > /dev/null 2>&1; then
    echo "Taiga API health check failed" | logger -t taiga-monitor
    # Restart services
    cd /var/www/taiga
    docker-compose -f deployment/docker-compose.prod.yml restart
fi
EOF

chmod +x /usr/local/bin/taiga-health-check
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/taiga-health-check") | crontab -

# Set proper permissions
log "Setting proper permissions..."
sudo chown -R deploy:deploy /var/www/taiga
sudo chmod +x /var/www/taiga/deployment/deploy.sh

log "✅ Server setup completed successfully!"
log ""
log "Next steps:"
log "1. Update deployment/.env.production with your production values"
log "2. Configure payment gateway credentials"
log "3. Set up database backup strategy"
log "4. Configure monitoring and alerting"
log "5. Run the deployment script: ./deployment/deploy.sh production"
log ""
log "Important files to configure:"
log "- /var/www/taiga/deployment/.env.production"
log "- /var/www/taiga/deployment/docker-compose.prod.yml"
log ""
log "Server is ready for Taiga deployment! 🚀"