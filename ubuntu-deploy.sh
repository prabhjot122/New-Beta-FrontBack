#!/bin/bash

# =============================================================================
# LawVriksh Ubuntu 24.04 Deployment Script
# =============================================================================
# One-command deployment for LawVriksh platform
# Usage: bash ubuntu-deploy.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo -e "${GREEN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                    🚀 LawVriksh Deployment                       ║
║                     Ubuntu 24.04 Auto-Deploy                    ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verify Ubuntu version
if ! grep -q "Ubuntu 24.04" /etc/os-release 2>/dev/null; then
    error "This script requires Ubuntu 24.04 LTS"
fi

# Check user privileges
if [[ $EUID -eq 0 ]]; then
    error "Please run as a regular user with sudo privileges, not as root"
fi

PROJECT_DIR="/opt/lawvriksh"

log "Starting LawVriksh deployment..."

# System update and dependencies
log "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git jq nginx certbot python3-certbot-nginx

# Install Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    success "Docker installed"
else
    success "Docker already installed"
fi

# Install Docker Compose
log "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    success "Docker Compose installed"
else
    success "Docker Compose already installed"
fi

# Setup project directory
log "Setting up project directory..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

# Create directory structure
mkdir -p {logs/{mysql,backend,celery,rabbitmq,redis},cache,uploads,backups}

# Create environment file
log "Creating environment configuration..."
cat > .env << 'EOF'
# Database Configuration
DB_USER=lawvriksh_user
DB_PASSWORD=Sahil123
DB_NAME=lawvriksh_referral
DB_HOST=mysql
DB_PORT=3306
MYSQL_ROOT_PASSWORD=Sahil123
DATABASE_URL=mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral

# Security
JWT_SECRET_KEY=lawvriksh-jwt-secret-key-change-in-production-2024

# Message Queue & Cache
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
REDIS_PASSWORD=redis_password_123

# Email Configuration
EMAIL_FROM=info@lawvriksh.com
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=info@lawvriksh.com
SMTP_PASSWORD=Lawvriksh@123

# Application Settings
ENVIRONMENT=production
LOG_LEVEL=INFO
CACHE_DIR=./cache

# Domain Configuration
DOMAIN=lawvriksh.com
FRONTEND_URL=https://lawvriksh.com

# Admin Configuration
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123
EOF

chmod 600 .env
success "Environment configured"

# Create Docker Compose file
log "Creating Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: lawvriksh-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./logs/mysql:/var/log/mysql
    ports:
      - "127.0.0.1:3306:3306"
    networks:
      - lawvriksh-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      timeout: 20s
      retries: 10

  backend:
    image: python:3.11-slim
    container_name: lawvriksh-backend
    restart: unless-stopped
    working_dir: /app
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - EMAIL_FROM=${EMAIL_FROM}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
      - ENVIRONMENT=production
      - FRONTEND_URL=${FRONTEND_URL}
      - ADMIN_EMAIL=${ADMIN_EMAIL}
      - ADMIN_PASSWORD=${ADMIN_PASSWORD}
    volumes:
      - .:/app
      - ./cache:/app/cache
      - ./logs/backend:/app/logs
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - lawvriksh-network
    command: >
      bash -c "
        apt-get update &&
        apt-get install -y default-libmysqlclient-dev build-essential curl &&
        pip install --no-cache-dir -r requirements.txt &&
        uvicorn app.main:app --host 0.0.0.0 --port 8000
      "
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  lawvriksh-network:
    driver: bridge

volumes:
  mysql_data:
    driver: local
EOF

# Create requirements.txt if not exists
if [ ! -f "requirements.txt" ]; then
    log "Creating requirements.txt..."
    cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
pymysql==1.1.0
cryptography==41.0.7
pydantic==2.5.0
pydantic-settings==2.1.0
PyJWT==2.8.0
passlib[bcrypt]==1.7.4
email-validator==2.1.0
python-multipart==0.0.6
diskcache==5.6.3
python-dotenv==1.0.0
EOF
fi

# Create basic app structure if not exists
if [ ! -d "app" ]; then
    log "Creating basic app structure..."
    mkdir -p app/{api,core,models,schemas,services}
    
    # Create __init__.py files
    touch app/__init__.py app/api/__init__.py app/core/__init__.py
    touch app/models/__init__.py app/schemas/__init__.py app/services/__init__.py
    
    # Create basic main.py
    cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="LawVriksh API",
    description="Legal Professional Referral Platform",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "lawvriksh-backend"}

@app.get("/")
def root():
    return {"message": "LawVriksh API is running", "version": "1.0.0"}
EOF
fi

# Start Docker services
log "Starting Docker services..."
# Use newgrp to apply docker group membership
newgrp docker << EONG
docker-compose up -d --build
EONG

# Wait for services to start
log "Waiting for services to initialize..."
sleep 45

# Configure Nginx
log "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/lawvriksh.com << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "*" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    }
    
    # Default route
    location / {
        return 200 'LawVriksh Platform is running!\n\nAPI: http://lawvriksh.com/api/\nHealth: http://lawvriksh.com/api/health\nDocs: http://lawvriksh.com/api/docs\n';
        add_header Content-Type text/plain;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

# Enable site and restart Nginx
sudo ln -sf /etc/nginx/sites-available/lawvriksh.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl enable nginx

# Configure firewall
log "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Health checks
log "Running health checks..."
sleep 15

# Check backend health
if curl -f -s http://localhost:8000/health > /dev/null; then
    success "Backend is healthy"
else
    error "Backend health check failed"
fi

# Check API through Nginx
if curl -f -s http://localhost/api/health > /dev/null; then
    success "API accessible through Nginx"
else
    error "API not accessible through Nginx"
fi

# Display final status
echo -e "${GREEN}"
cat << EOF
╔══════════════════════════════════════════════════════════════════╗
║                    🎉 Deployment Complete!                       ║
╚══════════════════════════════════════════════════════════════════╝

✅ LawVriksh Platform Status:
   • Backend API: http://lawvriksh.com/api/
   • Health Check: http://lawvriksh.com/api/health
   • API Documentation: http://lawvriksh.com/api/docs
   • Project Directory: $PROJECT_DIR

🔧 Next Steps:
   1. Upload your complete application code to: $PROJECT_DIR
   2. Configure SSL certificate:
      sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com
   3. Restart services after code upload:
      cd $PROJECT_DIR && docker-compose restart

🔍 Management Commands:
   • Check status: cd $PROJECT_DIR && docker-compose ps
   • View logs: cd $PROJECT_DIR && docker-compose logs -f
   • Restart: cd $PROJECT_DIR && docker-compose restart
   • Stop: cd $PROJECT_DIR && docker-compose down

📊 Monitoring:
   • Backend logs: docker-compose logs backend
   • Database logs: docker-compose logs mysql
   • System status: systemctl status nginx

EOF
echo -e "${NC}"

success "LawVriksh deployment completed successfully!"
log "Upload your application files to $PROJECT_DIR and restart services"
