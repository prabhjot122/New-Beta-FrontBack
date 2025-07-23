# LawVriksh Ubuntu Deployment Guide

## 🚀 Complete Deployment Steps for Ubuntu 24.04

This guide provides step-by-step instructions to deploy the LawVriksh platform on Ubuntu 24.04 with Docker.

### 📋 Prerequisites

- Ubuntu 24.04 LTS server
- 8GB RAM minimum
- 100GB storage minimum
- Domain name pointed to your server IP (lawvriksh.com)
- Root or sudo access

### 🔧 Step 1: System Preparation

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose (standalone)
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installations
docker --version
docker-compose --version
```

### 📁 Step 2: Project Setup

```bash
# Create project directory
sudo mkdir -p /opt/lawvriksh
sudo chown $USER:$USER /opt/lawvriksh
cd /opt/lawvriksh

# Clone or upload your project files
# If using git:
# git clone <your-repo-url> .

# If uploading files, ensure all project files are in /opt/lawvriksh/
# Your directory structure should look like:
# /opt/lawvriksh/
# ├── app/
# ├── Frontend/
# ├── docker-compose.production.yml
# ├── .env
# ├── requirements.txt
# └── other files...
```

### 🔐 Step 3: Environment Configuration

```bash
# Create production environment file
cat > .env << 'EOF'
# Database Configuration
DB_USER=lawvriksh_user
DB_PASSWORD=Sahil123
DB_NAME=lawvriksh_referral
DB_HOST=mysql
DB_PORT=3306
MYSQL_ROOT_PASSWORD=Sahil123

# Database URL (takes precedence)
DATABASE_URL=mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral

# Security
JWT_SECRET_KEY=your-super-secret-key-here-make-it-long-and-random-for-production-use-change-this

# Message Queue
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# Redis
REDIS_PASSWORD=redis_secure_password_123

# Email Configuration
EMAIL_FROM=info@lawvriksh.com
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=info@lawvriksh.com
SMTP_PASSWORD=Lawvriksh@123

# Application Settings
CACHE_DIR=./cache
ENVIRONMENT=production

# Domain Configuration
DOMAIN=lawvriksh.com
FRONTEND_URL=https://lawvriksh.com

# Admin Configuration
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123
EOF

# Secure the environment file
chmod 600 .env
```

### 🐳 Step 4: Docker Deployment

```bash
# Create necessary directories
mkdir -p logs/{mysql,backend,celery,celery-beat,rabbitmq,redis}
mkdir -p cache uploads

# Build and start services
docker-compose -f docker-compose.production.yml up -d --build

# Wait for services to start
echo "Waiting for services to start..."
sleep 60

# Check service status
docker-compose -f docker-compose.production.yml ps
```

### 🗄️ Step 5: Database Setup

```bash
# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until docker-compose -f docker-compose.production.yml exec mysql mysqladmin ping -h localhost -u root -pSahil123 --silent; do
    echo "Waiting for MySQL..."
    sleep 5
done

# Initialize database schema
docker-compose -f docker-compose.production.yml exec mysql mysql -u root -pSahil123 -e "
CREATE DATABASE IF NOT EXISTS lawvriksh_referral CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON lawvriksh_referral.* TO 'lawvriksh_user'@'%';
FLUSH PRIVILEGES;
"

# Import database schema
docker-compose -f docker-compose.production.yml exec -T mysql mysql -u root -pSahil123 lawvriksh_referral < lawdata.sql

# Setup admin user
docker-compose -f docker-compose.production.yml exec backend python setup_admin_corrected.py
```

### 🌐 Step 6: Nginx Configuration

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/lawvriksh.com << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # SSL Configuration (you'll need to add SSL certificates)
    # ssl_certificate /path/to/your/certificate.crt;
    # ssl_certificate_key /path/to/your/private.key;
    
    # For now, comment out SSL and use HTTP only for testing
    # listen 80;
    # Remove the SSL lines above
    
    # Frontend (React app)
    location / {
        proxy_pass http://localhost:3001;  # Assuming frontend runs on 3001
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://lawvriksh.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://lawvriksh.com";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/lawvriksh.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 🔒 Step 7: SSL Certificate (Optional but Recommended)

```bash
# Install Certbot for Let's Encrypt
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com

