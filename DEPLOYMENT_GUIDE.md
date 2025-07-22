# 🚀 Lawvriksh Backend Deployment Guide

## Complete Production Deployment on Ubuntu 24.04 + Docker

This guide provides step-by-step instructions to deploy the Lawvriksh FastAPI backend on Ubuntu 24.04 using Docker, with the domain configuration:
- **Frontend**: `https://www.lawvriksh.com`
- **Backend API**: `https://www.lawvriksh.com/api/`

## 📋 Prerequisites

- Ubuntu 24.04 VPS with root/sudo access
- Domain name (`www.lawvriksh.com`) pointing to your server IP
- At least 2GB RAM and 20GB disk space
- SMTP credentials for email functionality

## 🎯 Quick Deployment (3 Commands)

```bash
# 1. Initial system setup and Docker installation
chmod +x deploy.sh && ./deploy.sh

# 2. Production environment configuration
chmod +x setup-production.sh && ./setup-production.sh

# 3. Start all services
chmod +x start-services.sh && ./start-services.sh
```

## 📁 Deployment Files Overview

### Core Deployment Scripts
- `deploy.sh` - System setup, Docker installation, basic configuration
- `setup-production.sh` - Production environment, Nginx, SSL certificates
- `start-services.sh` - Start all services and verify deployment

### Docker Configuration
- `docker-compose.production.yml` - Production Docker Compose configuration
- `Dockerfile.production` - Optimized production Docker image
- `requirements.production.txt` - Production Python dependencies

### Utilities
- `backup.sh` - Database and files backup script
- `health-check.sh` - Comprehensive health monitoring
- `.env.production.example` - Environment variables template

## 🔧 Detailed Deployment Steps

### Step 1: Server Preparation

```bash
# Connect to your Ubuntu 24.04 VPS
ssh root@your-server-ip

# Create deployment user (recommended)
adduser lawvriksh
usermod -aG sudo lawvriksh
su - lawvriksh

# Clone your repository
git clone https://github.com/your-repo/lawvriksh-backend.git
cd lawvriksh-backend/backend
```

### Step 2: System Setup

```bash
# Run the deployment script
chmod +x deploy.sh
./deploy.sh
```

**What this script does:**
- Updates Ubuntu packages
- Installs Docker and Docker Compose
- Installs Nginx and Certbot
- Creates project directory structure
- Generates secure passwords and JWT keys
- Sets up basic security configurations

### Step 3: Production Configuration

```bash
# Configure production environment
chmod +x setup-production.sh
./setup-production.sh
```

**During this step, you'll be prompted for:**
- Domain name (default: www.lawvriksh.com)
- Email configuration (SMTP settings)
- SSL certificate setup

**What this script does:**
- Creates production environment variables
- Configures Nginx with SSL termination
- Sets up Let's Encrypt SSL certificates
- Configures log rotation
- Sets up basic monitoring

### Step 4: Start Services

```bash
# Start all production services
chmod +x start-services.sh
./start-services.sh
```

**What this script does:**
- Initializes the database
- Starts all Docker containers
- Verifies service health
- Sets up systemd service for auto-start
- Shows service URLs and status

## 🏗️ Architecture Overview

### Services Stack
```
┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │   Let's Encrypt │
│  (Reverse Proxy)│    │  (SSL Certs)    │
└─────────┬───────┘    └─────────────────┘
          │
          ▼
┌─────────────────┐    ┌─────────────────┐
│   FastAPI       │    │     Celery      │
│   Backend       │    │   Workers       │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          ▼                      ▼
┌─────────────────┐    ┌─────────────────┐
│     MySQL       │    │    RabbitMQ     │
│   Database      │    │ Message Queue   │
└─────────────────┘    └─────────────────┘
          │                      │
          ▼                      ▼
┌─────────────────┐    ┌─────────────────┐
│     Redis       │    │   Monitoring    │
│     Cache       │    │   & Logging     │
└─────────────────┘    └─────────────────┘
```

### Network Configuration
- **Port 80**: HTTP → Redirects to HTTPS
- **Port 443**: HTTPS → Nginx → FastAPI (8000)
- **Port 8000**: FastAPI (localhost only)
- **Port 3306**: MySQL (localhost only)
- **Port 5672**: RabbitMQ (localhost only)
- **Port 6379**: Redis (localhost only)

