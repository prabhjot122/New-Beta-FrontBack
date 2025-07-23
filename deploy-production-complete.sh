#!/bin/bash

# =============================================================================
# LawVriksh Complete Production Deployment Script
# =============================================================================
# Complete deployment for Ubuntu 24.04 VPS with beta user registration
# Deploys: Frontend (lawvriksh.com) + Backend (lawvriksh.com/api) + Database
# Features: Beta joining page, admin setup, nginx configuration
# 
# Usage: chmod +x deploy-production-complete.sh && ./deploy-production-complete.sh
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
DEPLOY_DIR="/opt/$PROJECT_NAME"
CURRENT_DIR=$(pwd)

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
    echo "🚀 LawVriksh Complete Production Deployment"
    echo "=================================================================="
    echo "Domain: $DOMAIN"
    echo "Frontend: https://$DOMAIN (Beta joining page)"
    echo "Backend API: https://$DOMAIN/api"
    echo "Admin Panel: https://$DOMAIN/admin/login"
    echo "=================================================================="
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking deployment prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
        error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 24.04" /etc/os-release 2>/dev/null; then
        warning "This script is optimized for Ubuntu 24.04"
        warning "Current OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
        warning "Continuing anyway, but some steps might fail"
    fi
    
    # Check if we have sudo privileges
    if ! sudo -n true 2>/dev/null; then
        error "This script requires sudo privileges"
        error "Please run: sudo -v"
        exit 1
    fi
    
    # Check required files exist
    local required_files=(
        "Frontend/src/App.tsx"
        "Frontend/src/components/WaitlistPopup.tsx"
        "app/main.py"
        "lawdata.sql"
        ".env"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "Required file not found: $file"
            error "Please run this script from the project root directory"
            exit 1
        fi
    done
    
    success "Prerequisites check passed"
}

# Confirm deployment with user
confirm_deployment() {
    echo ""
    warning "⚠️  PRODUCTION DEPLOYMENT CONFIRMATION"
    warning "⚠️  This will deploy LawVriksh to production on $DOMAIN"
    echo ""
    info "This deployment will:"
    echo "  🔧 Install Docker, Nginx, and required system packages"
    echo "  🔒 Configure firewall and security settings"
    echo "  🌐 Setup nginx for $DOMAIN (frontend) and $DOMAIN/api (backend)"
    echo "  🗄️  Deploy MySQL database with admin user"
    echo "  🚀 Deploy React frontend with beta joining page"
    echo "  ⚡ Deploy FastAPI backend with user registration API"
    echo "  👤 Create admin user: sahilsaurav2507@gmail.com"
    echo "  🔐 Setup SSL certificate (requires domain verification)"
    echo ""
    warning "⚠️  Make sure $DOMAIN points to this server's IP address"
    echo ""
    
    read -p "Do you want to continue with production deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Deployment cancelled by user"
        exit 0
    fi
    
    echo ""
    log "Starting production deployment in 3 seconds..."
    sleep 3
}

# Update system packages
update_system() {
    log "Updating system packages..."
    
    sudo apt update
    sudo apt upgrade -y
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
        build-essential \
        python3-pip \
        nodejs \
        npm
    
    success "System packages updated"
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        success "Docker already installed: $(docker --version)"
        return
    fi
    
    log "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    success "Docker installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        success "Docker Compose already installed: $(docker-compose --version)"
        return
    fi
    
    log "Installing Docker Compose..."
    
    # Get latest version
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for easier access
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    success "Docker Compose installed successfully"
}

# Install and configure Nginx
install_nginx() {
    if command -v nginx &> /dev/null; then
        success "Nginx already installed: $(nginx -v 2>&1)"
        return
    fi
    
    log "Installing Nginx..."
    
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    success "Nginx installed and configured"
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
    
    # Reset firewall to defaults
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow essential services
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Enable firewall
    sudo ufw --force enable
    
    success "Firewall configured and enabled"
}

# Create project structure
create_project_structure() {
    log "Creating project structure at $DEPLOY_DIR..."
    
    # Create main project directory
    sudo mkdir -p $DEPLOY_DIR
    sudo chown $USER:$USER $DEPLOY_DIR
    
    # Copy all project files
    log "Copying project files..."
    cp -r $CURRENT_DIR/* $DEPLOY_DIR/ 2>/dev/null || true
    cp -r $CURRENT_DIR/.* $DEPLOY_DIR/ 2>/dev/null || true
    
    # Change to project directory
    cd $DEPLOY_DIR
    
    # Create necessary directories
    mkdir -p {logs,cache,uploads,backups}
    mkdir -p logs/{backend,frontend,mysql,nginx}
    
    # Set proper permissions
    chmod +x *.sh 2>/dev/null || true
    chmod +x *.py 2>/dev/null || true
    
    success "Project structure created at $DEPLOY_DIR"
}

# Setup environment variables
setup_environment() {
    log "Setting up production environment variables..."
    
    cd $DEPLOY_DIR
    
    # Generate secure passwords if not already set
    if [[ ! -f ".env.production" ]]; then
        log "Creating production environment file..."
        
        # Generate secure random passwords
        MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        JWT_SECRET_KEY=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
        REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        
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

# CORS Configuration
FRONTEND_URL=https://$DOMAIN
EOF
        
        success "Production environment file created"
    else
        success "Production environment file already exists"
    fi
    
    # Create symlink for docker-compose
    ln -sf .env.production .env
    chmod 600 .env.production .env
}

# Main deployment function
main() {
    show_deployment_banner
    check_prerequisites
    confirm_deployment
    
    log "Starting complete production deployment..."
    
    # Phase 1: System Setup
    log "Phase 1: System Setup and Dependencies"
    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    setup_firewall
    
    # Phase 2: Project Setup
    log "Phase 2: Project Structure and Configuration"
    create_project_structure
    setup_environment
    
    success "=================================================================="
    success "🎉 System Setup Completed Successfully!"
    success "=================================================================="
    
    info "Next steps:"
    echo "1. Log out and log back in (for Docker group changes to take effect)"
    echo "2. Run: cd $DEPLOY_DIR && ./deploy-services.sh"
    echo "3. Setup SSL: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo ""
    
    warning "Important:"
    echo "• Make sure your domain $DOMAIN points to this server"
    echo "• The deployment will continue with the services setup"
    echo "• Admin credentials: sahilsaurav2507@gmail.com / Sahil@123"
    
    success "Phase 1 deployment completed successfully!"
}

# Handle script interruption
trap 'error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
