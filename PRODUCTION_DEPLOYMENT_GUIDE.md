# 🚀 LawVriksh Production Deployment Guide

## 📋 Pre-Deployment Checklist

### ✅ Server Requirements
- **OS**: Ubuntu 24.04 LTS
- **RAM**: 8GB (minimum)
- **Storage**: 100GB SSD
- **CPU**: 2+ cores
- **Network**: Public IP with domain pointing to server

### ✅ Domain & SSL
- Domain: `lawvriksh.com` configured and pointing to server
- SSL certificates already enabled on domain
- DNS propagation completed

### ✅ Credentials Ready
- Hostinger email credentials
- Database passwords
- Admin user credentials

## 🚀 One-Command Deployment

### Step 1: Download and Prepare
```bash
# Clone the repository
git clone <your-repo-url>
cd New-Beta-FrontBack

# Make deployment script executable
chmod +x deploy-production.sh
```

### Step 2: Update Configuration
```bash
# Edit production environment file
nano .env.production

# Update these critical values:
# - JWT_SECRET_KEY (generate secure key)
# - SMTP_PASSWORD (your Hostinger email password)
# - DB_PASSWORD (if different from default)
```

### Step 3: Run Deployment
```bash
# Execute the deployment script
./deploy-production.sh
```

### Step 4: Complete Setup (if prompted)
```bash
# If the script creates a second phase, run:
./configure-services.sh
```

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                Ubuntu 24.04 VPS (8GB RAM)                  │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────────────────────────────┐   │
│  │    Nginx    │  │         Docker Services             │   │
│  │   (SSL)     │  │                                     │   │
│  │             │  │  ┌─────────┐  ┌─────────┐  ┌─────┐ │   │
│  │lawvriksh.com│──┼──│Frontend │  │Backend  │  │MySQL│ │   │
│  │/api/        │  │  │(1GB RAM)│  │(2GB RAM)│  │(2GB)│ │   │
│  │             │  │  └─────────┘  └─────────┘  └─────┘ │   │
│  └─────────────┘  │                                     │   │
│                   │  ┌─────────┐  ┌─────────┐  ┌─────┐ │   │
│  ┌─────────────┐  │  │Prometheus│  │Grafana  │  │Redis│ │   │
│  │  Security   │  │  │(512MB)  │  │(512MB)  │  │(256)│ │   │
│  │ UFW+Fail2Ban│  │  └─────────┘  └─────────┘  └─────┘ │   │
│  └─────────────┘  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Resource Allocation

| Service    | RAM   | CPU  | Port | Purpose                    |
|------------|-------|------|------|----------------------------|
| MySQL      | 2GB   | 1.0  | 3307 | Database (custom port)     |
| Backend    | 2GB   | 2.0  | 8000 | FastAPI application        |
| Frontend   | 1GB   | 1.0  | 3000 | React application          |
| Prometheus | 512MB | 0.5  | 9090 | Monitoring                 |
| Grafana    | 512MB | 0.5  | 3001 | Dashboard                  |
| Redis      | 256MB | 0.2  | 6379 | Cache                      |
| **Total**  | **6.5GB** | **5.2** | - | **1.5GB reserved for system** |

## 🔧 What the Deployment Does

### 1. System Setup
- ✅ Updates Ubuntu packages
- ✅ Installs Docker & Docker Compose
- ✅ Configures UFW firewall
- ✅ Sets up Fail2Ban security
- ✅ Installs and configures Nginx

### 2. Application Deployment
- ✅ Builds optimized Docker containers
- ✅ Configures MySQL on port 3307
- ✅ Sets up Redis caching
- ✅ Deploys FastAPI backend
- ✅ Deploys React frontend
- ✅ Configures SSL/HTTPS routing

### 3. Monitoring & Backup
- ✅ Sets up Prometheus monitoring
- ✅ Configures Grafana dashboards
- ✅ Schedules daily database backups (2 AM)
- ✅ Email notifications to sahilsaurav2507@gmail.com
- ✅ 4-day backup retention

### 4. Security Features
- ✅ Firewall rules (ports 22, 80, 443)
- ✅ Fail2Ban intrusion prevention
- ✅ MySQL isolated to localhost:3307
- ✅ JWT token authentication
- ✅ HTTPS enforcement
- ✅ Security headers

## 🌐 Service URLs

After deployment, access your services at:

- **Frontend**: https://lawvriksh.com
- **Backend API**: https://lawvriksh.com/api/
- **API Documentation**: https://lawvriksh.com/api/docs
- **Grafana Dashboard**: http://your-server-ip:3001
- **Prometheus**: http://your-server-ip:9090

## 👤 Admin Access

- **Email**: sahilsaurav2507@gmail.com
- **Password**: Sahil@123
- **Grafana**: admin / admin123

## 📧 Backup System

- **Schedule**: Daily at 2:00 AM IST
- **Retention**: 4 days
- **Email**: sahilsaurav2507@gmail.com
- **Format**: Compressed SQL dump
- **Location**: `/opt/lawvriksh/backups/`

## 🔧 Management Commands

```bash
# View all services
docker-compose ps

# View logs
docker-compose logs -f [service_name]

# Restart a service
docker-compose restart [service_name]

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Update application
git pull
docker-compose build --no-cache
docker-compose up -d
```

## 🚨 Troubleshooting

### Service Not Starting
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs [service_name]

# Restart service
docker-compose restart [service_name]
```

### Database Connection Issues
```bash
# Check MySQL logs
docker-compose logs mysql

# Test database connection
docker-compose exec mysql mysql -u root -p
```

### SSL/Domain Issues
```bash
# Check Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
```

## 📞 Support

For deployment issues:
1. Check service logs: `docker-compose logs -f`
2. Verify environment variables in `.env.production`
3. Ensure domain DNS is properly configured
4. Check firewall settings: `sudo ufw status`

---

**Deployment Time**: ~15-20 minutes
**Zero Downtime Updates**: Supported
**High Availability**: ✅ Configured
**Production Ready**: ✅ Optimized
