#!/bin/bash

# =============================================================================
# LawVriksh Nginx Configuration Script
# =============================================================================
# Sets up Nginx reverse proxy for LawVriksh application
# Configures routing for frontend, backend API, and admin panel
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
NGINX_CONF="/etc/nginx/sites-available/lawvriksh"
NGINX_ENABLED="/etc/nginx/sites-enabled/lawvriksh"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Create Nginx configuration
create_nginx_config() {
    log "Creating Nginx configuration for $DOMAIN..."
    
    sudo tee $NGINX_CONF > /dev/null << EOF
# LawVriksh Nginx Configuration
# ============================

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
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
    
    # API routes (backend)
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
    
    # API documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # OpenAPI JSON
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Frontend (React app)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Handle client-side routing
        try_files \$uri \$uri/ @fallback;
    }
    
    # Fallback for client-side routing
    location @fallback {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\\n";
        add_header Content-Type text/plain;
    }
    
    # Favicon
    location /favicon.ico {
        proxy_pass http://127.0.0.1:3000/favicon.ico;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Static assets
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        proxy_pass http://127.0.0.1:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security: Block access to sensitive files
    location ~ /\\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \\.(env|log|conf)\$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    success "Nginx configuration created"
}

# Enable Nginx site
enable_nginx_site() {
    log "Enabling Nginx site..."
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Enable LawVriksh site
    sudo ln -sf $NGINX_CONF $NGINX_ENABLED
    
    success "Nginx site enabled"
}

# Test and reload Nginx
reload_nginx() {
    log "Testing and reloading Nginx configuration..."
    
    # Test configuration
    if sudo nginx -t; then
        success "Nginx configuration test passed"
        
        # Reload Nginx
        sudo systemctl reload nginx
        success "Nginx reloaded successfully"
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

# Setup SSL with Certbot
setup_ssl() {
    log "Setting up SSL certificate..."
    
    info "To setup SSL certificate, run:"
    echo "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo ""
    info "This will:"
    echo "1. Obtain SSL certificate from Let's Encrypt"
    echo "2. Automatically configure HTTPS in Nginx"
    echo "3. Set up automatic certificate renewal"
    echo ""
    warning "Make sure your domain DNS points to this server before running certbot!"
}

# Display status
show_status() {
    log "Checking service status..."
    
    # Check Nginx status
    if systemctl is-active --quiet nginx; then
        success "Nginx is running"
    else
        error "Nginx is not running"
    fi
    
    # Check Docker services
    if command -v docker-compose &> /dev/null; then
        info "Docker services status:"
        docker-compose ps 2>/dev/null || echo "No Docker Compose services found"
    fi
    
    # Test endpoints
    info "Testing endpoints:"
    
    # Test frontend
    if curl -f -s http://localhost:3000/health > /dev/null; then
        success "Frontend is responding"
    else
        warning "Frontend may not be responding"
    fi
    
    # Test backend
    if curl -f -s http://localhost:8000/health > /dev/null; then
        success "Backend is responding"
    else
        warning "Backend may not be responding"
    fi
    
    # Test Nginx proxy
    if curl -f -s http://localhost/health > /dev/null; then
        success "Nginx proxy is working"
    else
        warning "Nginx proxy may not be working"
    fi
}

# Main function
main() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🌐 LawVriksh Nginx Setup"
    echo "=================================================================="
    echo "Domain: $DOMAIN"
    echo "Configuration: $NGINX_CONF"
    echo "=================================================================="
    echo -e "${NC}"
    
    # Create and enable Nginx configuration
    create_nginx_config
    enable_nginx_site
    reload_nginx
    
    # Show SSL setup instructions
    setup_ssl
    
    # Show status
    show_status
    
    success "🎉 Nginx setup completed!"
    info "Your application should now be accessible at:"
    echo "• Frontend: http://$DOMAIN"
    echo "• API: http://$DOMAIN/api/"
    echo "• API Docs: http://$DOMAIN/docs"
    echo "• Admin Panel: http://$DOMAIN/admin/login"
    echo ""
    info "After setting up SSL, it will be available at https://$DOMAIN"
}

# Run main function
main "$@"
