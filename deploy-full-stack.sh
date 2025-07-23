#!/bin/bash

# =============================================================================
# LawVriksh Full Stack Production Deployment Script
# =============================================================================
# Complete deployment for Ubuntu 24.04 VPS (8GB RAM)
# Deploys: Frontend (React) + Backend (FastAPI) + MySQL + Nginx + SSL
# Domain: lawvriksh.com (frontend) + lawvriksh.com/api (backend)
# 
# Usage: chmod +x deploy-full-stack.sh && ./deploy-full-stack.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
DOMAIN="lawvriksh.com"
PROJECT_NAME="lawvriksh"
MYSQL_PORT="3307"
BACKUP_EMAIL="sahilsaurav2507@gmail.com"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
        error "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        warning "This script is optimized for Ubuntu 24.04"
        warning "Continuing anyway, but some steps might fail"
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common
    success "System updated successfully"
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        success "Docker already installed"
        return
    fi
    
    log "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    success "Docker installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        success "Docker Compose already installed"
        return
    fi
    
    log "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    success "Docker Compose installed successfully"
}

# Install and configure Nginx
install_nginx() {
    if command -v nginx &> /dev/null; then
        success "Nginx already installed"
        return
    fi
    
    log "Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    success "Nginx installed and started"
}

# Install Certbot for SSL
install_certbot() {
    if command -v certbot &> /dev/null; then
        success "Certbot already installed"
        return
    fi
    
    log "Installing Certbot for SSL certificates..."
    sudo apt install -y certbot python3-certbot-nginx
    success "Certbot installed successfully"
}

# Setup firewall
setup_firewall() {
    log "Configuring UFW firewall..."
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    success "Firewall configured"
}

# Create project structure
create_project_structure() {
    log "Creating project structure..."
    
    # Create main project directory
    sudo mkdir -p /opt/$PROJECT_NAME
    sudo chown $USER:$USER /opt/$PROJECT_NAME
    cd /opt/$PROJECT_NAME
    
    # Copy application files
    if [[ -d "$OLDPWD" ]]; then
        cp -r $OLDPWD/* . 2>/dev/null || true
    fi
    
    # Create necessary directories
    mkdir -p {nginx,mysql-data,prometheus-data,grafana-data,backups,logs,cache,uploads}
    mkdir -p logs/{backend,mysql,nginx}
    
    success "Project structure created at /opt/$PROJECT_NAME"
}

# Setup environment variables
setup_environment() {
    log "Setting up production environment variables..."
    
    # Generate secure passwords if not provided
    MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(openssl rand -base64 32)}
    DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}
    JWT_SECRET_KEY=${JWT_SECRET_KEY:-$(openssl rand -base64 64)}
    REDIS_PASSWORD=${REDIS_PASSWORD:-$(openssl rand -base64 32)}
    RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-$(openssl rand -base64 32)}
    
    # Create production environment file
    cat > .env.production << EOF
# =============================================================================
# LawVriksh Production Environment Configuration
# =============================================================================

# Domain Configuration
DOMAIN=$DOMAIN
API_BASE_URL=https://$DOMAIN/api
FRONTEND_URL=https://$DOMAIN

# Database Configuration
DB_NAME=lawvriksh_referral
DB_USER=lawvriksh_user
DB_PASSWORD=$DB_PASSWORD
DB_HOST=mysql
DB_PORT=3306
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

# Security Configuration
JWT_SECRET_KEY=$JWT_SECRET_KEY

# Cache Configuration
REDIS_PASSWORD=$REDIS_PASSWORD

# Message Queue Configuration
RABBITMQ_USER=lawvriksh_mq
RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD

# Email Configuration (Update with your SMTP settings)
EMAIL_FROM=info@$DOMAIN
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=info@$DOMAIN
SMTP_PASSWORD=Lawvriksh@123

# Admin Configuration
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123

# Application Settings
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO
CACHE_DIR=/app/cache

# Backup Configuration
BACKUP_EMAIL=$BACKUP_EMAIL
EOF
    
    # Create symlink for docker-compose to use
    ln -sf .env.production .env
    
    chmod 600 .env.production .env
    success "Environment configuration created"
}

# Configure Nginx for lawvriksh.com
configure_nginx() {
    log "Configuring Nginx for $DOMAIN..."
    
    sudo tee /etc/nginx/sites-available/$PROJECT_NAME > /dev/null << 'EOF'
# LawVriksh Nginx Configuration
# Frontend: lawvriksh.com
# Backend API: lawvriksh.com/api

server {
    listen 80;
    listen [::]:80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # SSL Configuration (will be configured by Certbot)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Backend API - lawvriksh.com/api
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # API specific settings
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        
        # CORS headers (backup, should be handled by FastAPI)
        add_header Access-Control-Allow-Origin "https://lawvriksh.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        add_header Access-Control-Expose-Headers "Content-Length,Content-Range" always;
    }
    
    # Frontend - lawvriksh.com (React SPA)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Handle React Router (SPA routing)
        try_files $uri $uri/ @fallback;
    }
    
    # Fallback for React Router
    location @fallback {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoints
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
    
    location /api/health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
    
    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    sudo nginx -t
    
    # Reload Nginx
    sudo systemctl reload nginx
    
    success "Nginx configured for $DOMAIN"
}

# Main deployment function
main() {
    log "Starting LawVriksh Full Stack Deployment"
    log "========================================"
    log "Domain: $DOMAIN"
    log "Frontend: https://$DOMAIN"
    log "Backend API: https://$DOMAIN/api"
    log "========================================"
    
    check_root
    check_ubuntu_version
    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    setup_firewall
    create_project_structure
    setup_environment
    configure_nginx
    
    success "========================================"
    success "Phase 1: System Setup Completed!"
    success "========================================"
    
    info "Next steps:"
    echo "1. Verify your domain DNS points to this server"
    echo "2. Run: ./deploy-services.sh (to deploy the application)"
    echo "3. Run: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN (for SSL)"
    
    success "Deployment script completed successfully!"
}

# Run main function
main "$@"
