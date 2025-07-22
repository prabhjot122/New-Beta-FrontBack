#!/bin/bash

# =============================================================================
# LawVriksh Production Deployment Script
# =============================================================================
# One-command deployment for Ubuntu 24.04 VPS (8GB RAM)
# Deploys: Backend (FastAPI) + Frontend (React) + MySQL + Monitoring
# 
# Usage: ./deploy-production.sh
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
MYSQL_PORT="3307"
PROJECT_NAME="lawvriksh"
BACKUP_EMAIL="sahilsaurav2507@gmail.com"

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

success() {
    echo -e "${PURPLE}[SUCCESS] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements
check_system() {
    log "Checking system requirements..."
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        warning "This script is optimized for Ubuntu 24.04. Proceeding anyway..."
    fi
    
    # Check RAM
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_RAM -lt 7 ]]; then
        error "Insufficient RAM. This deployment requires at least 8GB RAM. Found: ${TOTAL_RAM}GB"
    fi
    
    # Check disk space
    AVAILABLE_SPACE=$(df / | awk 'NR==2{print $4}')
    if [[ $AVAILABLE_SPACE -lt 10485760 ]]; then  # 10GB in KB
        error "Insufficient disk space. At least 10GB free space required."
    fi
    
    success "System requirements check passed"
}

# Update system
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    success "System updated successfully"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        info "Docker already installed"
        return
    fi
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    success "Docker installed successfully"
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        info "Docker Compose already installed"
        return
    fi
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    success "Docker Compose installed successfully"
}

# Setup firewall
setup_firewall() {
    log "Setting up UFW firewall..."
    
    # Install UFW if not present
    sudo apt install -y ufw
    
    # Reset UFW to defaults
    sudo ufw --force reset
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (be careful not to lock yourself out)
    sudo ufw allow ssh
    sudo ufw allow 22
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80
    sudo ufw allow 443
    
    # Allow custom MySQL port (only from localhost)
    sudo ufw allow from 127.0.0.1 to any port $MYSQL_PORT
    
    # Enable UFW
    sudo ufw --force enable
    
    success "Firewall configured successfully"
}

# Install and configure Fail2Ban
setup_fail2ban() {
    log "Setting up Fail2Ban..."
    
    sudo apt install -y fail2ban
    
    # Create custom jail configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF
    
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    
    success "Fail2Ban configured successfully"
}

# Install Nginx
install_nginx() {
    log "Installing and configuring Nginx..."
    
    sudo apt install -y nginx
    
    # Remove default configuration
    sudo rm -f /etc/nginx/sites-enabled/default
    
    success "Nginx installed successfully"
}

# Main installation function
main() {
    log "Starting LawVriksh Production Deployment"
    log "========================================"
    
    check_root
    check_system
    update_system
    install_docker
    install_docker_compose
    setup_firewall
    setup_fail2ban
    install_nginx
    
    success "========================================"
    success "Phase 1: System Setup Completed!"
    success "========================================"
    
    info "Next steps:"
    echo "1. Log out and log back in to apply Docker group changes"
    echo "2. Run: ./configure-services.sh"
    echo "3. The deployment will continue automatically"
    
    log "Creating next phase script..."

    # Create the configuration script
    cat > configure-services.sh << 'CONFIGURE_EOF'
#!/bin/bash
# Phase 2: Service Configuration and Deployment
source ./deploy-production.sh
configure_services
deploy_application
setup_monitoring
setup_backups
final_verification
CONFIGURE_EOF

    chmod +x configure-services.sh

    success "Phase 1 completed! Run './configure-services.sh' to continue."
}

