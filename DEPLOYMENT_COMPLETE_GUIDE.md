# 🚀 Complete LawVriksh Deployment Guide

## Overview

This guide provides complete deployment instructions for the LawVriksh platform on Ubuntu 24.04 with proper admin setup and nginx configuration.

**Domain Configuration:**
- **Frontend**: `https://lawvriksh.com`
- **Backend API**: `https://lawvriksh.com/api`

## 📋 Prerequisites

- Ubuntu 24.04 VPS with 8GB RAM and 100GB storage
- Domain `lawvriksh.com` pointing to your server IP
- Root or sudo access to the server
- SMTP credentials for email functionality

## 🎯 Quick Deployment (3 Commands)

```bash
# 1. System setup and nginx configuration
chmod +x deploy-full-stack.sh && ./deploy-full-stack.sh

# 2. Deploy application services
chmod +x deploy-services.sh && ./deploy-services.sh

# 3. Setup SSL certificate
sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com
```

## 📁 Deployment Files

### Core Scripts
- `deploy-full-stack.sh` - System setup, Docker, Nginx, firewall
- `deploy-services.sh` - Application deployment and admin setup
- `setup_admin.py` - Admin user creation from .env
- `verify_admin.py` - Admin credentials verification

### Configuration Files
- `docker-compose.yml` - Full stack Docker configuration
- `Dockerfile.production` - Backend production image
- `Dockerfile.frontend` - Frontend production image
- `.env.production` - Production environment variables

## 🔧 Detailed Steps

### Step 1: Server Preparation

```bash
# Connect to your Ubuntu server
ssh root@your-server-ip

# Create deployment user (recommended)
adduser lawvriksh
usermod -aG sudo lawvriksh
su - lawvriksh

# Clone your repository
git clone https://your-repo/lawvriksh.git
cd lawvriksh
```

### Step 2: System Setup

```bash
# Run full stack deployment
chmod +x deploy-full-stack.sh
./deploy-full-stack.sh
```

This script will:
- ✅ Install Docker and Docker Compose
- ✅ Configure UFW firewall
- ✅ Install and configure Nginx
- ✅ Create project structure at `/opt/lawvriksh`
- ✅ Generate secure environment variables
- ✅ Configure Nginx for `lawvriksh.com` and `lawvriksh.com/api`

### Step 3: Deploy Services

```bash
# Deploy application services
chmod +x deploy-services.sh
./deploy-services.sh
```

This script will:
- ✅ Create Docker Compose configuration
- ✅ Build and start all services (MySQL, Redis, Backend, Frontend)
- ✅ Initialize database with `lawdata.sql`
- ✅ Create admin user from environment variables
- ✅ Verify admin setup

### Step 4: SSL Certificate

```bash
# Setup SSL certificate with Certbot
sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com
```

## 🔐 Admin Credentials

The admin user is automatically created with these credentials:

```
📧 Email: sahilsaurav2507@gmail.com
🔑 Password: Sahil@123
```

These are loaded from the `.env` file and properly hashed in the database.

## 🌐 Nginx Configuration

The nginx configuration handles:

### Frontend (lawvriksh.com)
```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    # React Router SPA handling
    try_files $uri $uri/ @fallback;
}
```

### Backend API (lawvriksh.com/api)
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:8000/;
    # CORS headers
    add_header Access-Control-Allow-Origin "https://lawvriksh.com" always;
}
```

## 🐳 Docker Services

### Services Overview
- **MySQL 8.0**: Database on port 3307 (localhost only)
- **Redis 7**: Cache and session storage
- **FastAPI Backend**: API server on port 8000 (localhost only)
- **React Frontend**: Static files served on port 3000 (localhost only)

### Service Management
```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Restart a service
docker-compose restart backend

# Stop all services
docker-compose down

# Start all services
docker-compose up -d
```

## 🔍 Verification Steps

### 1. Check Services
```bash
# Check if all containers are running
docker-compose ps

# Check service health
curl http://localhost:8000/health
curl http://localhost:3000/health
```

### 2. Test URLs
- Frontend: `https://lawvriksh.com`
- Backend API: `https://lawvriksh.com/api/docs`
- Health Check: `https://lawvriksh.com/api/health`

### 3. Verify Admin Login
```bash
# Run admin verification script
docker-compose exec backend python verify_admin.py
```

## 🛠️ Troubleshooting

### Services Not Starting
```bash
# Check logs
docker-compose logs -f

# Rebuild services
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Admin Login Issues
```bash
# Reset admin user
docker-compose exec backend python setup_admin.py

# Verify admin setup
docker-compose exec backend python verify_admin.py
```

### Nginx Issues
```bash
# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
```

### SSL Certificate Issues
```bash
# Renew certificate
sudo certbot renew

# Test certificate
sudo certbot certificates
```

## 📊 Monitoring

### Log Locations
- Backend logs: `./logs/backend/`
- MySQL logs: `./logs/mysql/`
- Nginx logs: `/var/log/nginx/`

### Health Checks
- Backend: `https://lawvriksh.com/api/health`
- Frontend: `https://lawvriksh.com/health`

## 🔄 Updates and Maintenance

### Update Application
```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Database Backup
```bash
# Manual backup
docker-compose exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} lawvriksh_referral > backup.sql
```

## 🎉 Success Indicators

When deployment is successful, you should see:

1. ✅ All Docker containers running
2. ✅ Frontend accessible at `https://lawvriksh.com`
3. ✅ API docs at `https://lawvriksh.com/api/docs`
4. ✅ Admin login working with provided credentials
5. ✅ SSL certificate installed and working
6. ✅ All health checks passing

## 📞 Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify environment variables: `cat .env`
3. Test individual services: `curl http://localhost:8000/health`
4. Check nginx configuration: `sudo nginx -t`

---

**Note**: This deployment is optimized for production use with proper security, SSL, and monitoring configurations.
