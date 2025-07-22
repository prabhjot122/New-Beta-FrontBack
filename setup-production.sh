#!/bin/bash

# =============================================================================
# Lawvriksh Backend Production Setup Script
# =============================================================================
# This script sets up the production environment after basic deployment
# Run this after deploy.sh completes successfully
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="lawvriksh-backend"
PROJECT_DIR="/opt/${PROJECT_NAME}"
DOMAIN="www.lawvriksh.com"
API_PATH="/api"
DB_NAME="lawvriksh_production"
DB_USER="lawvriksh_user"
RABBITMQ_USER="lawvriksh_mq"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "docker-compose.production.yml" ]]; then
        error "docker-compose.production.yml not found. Please run this script from the backend directory."
    fi
}

# Load or create environment variables
setup_environment() {
    log "Setting up production environment variables..."
    
    # Load existing secrets if available
    if [[ -f ".env.production" ]]; then
        source .env.production
        info "Loaded existing secrets from .env.production"
    else
        error ".env.production not found. Please run deploy.sh first."
    fi
    
    # Prompt for additional configuration
    echo
    info "Please provide the following configuration:"
    
    # Domain configuration
    read -p "Domain name (default: www.lawvriksh.com): " input_domain
    DOMAIN=${input_domain:-$DOMAIN}
    
    # Email configuration
    read -p "Email FROM address (default: info@lawvriksh.com): " email_from
    EMAIL_FROM=${email_from:-"info@lawvriksh.com"}
    
    read -p "SMTP Host (e.g., smtp.gmail.com): " smtp_host
    SMTP_HOST=${smtp_host}
    
    read -p "SMTP Port (default: 587): " smtp_port
    SMTP_PORT=${smtp_port:-587}
    
    read -p "SMTP Username: " smtp_user
    SMTP_USER=${smtp_user}
    
    read -s -p "SMTP Password: " smtp_password
    SMTP_PASSWORD=${smtp_password}
    echo
    
    # Generate additional secrets
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    
    # Create comprehensive .env file
    cat > .env.production << EOF
# Lawvriksh Backend Production Environment
# Generated on $(date)

# Domain Configuration
DOMAIN=${DOMAIN}
API_BASE_URL=https://${DOMAIN}/api
FRONTEND_URL=https://${DOMAIN}

# Database Configuration
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

# Message Queue
RABBITMQ_USER=${RABBITMQ_USER}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}

# Cache
REDIS_PASSWORD=${REDIS_PASSWORD}

# Security
JWT_SECRET_KEY=${JWT_SECRET_KEY}

# Email Configuration
EMAIL_FROM=${EMAIL_FROM}
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASSWORD=${SMTP_PASSWORD}

# Application Settings
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO
EOF
    
    chmod 600 .env.production
    info "Production environment configured"
}

# Create Nginx configuration
setup_nginx() {
    log "Setting up Nginx configuration..."
    
    # Create Nginx site configuration
    sudo tee /etc/nginx/sites-available/lawvriksh << EOF
# Lawvriksh Backend Nginx Configuration
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # SSL Configuration (will be configured by Certbot)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_status 429;
    
    # Frontend (React/Next.js)
    location / {
        # This will be configured for frontend later
        root /var/www/lawvriksh;
        index index.html;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API Backend
    location ${API_PATH}/ {
        # Remove /api prefix when forwarding to backend
        rewrite ^${API_PATH}/(.*) /\$1 break;
        
        # Rate limiting for API
        limit_req zone=api burst=20 nodelay;
        
        # Proxy to FastAPI backend
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
    
    # Health check endpoint (direct access)
    location = /api/health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
    
    # API Documentation (optional, can be disabled in production)
    location /api/docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/lawvriksh /etc/nginx/sites-enabled/
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test Nginx configuration
    sudo nginx -t
    
    info "Nginx configuration created"
}

# Setup SSL certificate
setup_ssl() {
    log "Setting up SSL certificate with Let's Encrypt..."
    
    # Stop Nginx temporarily
    sudo systemctl stop nginx
    
    # Obtain SSL certificate
    sudo certbot certonly --standalone -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}
    
    # Start Nginx
    sudo systemctl start nginx
    
    # Setup auto-renewal
    sudo crontab -l 2>/dev/null | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx"; } | sudo crontab -
    
    info "SSL certificate configured and auto-renewal setup"
}

# Setup log rotation
setup_logging() {
    log "Setting up log rotation..."
    
    sudo tee /etc/logrotate.d/lawvriksh << EOF
${PROJECT_DIR}/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
    postrotate
        docker-compose -f ${PROJECT_DIR}/docker-compose.production.yml restart backend celery-worker celery-beat
    endscript
}
EOF
    
    info "Log rotation configured"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up basic monitoring..."
    
    # Create monitoring script
    cat > monitor.sh << 'EOF'
#!/bin/bash
# Basic monitoring script for Lawvriksh Backend

check_service() {
    if docker-compose -f docker-compose.production.yml ps $1 | grep -q "Up"; then
        echo "✅ $1 is running"
    else
        echo "❌ $1 is not running"
        docker-compose -f docker-compose.production.yml restart $1
    fi
}

echo "=== Lawvriksh Backend Health Check ==="
echo "Timestamp: $(date)"
echo

check_service "mysql"
check_service "rabbitmq"
check_service "redis"
check_service "backend"
check_service "celery-worker"
check_service "celery-beat"

echo
echo "=== Disk Usage ==="
df -h /opt/lawvriksh-backend

echo
echo "=== Memory Usage ==="
free -h

echo
echo "=== Docker Stats ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
EOF
    
    chmod +x monitor.sh
    
    # Setup monitoring cron job
    (crontab -l 2>/dev/null; echo "*/5 * * * * cd ${PROJECT_DIR} && ./monitor.sh >> logs/monitor.log 2>&1") | crontab -
    
    info "Basic monitoring setup complete"
}

# Main setup function
main() {
    log "Starting Lawvriksh Backend Production Setup"
    log "=========================================="
    
    check_directory
    setup_environment
    setup_nginx
    setup_ssl
    setup_logging
    setup_monitoring
    
    log "=========================================="
    log "Production setup completed successfully!"
    log "Next step: Run ./start-services.sh to start all services"
    log "=========================================="
}

# Run main function
main "$@"