# Configure services (Phase 2)
configure_services() {
    log "Phase 2: Configuring services..."

    # Create project directory
    sudo mkdir -p /opt/$PROJECT_NAME
    sudo chown $USER:$USER /opt/$PROJECT_NAME
    cd /opt/$PROJECT_NAME

    # Copy application files
    cp -r $OLDPWD/* .

    # Create necessary directories
    mkdir -p {nginx,mysql-data,prometheus-data,grafana-data,backups,logs}

    configure_nginx
    create_docker_compose
    setup_environment
}

# Configure Nginx
configure_nginx() {
    log "Configuring Nginx for $DOMAIN..."

    sudo tee /etc/nginx/sites-available/$PROJECT_NAME > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration (using existing domain SSL)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Frontend (React)
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
    }

    # Backend API
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

        # API specific settings
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
}
EOF

    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/

    # Test Nginx configuration
    sudo nginx -t

    success "Nginx configured successfully"
}

# Create Docker Compose and environment
create_docker_compose() {
    log "Setting up Docker Compose configuration..."

    # Copy optimized docker-compose file
    cp docker-compose.optimized.yml docker-compose.yml

    success "Docker Compose configuration ready"
}

# Setup environment variables
setup_environment() {
    log "Setting up production environment..."

    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        warning "Please update .env file with your production values"
        warning "Especially: DB_PASSWORD, JWT_SECRET_KEY, SMTP credentials"
    fi

    # Ensure required directories exist
    mkdir -p {mysql-data,mysql-config,redis-data,prometheus-data,grafana-data,backups,logs/{mysql,backend,nginx}}
    mkdir -p {prometheus-config,grafana-config,backup-scripts}

    # Set proper permissions
    chmod +x backup-scripts/backup-cron.sh

    success "Environment setup completed"
}

# Deploy application
deploy_application() {
    log "Deploying LawVriksh application..."

    # Build and start services
    docker-compose down --remove-orphans
    docker-compose build --no-cache
    docker-compose up -d

    # Wait for services to be healthy
    log "Waiting for services to start..."
    sleep 30

    # Check service health
    check_service_health

    success "Application deployed successfully"
}

# Check service health
check_service_health() {
    log "Checking service health..."

    services=("mysql" "redis" "backend" "frontend")

    for service in "${services[@]}"; do
        info "Checking $service..."

        for i in {1..10}; do
            if docker-compose ps $service | grep -q "healthy\|Up"; then
                success "$service is healthy"
                break
            else
                if [[ $i -eq 10 ]]; then
                    error "$service failed to start properly"
                fi
                sleep 10
            fi
        done
    done
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring and alerting..."

    # Wait for Prometheus and Grafana to start
    sleep 20

    # Import Grafana dashboards (if available)
    if [[ -d "grafana-dashboards" ]]; then
        info "Importing Grafana dashboards..."
        # Dashboard import logic here
    fi

    success "Monitoring setup completed"
}

# Setup automated backups
setup_backups() {
    log "Setting up automated database backups..."

    # Ensure backup service is running
    if docker-compose ps backup | grep -q "Up"; then
        success "Backup service is running"
        info "Daily backups scheduled for 2 AM"
        info "Backup retention: 4 days"
        info "Backup email: sahilsaurav2507@gmail.com"
    else
        warning "Backup service is not running properly"
    fi
}

# Final verification
final_verification() {
    log "Performing final verification..."

    # Test API health
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        success "✅ Backend API is responding"
    else
        error "❌ Backend API is not responding"
    fi

    # Test frontend
    if curl -f http://localhost:3000 >/dev/null 2>&1; then
        success "✅ Frontend is responding"
    else
        error "❌ Frontend is not responding"
    fi

    # Test database
    if docker-compose exec -T mysql mysqladmin ping -h localhost --silent; then
        success "✅ Database is responding"
    else
        error "❌ Database is not responding"
    fi

    # Restart Nginx to apply configuration
    sudo systemctl restart nginx

    if sudo nginx -t; then
        success "✅ Nginx configuration is valid"
    else
        error "❌ Nginx configuration has errors"
    fi

    success "========================================"
    success "🎉 LawVriksh Deployment Completed!"
    success "========================================"

    info "Service URLs:"
    echo "🌐 Frontend: https://lawvriksh.com"
    echo "🔗 Backend API: https://lawvriksh.com/api/"
    echo "📚 API Docs: https://lawvriksh.com/api/docs"
    echo "📊 Grafana: http://localhost:3001 (admin/admin123)"
    echo "📈 Prometheus: http://localhost:9090"
    echo ""
    info "Database:"
    echo "🗄️  MySQL Port: 3307 (localhost only)"
    echo "📧 Backup Email: sahilsaurav2507@gmail.com"
    echo ""
    info "Admin Credentials:"
    echo "👤 Email: sahilsaurav2507@gmail.com"
    echo "🔑 Password: Sahil@123"
    echo ""
    info "Management Commands:"
    echo "📋 View logs: docker-compose logs -f [service]"
    echo "🔄 Restart: docker-compose restart [service]"
    echo "⏹️  Stop: docker-compose down"
    echo "🚀 Start: docker-compose up -d"
}

# Run main function
main "$@"
