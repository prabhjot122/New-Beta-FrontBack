# 🚀 LawVriksh Complete Deployment Guide

## Overview
This guide will deploy your LawVriksh platform on Ubuntu 24.04 with Docker, including:
- Backend API (FastAPI)
- Frontend (React/Vite)
- Database (MySQL 8.0)
- Reverse Proxy (Nginx)
- SSL Certificate (Let's Encrypt)
- Monitoring & Health Checks

---

## 📋 Prerequisites

### Server Requirements
- **OS**: Ubuntu 24.04 LTS
- **RAM**: 8GB minimum
- **Storage**: 100GB minimum
- **Domain**: lawvriksh.com pointed to your server IP
- **Access**: Root or sudo privileges

### Before You Start
1. Ensure your domain DNS is pointing to your server IP
2. Have SSH access to your Ubuntu server
3. Firewall ports 22, 80, 443 should be accessible

---

## 🔧 Step 1: Server Preparation

### Connect to Your Server
```bash
ssh your-username@your-server-ip
```

### Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip software-properties-common
```

### Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### Install Additional Tools
```bash
sudo apt install -y nginx certbot python3-certbot-nginx jq htop
```

---

## 📁 Step 2: Project Setup

### Create Project Directory
```bash
sudo mkdir -p /opt/lawvriksh
sudo chown $USER:$USER /opt/lawvriksh
cd /opt/lawvriksh
```

### Upload Your Project Files
You have several options:

**Option A: Using Git (if your code is in a repository)**
```bash
git clone https://github.com/your-username/lawvriksh.git .
```

**Option B: Using SCP from your local machine**
```bash
# From your local machine (where your project is)
scp -r /path/to/your/project/* username@server-ip:/opt/lawvriksh/
```

**Option C: Using rsync**
```bash
# From your local machine
rsync -avz --progress /path/to/your/project/ username@server-ip:/opt/lawvriksh/
```

### Create Directory Structure
```bash
mkdir -p logs/{mysql,backend,celery,celery-beat,rabbitmq,redis}
mkdir -p cache uploads backups
```

---

## 🐳 Step 3: Docker Deployment

### Verify Your Files
Make sure these files exist in `/opt/lawvriksh/`:
```bash
ls -la
# Should show:
# - docker-compose.production.yml
# - .env
# - app/ (directory)
# - Frontend/ (directory)
# - requirements.txt
# - lawdata.sql
```

### Start Services
```bash
# Apply docker group membership
newgrp docker

# Start all services
docker-compose -f docker-compose.production.yml up -d --build

# Check status
docker-compose -f docker-compose.production.yml ps
```

### Wait for Services
```bash
echo "Waiting for services to start..."
sleep 60

# Check logs if needed
docker-compose -f docker-compose.production.yml logs backend
```

---

## 🗄️ Step 4: Database Setup

### Wait for MySQL
```bash
echo "Waiting for MySQL to be ready..."
until docker-compose -f docker-compose.production.yml exec mysql mysqladmin ping -h localhost -u root -pSahil123 --silent; do
    echo "Waiting for MySQL..."
    sleep 5
done
```

### Initialize Database
```bash
# Create database and user
docker-compose -f docker-compose.production.yml exec mysql mysql -u root -pSahil123 -e "
CREATE DATABASE IF NOT EXISTS lawvriksh_referral CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'lawvriksh_user'@'%' IDENTIFIED BY 'Sahil123';
GRANT ALL PRIVILEGES ON lawvriksh_referral.* TO 'lawvriksh_user'@'%';
FLUSH PRIVILEGES;
"

# Import schema
docker-compose -f docker-compose.production.yml exec -T mysql mysql -u root -pSahil123 lawvriksh_referral < lawdata.sql

# Setup admin user
docker-compose -f docker-compose.production.yml exec backend python setup_admin_corrected.py
```

### Verify Database
```bash
docker-compose -f docker-compose.production.yml exec mysql mysql -u lawvriksh_user -pSahil123 -e "
USE lawvriksh_referral;
SELECT COUNT(*) as total_users FROM users;
SELECT name, email, is_admin FROM users WHERE is_admin = 1;
"
```

---

## 🌐 Step 5: Nginx Configuration

### Create Nginx Config
```bash
sudo tee /etc/nginx/sites-available/lawvriksh.com << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # Redirect HTTP to HTTPS (will be enabled after SSL setup)
    # return 301 https://$server_name$request_uri;
    
    # Frontend (React app)
    location / {
        root /var/www/lawvriksh;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
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
}
EOF
```

### Enable Site
```bash
sudo ln -sf /etc/nginx/sites-available/lawvriksh.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

## 🏗️ Step 6: Frontend Build & Deploy

### Install Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Build Frontend
```bash
cd /opt/lawvriksh/Frontend

# Install dependencies
npm install

# Build for production
npm run build

# Deploy to Nginx
sudo mkdir -p /var/www/lawvriksh
sudo cp -r dist/* /var/www/lawvriksh/
sudo chown -R www-data:www-data /var/www/lawvriksh
```

---

## 🔒 Step 7: SSL Certificate

### Install SSL Certificate
```bash
sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com
```

### Enable Auto-renewal
```bash
sudo systemctl enable certbot.timer
sudo certbot renew --dry-run
```

---

## 🔥 Step 8: Firewall Configuration

### Configure UFW
```bash
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

---

## 🔍 Step 9: Health Checks & Testing

### Run Health Checks
```bash
cd /opt/lawvriksh

# Check Docker services
docker-compose -f docker-compose.production.yml ps

# Test backend health
curl -s http://localhost:8000/health | jq .

# Test API through Nginx
curl -s https://lawvriksh.com/api/health | jq .

# Test beta registration
curl -X POST https://lawvriksh.com/api/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}' | jq .

# Test admin login
curl -X POST https://lawvriksh.com/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' | jq .
```

### Run Comprehensive Health Check
```bash
./deployment-health-check.sh
```

---

## 📊 Step 10: Monitoring & Maintenance

### Create Systemd Service
```bash
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

### Setup Log Rotation
```bash
sudo tee /etc/logrotate.d/lawvriksh << 'EOF'
/opt/lawvriksh/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /opt/lawvriksh/docker-compose.production.yml restart backend
    endscript
}
EOF
```

### Create Backup Script
```bash
sudo tee /opt/lawvriksh/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/lawvriksh/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker-compose -f /opt/lawvriksh/docker-compose.production.yml exec -T mysql mysqldump -u root -pSahil123 lawvriksh_referral > $BACKUP_DIR/db_backup_$DATE.sql

# Application files backup
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz -C /opt/lawvriksh --exclude=backups --exclude=logs .

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/lawvriksh/backup.sh

# Add to crontab for daily backups at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/lawvriksh/backup.sh") | crontab -
```

---

## 🎉 Step 11: Deployment Complete!

### Verify Everything is Working

Your LawVriksh platform should now be accessible at:

- **🌐 Frontend**: https://lawvriksh.com/
- **🔌 Backend API**: https://lawvriksh.com/api/
- **👑 Admin Panel**: https://lawvriksh.com/admin/
- **📚 API Documentation**: https://lawvriksh.com/api/docs
- **💓 Health Check**: https://lawvriksh.com/api/health

### Final Verification Checklist

Run these commands to verify everything:

```bash
# 1. Check all services are running
docker-compose -f docker-compose.production.yml ps

# 2. Test all endpoints
curl -s https://lawvriksh.com/api/health
curl -s https://lawvriksh.com/api/beta/health
curl -s https://lawvriksh.com/api/docs

# 3. Check SSL certificate
curl -I https://lawvriksh.com

# 4. Verify database
docker-compose -f docker-compose.production.yml exec mysql mysql -u lawvriksh_user -pSahil123 -e "SELECT COUNT(*) FROM lawvriksh_referral.users;"

# 5. Check logs
docker-compose -f docker-compose.production.yml logs --tail=20 backend
```

---

## 🚨 Troubleshooting

### Common Issues & Solutions

**Issue: Services not starting**
```bash
# Check logs
docker-compose -f docker-compose.production.yml logs

# Restart services
docker-compose -f docker-compose.production.yml restart
```

**Issue: Database connection failed**
```bash
# Check MySQL status
docker-compose -f docker-compose.production.yml exec mysql mysqladmin ping -h localhost -u root -pSahil123

# Reset database
docker-compose -f docker-compose.production.yml restart mysql
```

**Issue: Nginx not serving content**
```bash
# Check Nginx status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

**Issue: SSL certificate problems**
```bash
# Renew certificate
sudo certbot renew

# Check certificate status
sudo certbot certificates
```

### Useful Management Commands

```bash
# View all logs
docker-compose -f docker-compose.production.yml logs -f

# Restart specific service
docker-compose -f docker-compose.production.yml restart backend

# Update application (after code changes)
docker-compose -f docker-compose.production.yml up -d --build

# Check system resources
htop
df -h
free -h

# Monitor real-time logs
tail -f logs/backend/*.log
```

---

## 📈 Performance Optimization

### Enable Gzip Compression
Add to your Nginx config:
```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
```

### Database Optimization
```bash
# Optimize MySQL configuration
docker-compose -f docker-compose.production.yml exec mysql mysql -u root -pSahil123 -e "
SET GLOBAL innodb_buffer_pool_size = 1073741824;
SET GLOBAL max_connections = 200;
"
```

---

## 🔐 Security Hardening

### Additional Security Measures
```bash
# Disable root SSH login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban

# Setup automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 📞 Support & Maintenance

### Regular Maintenance Tasks

**Daily:**
- Check service status: `docker-compose ps`
- Review logs: `docker-compose logs --tail=50`

**Weekly:**
- Update system: `sudo apt update && sudo apt upgrade`
- Check disk space: `df -h`
- Review backup status

**Monthly:**
- Rotate logs manually if needed
- Review SSL certificate expiry
- Update Docker images: `docker-compose pull && docker-compose up -d`

### Getting Help

If you encounter issues:

1. **Check the logs first**: `docker-compose logs service-name`
2. **Verify configuration**: Ensure `.env` file is correct
3. **Test connectivity**: Use `curl` commands to test endpoints
4. **Check resources**: Ensure sufficient disk space and memory
5. **Review firewall**: Verify ports are open with `sudo ufw status`

---

## 🎯 Success!

Your LawVriksh platform is now fully deployed and production-ready!

The platform includes:
- ✅ High-availability architecture
- ✅ SSL encryption
- ✅ Automated backups
- ✅ Health monitoring
- ✅ Security hardening
- ✅ Performance optimization

Your users can now:
- Register as beta users at https://lawvriksh.com
- Access the admin panel at https://lawvriksh.com/admin
- Use the API at https://lawvriksh.com/api

**Admin Credentials:**
- Email: sahilsaurav2507@gmail.com
- Password: Sahil@123

Enjoy your fully deployed LawVriksh platform! 🚀
```
