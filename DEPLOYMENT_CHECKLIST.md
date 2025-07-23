# 🚀 LawVriksh Deployment Checklist

## Quick Deployment Guide for Ubuntu 24.04

### ✅ Pre-Deployment Checklist

- [ ] Ubuntu 24.04 LTS server ready
- [ ] Domain `lawvriksh.com` pointing to server IP
- [ ] SSH access to server
- [ ] 8GB RAM, 100GB storage available
- [ ] Ports 22, 80, 443 open in firewall

---

## 🔧 Step-by-Step Deployment

### 1. Server Preparation
```bash
# Connect to server
ssh username@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip jq htop
```

### 2. Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

### 3. Install Additional Tools
```bash
sudo apt install -y nginx certbot python3-certbot-nginx nodejs npm
```

### 4. Setup Project
```bash
# Create project directory
sudo mkdir -p /opt/lawvriksh
sudo chown $USER:$USER /opt/lawvriksh
cd /opt/lawvriksh

# Upload your project files here
# Make sure you have:
# - docker-compose.production.yml
# - .env (updated)
# - app/ directory
# - Frontend/ directory
# - requirements.txt
# - lawdata.sql

# Create directories
mkdir -p logs/{mysql,backend,celery,rabbitmq,redis}
mkdir -p cache uploads backups
```

### 5. Start Services
```bash
# Start Docker services
newgrp docker
docker-compose -f docker-compose.production.yml up -d --build

# Wait for services
sleep 60

# Check status
docker-compose -f docker-compose.production.yml ps
```

### 6. Setup Database
```bash
# Wait for MySQL
until docker-compose -f docker-compose.production.yml exec mysql mysqladmin ping -h localhost -u root -pSahil123 --silent; do
    echo "Waiting for MySQL..."
    sleep 5
done

# Create database
docker-compose -f docker-compose.production.yml exec mysql mysql -u root -pSahil123 -e "
CREATE DATABASE IF NOT EXISTS lawvriksh_referral CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'lawvriksh_user'@'%' IDENTIFIED BY 'Sahil123';
GRANT ALL PRIVILEGES ON lawvriksh_referral.* TO 'lawvriksh_user'@'%';
FLUSH PRIVILEGES;
"

# Import schema
docker-compose -f docker-compose.production.yml exec -T mysql mysql -u root -pSahil123 lawvriksh_referral < lawdata.sql

# Setup admin
docker-compose -f docker-compose.production.yml exec backend python setup_admin_corrected.py
```

### 7. Configure Nginx
```bash
# Create Nginx config
sudo tee /etc/nginx/sites-available/lawvriksh.com << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    location / {
        root /var/www/lawvriksh;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        add_header Access-Control-Allow-Origin "https://lawvriksh.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/lawvriksh.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 8. Build Frontend
```bash
cd /opt/lawvriksh/Frontend
npm install
npm run build

# Deploy to Nginx
sudo mkdir -p /var/www/lawvriksh
sudo cp -r dist/* /var/www/lawvriksh/
sudo chown -R www-data:www-data /var/www/lawvriksh
cd ..
```

### 9. Configure Firewall
```bash
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 10. Setup SSL
```bash
sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com
```

---

## 🔍 Verification Tests

### Test Backend
```bash
curl -s http://localhost:8000/health | jq .
```

### Test API through Nginx
```bash
curl -s https://lawvriksh.com/api/health | jq .
```

### Test Beta Registration
```bash
curl -X POST https://lawvriksh.com/api/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}' | jq .
```

### Test Admin Login
```bash
curl -X POST https://lawvriksh.com/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' | jq .
```

---

## 📊 Final Verification

### ✅ Services Running
```bash
docker-compose -f docker-compose.production.yml ps
```

### ✅ All Endpoints Working
- [ ] https://lawvriksh.com/ (Frontend)
- [ ] https://lawvriksh.com/api/health (Backend Health)
- [ ] https://lawvriksh.com/api/docs (API Documentation)
- [ ] https://lawvriksh.com/admin/ (Admin Panel)

### ✅ Database Working
```bash
docker-compose -f docker-compose.production.yml exec mysql mysql -u lawvriksh_user -pSahil123 -e "SELECT COUNT(*) FROM lawvriksh_referral.users;"
```

### ✅ SSL Certificate Active
```bash
curl -I https://lawvriksh.com
```

---

## 🚨 Troubleshooting

### Services Not Starting
```bash
docker-compose -f docker-compose.production.yml logs
docker-compose -f docker-compose.production.yml restart
```

### Database Issues
```bash
docker-compose -f docker-compose.production.yml logs mysql
docker-compose -f docker-compose.production.yml restart mysql
```

### Nginx Issues
```bash
sudo systemctl status nginx
sudo nginx -t
sudo systemctl restart nginx
```

### SSL Issues
```bash
sudo certbot renew
sudo certbot certificates
```

---

## 🔧 Management Commands

### View Logs
```bash
docker-compose -f docker-compose.production.yml logs -f backend
docker-compose -f docker-compose.production.yml logs -f mysql
```

### Restart Services
```bash
docker-compose -f docker-compose.production.yml restart
docker-compose -f docker-compose.production.yml restart backend
```

### Update Application
```bash
docker-compose -f docker-compose.production.yml up -d --build
```

### Backup Database
```bash
docker-compose -f docker-compose.production.yml exec -T mysql mysqldump -u root -pSahil123 lawvriksh_referral > backup_$(date +%Y%m%d).sql
```

---

## 🎉 Success!

If all checks pass, your LawVriksh platform is now live at:

- **🌐 Frontend**: https://lawvriksh.com/
- **🔌 API**: https://lawvriksh.com/api/
- **👑 Admin**: https://lawvriksh.com/admin/
- **📚 Docs**: https://lawvriksh.com/api/docs

**Admin Credentials:**
- Email: sahilsaurav2507@gmail.com
- Password: Sahil@123

Your platform is production-ready! 🚀