## 🔒 Security Features

### SSL/TLS Configuration
- Automatic SSL certificate generation with Let's Encrypt
- TLS 1.2+ only with secure cipher suites
- HSTS headers for enhanced security
- Automatic certificate renewal

### Application Security
- JWT-based authentication with secure secret keys
- Rate limiting (10 requests/second per IP)
- CORS configuration for frontend domain
- Input validation with Pydantic
- SQL injection protection with SQLAlchemy ORM

### Infrastructure Security
- Non-root Docker containers
- Database and services bound to localhost only
- Secure password generation for all services
- Log rotation and monitoring

## 📊 Monitoring & Maintenance

### Health Monitoring
```bash
# Check all services health
./health-check.sh

# Generate detailed health report
./health-check.sh --report

# Check specific components
./health-check.sh --docker
./health-check.sh --api
./health-check.sh --database
```

### Service Management
```bash
# View logs
./start-services.sh logs

# Stop services
./start-services.sh stop

# Restart services
./start-services.sh restart

# Check status
./start-services.sh status
```

### Backup & Recovery
```bash
# Full backup (database + files + volumes)
./backup.sh

# Database only
./backup.sh database

# Files only
./backup.sh files
```

## 🌐 DNS Configuration

Point your domain to your server:

```
Type: A
Name: www.lawvriksh.com
Value: YOUR_SERVER_IP
TTL: 300

Type: A  
Name: lawvriksh.com
Value: YOUR_SERVER_IP
TTL: 300
```

## 🔧 Environment Variables

Key production environment variables in `.env.production`:

```bash
# Domain
DOMAIN=www.lawvriksh.com
API_BASE_URL=https://www.lawvriksh.com/api
FRONTEND_URL=https://www.lawvriksh.com

# Database
DB_NAME=lawvriksh_production
DB_USER=lawvriksh_user
DB_PASSWORD=auto_generated_secure_password

# Security
JWT_SECRET_KEY=auto_generated_64_char_key

# Email
EMAIL_FROM=info@lawvriksh.com
SMTP_HOST=smtp.gmail.com
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
```

## 📈 Performance Optimization

### Production Settings
- **Gunicorn**: 4 worker processes with Uvicorn workers
- **Database**: Connection pooling with SQLAlchemy
- **Caching**: Redis for session storage and API caching
- **Static Files**: Nginx serves static content directly
- **Compression**: Gzip compression enabled

### Resource Requirements
- **Minimum**: 2GB RAM, 2 CPU cores, 20GB disk
- **Recommended**: 4GB RAM, 4 CPU cores, 50GB disk
- **High Traffic**: 8GB RAM, 8 CPU cores, 100GB disk

## 🚨 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   ```bash
   sudo certbot renew --dry-run
   sudo systemctl reload nginx
   ```

2. **Database Connection Issues**
   ```bash
   docker-compose -f docker-compose.production.yml logs mysql
   docker-compose -f docker-compose.production.yml restart mysql
   ```

3. **API Not Responding**
   ```bash
   docker-compose -f docker-compose.production.yml logs backend
   docker-compose -f docker-compose.production.yml restart backend
   ```

4. **High Memory Usage**
   ```bash
   docker stats
   ./health-check.sh --performance
   ```

### Log Locations
- **Application Logs**: `./logs/backend/`
- **Database Logs**: `./logs/mysql/`
- **Nginx Logs**: `/var/log/nginx/`
- **System Logs**: `/var/log/syslog`

## 🎉 Post-Deployment Verification

After successful deployment, verify:

1. **API Health**: `https://www.lawvriksh.com/api/health`
2. **API Documentation**: `https://www.lawvriksh.com/api/docs`
3. **SSL Certificate**: Check browser for valid SSL
4. **Database**: Run health check script
5. **Email**: Test user registration flow

## 📞 Support

For deployment issues:
1. Check logs: `./start-services.sh logs`
2. Run health check: `./health-check.sh --report`
3. Review troubleshooting section above
4. Check GitHub issues or documentation

---

**🎯 Your Lawvriksh backend is now production-ready on Ubuntu 24.04 with Docker!**
