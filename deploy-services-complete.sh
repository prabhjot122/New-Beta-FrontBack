#!/bin/bash

# =============================================================================
# LawVriksh Complete Services Deployment Script
# =============================================================================
# Deploys all services: MySQL, Backend, Frontend with proper initialization
# Includes database setup, admin user creation, and verification
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
COMPOSE_FILE="docker-compose.production.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
    COMPOSE_FILE="docker-compose.yml"
fi

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Display deployment banner
show_deployment_banner() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🚀 LawVriksh Services Deployment"
    echo "=================================================================="
    echo "Services: MySQL, Backend (FastAPI), Frontend (React)"
    echo "Features: Beta Registration, Admin Panel, Database Setup"
    echo "Compose File: $COMPOSE_FILE"
    echo "=================================================================="
    echo -e "${NC}"
}

# Create database initialization SQL
create_database_init() {
    log "Creating database initialization script..."
    
    cat > init-db.sql << 'EOF'
-- LawVriksh Database Initialization
-- ================================

-- Create database
CREATE DATABASE IF NOT EXISTS lawvriksh_referral;
USE lawvriksh_referral;

-- Create users table with correct schema
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NULL,  -- NULL for beta users, set for admin
    total_points INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    default_rank INT NULL,
    current_rank INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    user_type VARCHAR(10) DEFAULT 'beta',  -- 'beta' or 'admin'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_total_points (total_points DESC),
    INDEX idx_is_admin (is_admin),
    INDEX idx_user_type (user_type)
);

-- Create shares table
CREATE TABLE IF NOT EXISTS shares (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    points_earned INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_platform (platform)
);

-- Create campaigns table
CREATE TABLE IF NOT EXISTS campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create feedback table
CREATE TABLE IF NOT EXISTS feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    message TEXT NOT NULL,
    rating INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id)
);
EOF
    
    success "Database initialization script created"
}

# Create Dockerfiles if they don't exist
create_dockerfiles() {
    log "Creating Dockerfiles..."
    
    # Backend Dockerfile
    if [[ ! -f "Dockerfile.production" ]]; then
        cat > Dockerfile.production << 'EOF'
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/logs /app/cache /app/uploads

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
        success "Backend Dockerfile created"
    fi
    
    # Frontend Dockerfile
    if [[ ! -f "Dockerfile.frontend" ]]; then
        cat > Dockerfile.frontend << 'EOF'
FROM node:18-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . ./
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html

RUN cat > /etc/nginx/conf.d/default.conf << 'NGINXEOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript;
}
NGINXEOF

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
EOF
        success "Frontend Dockerfile created"
    fi
}

# Create requirements.txt if it doesn't exist
create_requirements() {
    if [[ ! -f "requirements.txt" ]]; then
        log "Creating requirements.txt..."
        cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
pymysql==1.1.0
cryptography==41.0.7
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
bcrypt==4.0.1
python-dotenv==1.0.0
pydantic==2.5.0
pydantic-settings==2.1.0
email-validator==2.1.0
jinja2==3.1.2
aiofiles==23.2.1
httpx==0.25.2
celery==5.3.4
redis==5.0.1
alembic==1.13.1
EOF
        success "Requirements.txt created"
    fi
}

# Deploy services
deploy_services() {
    log "Deploying services with Docker Compose..."
    
    # Stop any existing services
    docker-compose -f $COMPOSE_FILE down -v 2>/dev/null || true
    
    # Clean up Docker system
    docker system prune -f
    
    # Build and start services
    docker-compose -f $COMPOSE_FILE up -d --build
    
    success "Services deployment initiated"
}

# Wait for services to be ready
wait_for_services() {
    log "Waiting for services to be ready..."
    
    # Wait for MySQL
    log "Waiting for MySQL to initialize..."
    sleep 60
    
    # Check MySQL health
    local mysql_ready=false
    for i in {1..10}; do
        if docker-compose -f $COMPOSE_FILE exec mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-Sahil123} 2>/dev/null; then
            mysql_ready=true
            break
        fi
        log "MySQL not ready yet, waiting... ($i/10)"
        sleep 10
    done
    
    if [[ "$mysql_ready" == "true" ]]; then
        success "MySQL is ready"
    else
        error "MySQL failed to start properly"
        return 1
    fi
    
    # Wait for backend
    log "Waiting for backend to be ready..."
    sleep 30
    
    local backend_ready=false
    for i in {1..10}; do
        if curl -f http://localhost:8000/health 2>/dev/null; then
            backend_ready=true
            break
        fi
        log "Backend not ready yet, waiting... ($i/10)"
        sleep 10
    done
    
    if [[ "$backend_ready" == "true" ]]; then
        success "Backend is ready"
    else
        warning "Backend may not be fully ready, continuing..."
    fi
    
    success "Services are ready"
}

# Setup admin user
setup_admin_user() {
    log "Setting up admin user..."
    
    # Copy admin setup script to container
    docker cp setup_admin_corrected.py $(docker-compose -f $COMPOSE_FILE ps -q backend):/app/ 2>/dev/null || {
        warning "Admin setup script not found, creating it..."
        cat > temp_admin_setup.py << 'EOF'
import os
import bcrypt
from sqlalchemy import create_engine, text

DATABASE_URL = "mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral"
ADMIN_EMAIL = "sahilsaurav2507@gmail.com"
ADMIN_PASSWORD = "Sahil@123"

def setup_admin():
    try:
        engine = create_engine(DATABASE_URL)
        hashed_password = bcrypt.hashpw(ADMIN_PASSWORD.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        with engine.connect() as conn:
            conn.execute(text("""
                INSERT INTO users (name, email, password_hash, is_admin, is_active, user_type, total_points, shares_count)
                VALUES (:name, :email, :password_hash, 1, 1, 'admin', 0, 0)
                ON DUPLICATE KEY UPDATE 
                    password_hash = :password_hash, 
                    is_admin = 1, 
                    is_active = 1,
                    user_type = 'admin',
                    updated_at = NOW()
            """), {
                "name": "Admin User",
                "email": ADMIN_EMAIL,
                "password_hash": hashed_password
            })
            conn.commit()
            print(f"✅ Admin user {ADMIN_EMAIL} created successfully")
            return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    setup_admin()
EOF
        docker cp temp_admin_setup.py $(docker-compose -f $COMPOSE_FILE ps -q backend):/app/setup_admin.py
        rm temp_admin_setup.py
    }
    
    # Install bcrypt and run admin setup
    docker-compose -f $COMPOSE_FILE exec backend pip install bcrypt
    docker-compose -f $COMPOSE_FILE exec backend python setup_admin.py || \
    docker-compose -f $COMPOSE_FILE exec backend python setup_admin_corrected.py
    
    success "Admin user setup completed"
}

# Main deployment function
main() {
    show_deployment_banner
    
    # Create necessary files
    create_database_init
    create_dockerfiles
    create_requirements
    
    # Deploy services
    deploy_services
    
    # Wait for services
    wait_for_services
    
    # Setup admin user
    setup_admin_user
    
    success "🎉 Services deployment completed successfully!"
    info "Services Status:"
    docker-compose -f $COMPOSE_FILE ps
    
    info "Next Steps:"
    echo "1. Test deployment: ./test-deployment.sh"
    echo "2. Setup SSL: sudo certbot --nginx -d your-domain.com"
    echo "3. Configure Nginx: ./setup-nginx.sh"
}

# Run main function
main "$@"
