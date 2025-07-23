#!/bin/bash

# =============================================================================
# LawVriksh Production Deployment for lawvriksh.com
# =============================================================================
# Deploys:
# - Frontend: https://lawvriksh.com
# - Backend API: https://lawvriksh.com/api/
# - Admin Panel: https://lawvriksh.com/admin/login
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

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Display banner
show_banner() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🚀 LawVriksh Production Deployment"
    echo "=================================================================="
    echo "🌐 Frontend: https://$DOMAIN"
    echo "🔗 Backend API: https://$DOMAIN/api/"
    echo "👑 Admin Panel: https://$DOMAIN/admin/login"
    echo "📚 API Docs: https://$DOMAIN/docs"
    echo "=================================================================="
    echo -e "${NC}"
}

# Step 1: Build frontend
build_frontend() {
    log "Building frontend for production..."
    
    cd Frontend
    
    # Install dependencies
    if [[ ! -d "node_modules" ]]; then
        log "Installing frontend dependencies..."
        npm install
    fi
    
    # Build for production
    log "Building React application..."
    npm run build
    
    # Verify build
    if [[ -d "dist" && -f "dist/index.html" ]]; then
        success "Frontend build completed successfully"
        ls -la dist/
    else
        error "Frontend build failed - dist directory not found"
        exit 1
    fi
    
    cd ..
}

# Step 2: Create database initialization
create_database_init() {
    log "Creating database initialization script..."
    
    cat > init-db.sql << 'EOF'
-- LawVriksh Production Database Initialization
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

-- Create other tables
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

CREATE TABLE IF NOT EXISTS campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

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

# Step 3: Create environment file
create_env_file() {
    log "Creating production environment file..."
    
    cat > .env << EOF
# Production Environment Configuration
DOMAIN=lawvriksh.com
API_BASE_URL=https://lawvriksh.com/api
FRONTEND_URL=https://lawvriksh.com

# Database Configuration
DB_USER=lawvriksh_user
DB_PASSWORD=Sahil123
DB_NAME=lawvriksh_referral
MYSQL_ROOT_PASSWORD=Sahil123

# Security
JWT_SECRET_KEY=$(openssl rand -base64 64)

# Admin Configuration
ADMIN_EMAIL=sahilsaurav2507@gmail.com
ADMIN_PASSWORD=Sahil@123

# Application Settings
ENVIRONMENT=production
EOF
    
    success "Environment file created"
}

# Step 4: Deploy services
deploy_services() {
    log "Deploying services with Docker Compose..."
    
    # Stop any existing services
    docker-compose -f docker-compose.domain.yml down -v 2>/dev/null || true
    
    # Clean up Docker system
    docker system prune -f
    
    # Build and start services
    docker-compose -f docker-compose.domain.yml up -d --build
    
    success "Services deployment initiated"
}

# Step 5: Wait for services
wait_for_services() {
    log "Waiting for services to be ready..."
    
    # Wait for MySQL
    log "Waiting for MySQL to initialize..."
    sleep 60
    
    # Check MySQL health
    local mysql_ready=false
    for i in {1..10}; do
        if docker-compose -f docker-compose.domain.yml exec mysql mysqladmin ping -h localhost -u root -pSahil123 2>/dev/null; then
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
    
    # Wait for frontend
    log "Waiting for frontend to be ready..."
    sleep 10
    
    if curl -f http://localhost:3000/health 2>/dev/null; then
        success "Frontend is ready"
    else
        warning "Frontend may not be fully ready, continuing..."
    fi
    
    success "All services are ready"
}

# Step 6: Setup admin user
setup_admin_user() {
    log "Setting up admin user..."
    
    # Install bcrypt and run admin setup
    docker-compose -f docker-compose.domain.yml exec backend pip install bcrypt
    docker-compose -f docker-compose.domain.yml exec backend python setup_admin_corrected.py
    
    success "Admin user setup completed"
}

# Step 7: Configure Nginx
configure_nginx() {
    log "Configuring Nginx for production..."
    
    # Copy Nginx configuration
    sudo cp nginx-lawvriksh-production.conf /etc/nginx/sites-available/lawvriksh
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Enable LawVriksh site
    sudo ln -sf /etc/nginx/sites-available/lawvriksh /etc/nginx/sites-enabled/
    
    # Test configuration
    if sudo nginx -t; then
        success "Nginx configuration test passed"
        sudo systemctl reload nginx
        success "Nginx reloaded successfully"
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

# Step 8: Test deployment
test_deployment() {
    log "Testing deployment..."
    
    # Test backend health
    if curl -f http://localhost:8000/health &>/dev/null; then
        success "Backend health check passed"
    else
        warning "Backend health check failed"
    fi
    
    # Test frontend health
    if curl -f http://localhost:3000/health &>/dev/null; then
        success "Frontend health check passed"
    else
        warning "Frontend health check failed"
    fi
    
    # Test beta registration
    log "Testing beta registration..."
    curl -X POST http://localhost:8000/beta/signup \
      -H "Content-Type: application/json" \
      -d '{"name":"Test Beta User","email":"test@example.com"}' && echo ""
    
    # Test admin login
    log "Testing admin login..."
    curl -X POST http://localhost:8000/admin/login \
      -H "Content-Type: application/json" \
      -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' && echo ""
    
    success "Deployment testing completed"
}

# Main deployment function
main() {
    show_banner
    
    # Change to project directory
    if [[ "$(pwd)" != "$PROJECT_DIR" ]]; then
        if [[ -d "$PROJECT_DIR" ]]; then
            cd "$PROJECT_DIR"
        else
            warning "Project directory $PROJECT_DIR not found, using current directory"
        fi
    fi
    
    # Run deployment steps
    build_frontend
    create_database_init
    create_env_file
    deploy_services
    wait_for_services
    setup_admin_user
    configure_nginx
    test_deployment
    
    # Show final status
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🎉 LawVriksh Production Deployment Completed!"
    echo "=================================================================="
    echo -e "${NC}"
    
    info "Service Status:"
    docker-compose -f docker-compose.domain.yml ps
    
    echo ""
    info "Application URLs:"
    echo "  🌐 Frontend: https://$DOMAIN"
    echo "  🔗 Backend API: https://$DOMAIN/api/"
    echo "  📚 API Documentation: https://$DOMAIN/docs"
    echo "  👑 Admin Panel: https://$DOMAIN/admin/login"
    echo ""
    
    info "Next Steps:"
    echo "1. Setup SSL certificate: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    echo "2. Test your application at https://$DOMAIN"
    echo "3. Monitor logs: docker-compose -f docker-compose.domain.yml logs -f"
    
    success "🚀 LawVriksh is now live at https://$DOMAIN!"
}

# Run main function
main "$@"
