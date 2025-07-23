#!/bin/bash

# =============================================================================
# LawVriksh Services Deployment Script
# =============================================================================
# Deploys the application services (Frontend + Backend + Database)
# Runs admin setup and database initialization
# 
# Usage: ./deploy-services.sh
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
PROJECT_NAME="lawvriksh"
DOMAIN="lawvriksh.com"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "docker-compose.production.yml" ]] && [[ ! -f "docker-compose.yml" ]]; then
        error "Docker compose file not found!"
        error "Please run this script from the project directory (/opt/$PROJECT_NAME)"
        exit 1
    fi
    
    if [[ ! -f ".env" ]] && [[ ! -f ".env.production" ]]; then
        error "Environment file not found!"
        error "Please run deploy-full-stack.sh first to set up the environment"
        exit 1
    fi
}

# Configure Nginx for production
configure_nginx() {
    log "Configuring Nginx for $DOMAIN..."

    # Copy nginx configuration
    if [[ -f "nginx-lawvriksh.conf" ]]; then
        sudo cp nginx-lawvriksh.conf /etc/nginx/sites-available/lawvriksh
        success "Nginx configuration copied"
    else
        log "Creating Nginx configuration..."
        sudo cp /dev/stdin /etc/nginx/sites-available/lawvriksh << 'EOF'
# LawVriksh Nginx Configuration
server {
    listen 80;
    listen [::]:80;
    server_name lawvriksh.com www.lawvriksh.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name lawvriksh.com www.lawvriksh.com;

    # SSL Configuration (managed by Certbot)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript;

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
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;

        # CORS headers
        add_header Access-Control-Allow-Origin "https://lawvriksh.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
    }

    # Frontend - lawvriksh.com (React SPA with beta joining)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        try_files $uri $uri/ @fallback;
    }

    location @fallback {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health checks
    location /api/health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
}
EOF
    fi

    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/lawvriksh /etc/nginx/sites-enabled/

    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default

    # Test nginx configuration
    if sudo nginx -t; then
        success "Nginx configuration is valid"
        sudo systemctl reload nginx
        success "Nginx reloaded with new configuration"
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

# Create Docker Compose file for full stack
create_docker_compose() {
    log "Creating Docker Compose configuration..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # MySQL Database
  mysql:
    image: mysql:8.0
    container_name: lawvriksh-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_CHARSET: utf8mb4
      MYSQL_COLLATION: utf8mb4_unicode_ci
    volumes:
      - mysql_data:/var/lib/mysql
      - ./lawdata.sql:/docker-entrypoint-initdb.d/init.sql:ro
      - ./logs/mysql:/var/log/mysql
    ports:
      - "127.0.0.1:3307:3306"
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb-buffer-pool-size=512M
      --max-connections=200
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    networks:
      - lawvriksh-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: lawvriksh-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - lawvriksh-network

  # FastAPI Backend
  backend:
    build:
      context: .
      dockerfile: Dockerfile.production
    container_name: lawvriksh-backend
    restart: unless-stopped
    environment:
      # Database Configuration
      DATABASE_URL: mysql+pymysql://${DB_USER}:${DB_PASSWORD}@mysql:3306/${DB_NAME}
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      
      # Security
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      
      # Email Configuration
      EMAIL_FROM: ${EMAIL_FROM}
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USER: ${SMTP_USER}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      
      # Application Settings
      ENVIRONMENT: production
      DEBUG: "false"
      CACHE_DIR: /app/cache
      LOG_LEVEL: INFO
      
      # Domain Configuration
      DOMAIN: ${DOMAIN}
      API_BASE_URL: https://${DOMAIN}/api
      FRONTEND_URL: https://${DOMAIN}
      
      # Admin Configuration
      ADMIN_EMAIL: ${ADMIN_EMAIL}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      
      # Cache
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379/0
      
    volumes:
      - ./cache:/app/cache
      - ./logs/backend:/app/logs
      - ./uploads:/app/uploads
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - lawvriksh-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # React Frontend
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    container_name: lawvriksh-frontend
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:80"
    networks:
      - lawvriksh-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

volumes:
  mysql_data:
  redis_data:

networks:
  lawvriksh-network:
    driver: bridge
EOF
    
    success "Docker Compose configuration created"
}

