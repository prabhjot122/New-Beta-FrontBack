#!/bin/bash

# =============================================================================
# Lawvriksh Backend Deployment Script for Ubuntu 24.04 + Docker
# =============================================================================
# This script deploys the FastAPI backend to Ubuntu 24.04 with Docker
# Domain: www.lawvriksh.com/api/
# 
# Usage: chmod +x deploy.sh && ./deploy.sh
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="lawvriksh-backend"
DOMAIN="www.lawvriksh.com"
API_PATH="/api"
DOCKER_NETWORK="lawvriksh-network"
DB_NAME="lawvriksh_production"
DB_USER="lawvriksh_user"

# Logging function
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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    log "Checking Ubuntu version..."
    if ! grep -q "24.04" /etc/os-release; then
        warning "This script is optimized for Ubuntu 24.04. Current version:"
        cat /etc/os-release | grep VERSION
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    info "Docker installed successfully. You may need to log out and back in for group changes to take effect."
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    
    # Docker Compose is now included with Docker, but let's ensure we have the latest
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for docker-compose command
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
}

# Install Nginx
install_nginx() {
    log "Installing and configuring Nginx..."
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Allow Nginx through firewall
    sudo ufw allow 'Nginx Full' 2>/dev/null || true
}

# Install Certbot for SSL
install_certbot() {
    log "Installing Certbot for SSL certificates..."
    sudo apt install -y certbot python3-certbot-nginx
}

# Generate secure passwords and keys
generate_secrets() {
    log "Generating secure passwords and keys..."
    
    # Generate random passwords
    DB_PASSWORD=$(openssl rand -base64 32)
    JWT_SECRET_KEY=$(openssl rand -base64 64)
    RABBITMQ_PASSWORD=$(openssl rand -base64 32)
    
    # Save to secrets file
    cat > .env.production << EOF
# Generated secrets - DO NOT COMMIT TO VERSION CONTROL
DB_PASSWORD=${DB_PASSWORD}
JWT_SECRET_KEY=${JWT_SECRET_KEY}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD}
EOF
    
    chmod 600 .env.production
    info "Secrets generated and saved to .env.production"
}

# Create project directory structure
create_project_structure() {
    log "Creating project directory structure..."
    
    sudo mkdir -p /opt/${PROJECT_NAME}
    sudo chown $USER:$USER /opt/${PROJECT_NAME}
    
    mkdir -p /opt/${PROJECT_NAME}/{logs,cache,data,backups,ssl}
    mkdir -p /opt/${PROJECT_NAME}/data/{mysql,rabbitmq}
    
    info "Project structure created at /opt/${PROJECT_NAME}"
}

# Main deployment function
main() {
    log "Starting Lawvriksh Backend Deployment on Ubuntu 24.04"
    log "=================================================="
    
    check_root
    check_ubuntu_version
    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    generate_secrets
    create_project_structure
    
    log "=================================================="
    log "Basic system setup completed!"
    log "Next steps:"
    echo "1. Copy your backend code to /opt/${PROJECT_NAME}/"
    echo "2. Run: ./setup-production.sh"
    echo "3. Run: ./start-services.sh"
    log "=================================================="
}

# Run main function
main "$@"