# Auto-renewal setup
sudo systemctl enable certbot.timer
```

### 🏗️ Step 8: Frontend Build and Deployment

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Build frontend
cd Frontend
npm install
npm run build

# Serve frontend with a simple HTTP server or configure Nginx to serve static files
# Option 1: Use serve package
sudo npm install -g serve
nohup serve -s dist -l 3001 > ../logs/frontend.log 2>&1 &

# Option 2: Configure Nginx to serve static files (recommended)
# Copy built files to Nginx directory
sudo mkdir -p /var/www/lawvriksh
sudo cp -r dist/* /var/www/lawvriksh/
sudo chown -R www-data:www-data /var/www/lawvriksh

# Update Nginx config to serve static files instead of proxying
# Edit /etc/nginx/sites-available/lawvriksh.com and change:
# location / {
#     root /var/www/lawvriksh;
#     index index.html;
#     try_files $uri $uri/ /index.html;
# }

cd ..
```

### 🔍 Step 9: Health Checks and Verification

```bash
# Run the deployment health check
chmod +x deployment-health-check.sh
./deployment-health-check.sh

# Check individual services
echo "=== Service Status ==="
docker-compose -f docker-compose.production.yml ps

echo "=== Backend Health ==="
curl -s http://localhost:8000/health | jq .

echo "=== Beta Service Health ==="
curl -s http://localhost:8000/beta/health | jq .

echo "=== Database Connection ==="
docker-compose -f docker-compose.production.yml exec mysql mysql -u lawvriksh_user -pSahil123 -e "SELECT COUNT(*) as user_count FROM lawvriksh_referral.users;"

echo "=== Nginx Status ==="
sudo systemctl status nginx

echo "=== Check Logs ==="
echo "Backend logs:"
docker-compose -f docker-compose.production.yml logs --tail=20 backend

echo "MySQL logs:"
docker-compose -f docker-compose.production.yml logs --tail=20 mysql
```

### 🔧 Step 10: Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

### 📊 Step 11: Monitoring and Maintenance

```bash
# Create systemd service for auto-restart
sudo tee /etc/systemd/system/lawvriksh.service << 'EOF'
[Unit]
Description=LawVriksh Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/lawvriksh
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable lawvriksh.service
sudo systemctl start lawvriksh.service
```

### 🚨 Step 12: Troubleshooting

```bash
# Common troubleshooting commands

# Check all container logs
docker-compose -f docker-compose.production.yml logs

# Check specific service logs
docker-compose -f docker-compose.production.yml logs backend
docker-compose -f docker-compose.production.yml logs mysql

# Restart services
docker-compose -f docker-compose.production.yml restart

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
docker ps

# Access backend container
docker-compose -f docker-compose.production.yml exec backend bash

# Access MySQL container
docker-compose -f docker-compose.production.yml exec mysql mysql -u root -pSahil123
```

### 🎯 Step 13: Testing the Deployment

```bash
# Test beta user registration
curl -X POST http://localhost:8000/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# Test admin login
curl -X POST http://localhost:8000/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}'

# Test frontend access
curl -I http://localhost/

# Test API through Nginx
curl -s http://localhost/api/health
```

### 📝 Step 14: Production Checklist

- [ ] All services are running (`docker-compose ps`)
- [ ] Database is accessible and populated
- [ ] Admin user is created and can login
- [ ] Beta registration works
- [ ] Frontend loads correctly
- [ ] API endpoints respond through Nginx
- [ ] SSL certificate is installed (if using HTTPS)
- [ ] Firewall is configured
- [ ] Monitoring is set up
- [ ] Backups are configured
- [ ] Domain DNS is pointing to server

### 🔄 Step 15: Backup Strategy

```bash
# Create backup script
sudo tee /opt/lawvriksh/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/lawvriksh/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker-compose -f /opt/lawvriksh/docker-compose.production.yml exec -T mysql mysqldump -u root -pSahil123 lawvriksh_referral > $BACKUP_DIR/db_backup_$DATE.sql

# Application files backup
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz -C /opt/lawvriksh --exclude=backups --exclude=logs .

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/lawvriksh/backup.sh

# Add to crontab for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/lawvriksh/backup.sh") | crontab -
```

## 🎉 Deployment Complete!

Your LawVriksh platform should now be running on Ubuntu with:

- **Backend API**: `https://lawvriksh.com/api/`
- **Frontend**: `https://lawvriksh.com/`
- **Admin Panel**: `https://lawvriksh.com/admin/`
- **API Documentation**: `https://lawvriksh.com/api/docs`

### 📞 Support

If you encounter any issues during deployment, check:

1. Service logs: `docker-compose -f docker-compose.production.yml logs`
2. System resources: `htop` or `free -h`
3. Network connectivity: `netstat -tlnp`
4. Firewall rules: `sudo ufw status`

The platform is now ready for production use with proper monitoring, backups, and security configurations.
```