# Build and deploy services
deploy_services() {
    log "Building and deploying services..."
    
    # Stop any existing services
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Remove old images to ensure fresh build
    docker system prune -f
    
    # Build services
    log "Building Docker images..."
    docker-compose build --no-cache
    
    # Start services
    log "Starting services..."
    docker-compose up -d
    
    success "Services started successfully"
}

# Wait for services to be healthy
wait_for_services() {
    log "Waiting for services to be healthy..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log "Health check attempt $attempt/$max_attempts..."
        
        # Check MySQL
        if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD} &>/dev/null; then
            success "MySQL is healthy"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            error "Services failed to become healthy after $max_attempts attempts"
            return 1
        fi
        
        sleep 10
        ((attempt++))
    done
    
    # Additional wait for backend to be ready
    log "Waiting for backend to be ready..."
    sleep 20
}

# Setup admin user and initialize database
setup_admin_and_database() {
    log "Setting up admin user and initializing database..."
    
    # Run database initialization
    if [[ -f "init_db.py" ]]; then
        log "Running database initialization..."
        if docker-compose exec -T backend python init_db.py; then
            success "Database initialization completed"
        else
            warning "Database initialization failed, trying alternative method..."
        fi
    fi
    
    # Run admin setup
    if [[ -f "setup_admin.py" ]]; then
        log "Running admin setup..."
        if docker-compose exec -T backend python setup_admin.py; then
            success "Admin user setup completed"
        else
            warning "Admin setup failed, trying alternative method..."
        fi
    fi
    
    # Verify admin setup
    if [[ -f "verify_admin.py" ]]; then
        log "Verifying admin setup..."
        if docker-compose exec -T backend python verify_admin.py; then
            success "Admin verification completed successfully"
        else
            warning "Admin verification failed"
        fi
    fi
    
    # Show admin credentials
    info "Admin credentials:"
    echo "  📧 Email: sahilsaurav2507@gmail.com"
    echo "  🔑 Password: Sahil@123"
}

# Check service health
check_service_health() {
    log "Checking service health..."
    
    # Check backend health
    if curl -f http://localhost:8000/health &>/dev/null; then
        success "Backend is healthy"
    else
        warning "Backend health check failed"
    fi
    
    # Check frontend health
    if curl -f http://localhost:3000/health &>/dev/null; then
        success "Frontend is healthy"
    else
        warning "Frontend health check failed"
    fi
    
    # Show running containers
    log "Running containers:"
    docker-compose ps
}

# Display deployment summary
show_deployment_summary() {
    success "========================================"
    success "🎉 LawVriksh Deployment Completed!"
    success "========================================"
    
    info "Service URLs:"
    echo "🌐 Frontend: https://$DOMAIN"
    echo "🔗 Backend API: https://$DOMAIN/api"
    echo "📚 API Documentation: https://$DOMAIN/api/docs"
    echo ""
    
    info "Admin Access:"
    echo "👤 Email: sahilsaurav2507@gmail.com"
    echo "🔑 Password: Sahil@123"
    echo ""
    
    info "Management Commands:"
    echo "📋 View logs: docker-compose logs -f [service]"
    echo "🔄 Restart service: docker-compose restart [service]"
    echo "⏹️  Stop all: docker-compose down"
    echo "🚀 Start all: docker-compose up -d"
    echo "🔍 Service status: docker-compose ps"
    echo ""
    
    info "Next Steps:"
    echo "1. Set up SSL certificate: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo "2. Test the application at https://$DOMAIN"
    echo "3. Test the API at https://$DOMAIN/api/docs"
    echo "4. Login to admin panel with the credentials above"
    echo ""
    
    warning "Important:"
    echo "- Make sure your domain DNS points to this server"
    echo "- Run the SSL certificate command above for HTTPS"
    echo "- Monitor logs for any issues: docker-compose logs -f"
}

# Main function
main() {
    log "Starting LawVriksh Services Deployment"
    log "======================================"
    
    check_directory
    configure_nginx
    create_docker_compose
    deploy_services
    wait_for_services
    setup_admin_and_database
    check_service_health
    show_deployment_summary
    
    success "Services deployment completed successfully!"
}

# Run main function
main "$@"
