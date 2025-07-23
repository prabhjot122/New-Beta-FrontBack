#!/bin/bash

# =============================================================================
# LawVriksh Complete Ubuntu Docker Deployment Script
# =============================================================================
# This script deploys the complete LawVriksh application on Ubuntu with Docker
# Includes: MySQL, Backend (FastAPI), Frontend (React), Nginx, SSL
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
PROJECT_DIR="/opt/lawvriksh"
COMPOSE_FILE="docker-compose.production.yml"

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
    echo "🚀 LawVriksh Complete Ubuntu Docker Deployment"
    echo "=================================================================="
    echo "Domain: $DOMAIN"
    echo "Project Directory: $PROJECT_DIR"
    echo "Services: MySQL, Backend, Frontend, Nginx"
    echo "Features: SSL, Admin Panel, Beta Registration"
    echo "=================================================================="
    echo -e "${NC}"
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root. This is fine for deployment."
    elif sudo -n true 2>/dev/null; then
        success "Sudo access confirmed"
    else
        error "This script requires sudo access. Please run with sudo or as root."
        exit 1
    fi
}

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    # Update system
    sudo apt update && sudo apt upgrade -y
    
    # Install required packages
    sudo apt install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        nginx \
        certbot \
        python3-certbot-nginx
    
    success "System dependencies installed"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Remove old Docker versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    success "Docker installed successfully"
}

# Setup firewall
setup_firewall() {
    log "Setting up UFW firewall..."
    
    # Reset UFW to defaults
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 'Nginx Full'
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Enable firewall
    sudo ufw --force enable
    
    success "Firewall configured"
}

# Create project structure
create_project_structure() {
    log "Creating project structure..."
    
    # Create project directory
    sudo mkdir -p $PROJECT_DIR
    sudo chown -R $USER:$USER $PROJECT_DIR
    
    # Copy project files
    if [[ -d "$(pwd)" && "$(pwd)" != "$PROJECT_DIR" ]]; then
        log "Copying project files to $PROJECT_DIR..."
        sudo cp -r . $PROJECT_DIR/
        sudo chown -R $USER:$USER $PROJECT_DIR
    fi
    
    # Change to project directory
    cd $PROJECT_DIR
    
    success "Project structure created at $PROJECT_DIR"
}

# Generate environment configuration
generate_env_config() {
    log "Generating production environment configuration..."
    
    cat > .env << EOF
# Domain Configuration
DOMAIN=$DOMAIN
API_BASE_URL=https://$DOMAIN/api
FRONTEND_URL=https://$DOMAIN

# Database Configuration
DB_USER=lawvriksh_user
DB_PASSWORD=Sahil123
DB_NAME=lawvriksh_referral
DB_HOST=mysql
DB_PORT=3306
MYSQL_ROOT_PASSWORD=Sahil123

# Or use DATABASE_URL directly (takes precedence over individual DB_* variables)
DATABASE_URL=mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral

# Security
JWT_SECRET_KEY=$(openssl rand -base64 64)

# Message Queue
RABBITMQ_URL=amqp://guest:guest@localhost:5672/

# Email Configuration
EMAIL_FROM=info@lawvriksh.com
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=info@lawvriksh.com
SMTP_PASSWORD=Lawvriksh@123

# Application Settings
CACHE_DIR=./cache

# CORS Configuration
FRONTEND_URL=https://$DOMAIN

# Environment
ENVIRONMENT=production

# Admin Configuration
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123
EOF
    
    success "Environment configuration generated"
}

# Create production Docker Compose file
create_docker_compose() {
    log "Creating production Docker Compose configuration..."
    
    cat > $COMPOSE_FILE << 'EOF'
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
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    ports:
      - "127.0.0.1:3307:3306"
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    networks:
      - lawvriksh-network

  backend:
    build:
      context: .
      dockerfile: Dockerfile.production
    container_name: lawvriksh-backend
    restart: unless-stopped
    environment:
      DATABASE_URL: mysql+pymysql://${DB_USER}:${DB_PASSWORD}@mysql:3306/${DB_NAME}
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      ADMIN_EMAIL: ${ADMIN_EMAIL}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      ENVIRONMENT: production
      DEBUG: "false"
      LOG_LEVEL: INFO
      CACHE_DIR: /app/cache
      DOMAIN: ${DOMAIN}
      API_BASE_URL: ${API_BASE_URL}
      FRONTEND_URL: ${FRONTEND_URL}
    volumes:
      - ./logs:/app/logs
      - ./cache:/app/cache
      - ./uploads:/app/uploads
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - lawvriksh-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    build:
      context: ./Frontend
      dockerfile: ../Dockerfile.frontend
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

networks:
  lawvriksh-network:
    driver: bridge
EOF
    
    success "Docker Compose configuration created"
}

# Main deployment function
main() {
    show_deployment_banner
    
    # Check permissions
    check_permissions
    
    # Install dependencies
    install_dependencies
    install_docker
    
    # Setup firewall
    setup_firewall
    
    # Create project structure
    create_project_structure
    
    # Generate configuration
    generate_env_config
    create_docker_compose
    
    success "🎉 Deployment preparation complete!"
    info "Next steps:"
    echo "1. Run: cd $PROJECT_DIR"
    echo "2. Run: ./deploy-services.sh"
    echo "3. Setup SSL: sudo certbot --nginx -d $DOMAIN"
    echo "4. Test: ./test-deployment.sh"
}

# Run main function
main "$@"
