#!/bin/bash

# =============================================================================
# LawVriksh Quick Ubuntu Deployment Script
# =============================================================================
# Automated deployment script for Ubuntu 24.04
# This script handles the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_DIR="/opt/lawvriksh"
DOMAIN="lawvriksh.com"
ADMIN_EMAIL="sahilsaurav2507@gmail.com"
ADMIN_PASSWORD="Sahil@123"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release jq
    
    success "System dependencies installed"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Install Docker Compose standalone
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    success "Docker installed successfully"
}

# Setup project directory
setup_project() {
    log "Setting up project directory..."
    
    # Create project directory
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    
    # Create necessary subdirectories
    mkdir -p $PROJECT_DIR/{logs/{mysql,backend,celery,celery-beat,rabbitmq,redis},cache,uploads,backups}
    
    success "Project directory created"
}

# Create environment file
create_env_file() {
    log "Creating environment configuration..."
    
    cat > $PROJECT_DIR/.env << 'EOF'
# Database Configuration
DB_USER=lawvriksh_user
DB_PASSWORD=Sahil123
DB_NAME=lawvriksh_referral
DB_HOST=mysql
DB_PORT=3306
MYSQL_ROOT_PASSWORD=Sahil123

# Database URL
DATABASE_URL=mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral

# Security
JWT_SECRET_KEY=your-super-secret-key-here-make-it-long-and-random-for-production-use-change-this-now

# Message Queue
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# Redis
REDIS_PASSWORD=redis_secure_password_123

# Email Configuration
EMAIL_FROM=info@lawvriksh.com
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=info@lawvriksh.com
SMTP_PASSWORD=Lawvriksh@123

# Application Settings
CACHE_DIR=./cache
ENVIRONMENT=production
LOG_LEVEL=INFO

# Domain Configuration
DOMAIN=lawvriksh.com
FRONTEND_URL=https://lawvriksh.com

# Admin Configuration
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123
EOF

    chmod 600 $PROJECT_DIR/.env
    success "Environment file created"
}

# Deploy with Docker
deploy_docker() {
    log "Deploying with Docker..."
    
    cd $PROJECT_DIR
    
    # Start services
    docker-compose -f docker-compose.production.yml up -d --build
    
    # Wait for services to start
    log "Waiting for services to start..."
    sleep 60
    
    success "Docker services deployed"
}

# Setup database
setup_database() {
    log "Setting up database..."
    
    cd $PROJECT_DIR
    
    # Wait for MySQL to be ready
    log "Waiting for MySQL to be ready..."
    until docker-compose -f docker-compose.production.yml exec mysql mysqladmin ping -h localhost -u root -pSahil123 --silent; do
        echo "Waiting for MySQL..."
        sleep 5
    done
    
    # Create database and user
    docker-compose -f docker-compose.production.yml exec mysql mysql -u root -pSahil123 -e "
    CREATE DATABASE IF NOT EXISTS lawvriksh_referral CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS 'lawvriksh_user'@'%' IDENTIFIED BY 'Sahil123';
    GRANT ALL PRIVILEGES ON lawvriksh_referral.* TO 'lawvriksh_user'@'%';
    FLUSH PRIVILEGES;
    "
    
    # Import schema if lawdata.sql exists
    if [ -f "lawdata.sql" ]; then
        log "Importing database schema..."
        docker-compose -f docker-compose.production.yml exec -T mysql mysql -u root -pSahil123 lawvriksh_referral < lawdata.sql
    fi
    
    # Setup admin user
    if [ -f "setup_admin_corrected.py" ]; then
        log "Setting up admin user..."
        docker-compose -f docker-compose.production.yml exec backend python setup_admin_corrected.py
    fi
    
    success "Database setup completed"
}

# Install and configure Nginx
setup_nginx() {
    log "Setting up Nginx..."
    
    sudo apt install -y nginx
    
    # Create Nginx configuration
    sudo tee /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Frontend (serve static files)
    location / {
        root /var/www/lawvriksh;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://$DOMAIN" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
        
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://$DOMAIN";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and start Nginx
    sudo nginx -t
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    success "Nginx configured"
}

# Setup frontend
setup_frontend() {
    log "Setting up frontend..."
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    
    cd $PROJECT_DIR
    
    if [ -d "Frontend" ]; then
        cd Frontend
        
        # Install dependencies and build
        npm install
        npm run build
        
        # Copy to Nginx directory
        sudo mkdir -p /var/www/lawvriksh
        sudo cp -r dist/* /var/www/lawvriksh/
        sudo chown -R www-data:www-data /var/www/lawvriksh
        
        success "Frontend built and deployed"
    else
        warning "Frontend directory not found, skipping frontend setup"
    fi
}

# Configure firewall
setup_firewall() {
    log "Configuring firewall..."
    
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    success "Firewall configured"
}

# Run health checks
run_health_checks() {
    log "Running health checks..."
    
    cd $PROJECT_DIR
    
    # Check Docker services
    docker-compose -f docker-compose.production.yml ps
    
    # Check backend health
    if curl -f -s http://localhost:8000/health > /dev/null; then
        success "Backend health check passed"
    else
        error "Backend health check failed"
    fi
    
    # Check beta service
    if curl -f -s http://localhost:8000/beta/health > /dev/null; then
        success "Beta service health check passed"
    else
        warning "Beta service health check failed"
    fi
    
    success "Health checks completed"
}

# Main deployment function
main() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🚀 LawVriksh Ubuntu Deployment Script"
    echo "=================================================================="
    echo "Domain: $DOMAIN"
    echo "Project Directory: $PROJECT_DIR"
    echo "=================================================================="
    echo -e "${NC}"
    
    check_root
    install_dependencies
    install_docker
    setup_project
    create_env_file
    
    log "Please copy your project files to $PROJECT_DIR and press Enter to continue..."
    read -p "Press Enter when ready..."
    
    deploy_docker
    setup_database
    setup_nginx
    setup_frontend
    setup_firewall
    run_health_checks
    
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🎉 Deployment Complete!"
    echo "=================================================================="
    echo "Frontend: http://$DOMAIN"
    echo "Backend API: http://$DOMAIN/api"
    echo "Admin Panel: http://$DOMAIN/admin"
    echo "API Docs: http://$DOMAIN/api/docs"
    echo ""
    echo "Next steps:"
    echo "1. Configure SSL with: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo "2. Test the application thoroughly"
    echo "3. Set up monitoring and backups"
    echo "=================================================================="
    echo -e "${NC}"
}

# Run main function
main "$@"
