#!/bin/bash

# =============================================================================
# LawVriksh One-Command Deployment Script
# =============================================================================
# Complete deployment for Ubuntu 24.04 VPS
# Deploys: Frontend + Backend + Database + Nginx + SSL + Admin Setup
# 
# Usage: chmod +x deploy-one-command.sh && ./deploy-one-command.sh
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

# Display banner
show_banner() {
    echo -e "${GREEN}"
    echo "=============================================="
    echo "🚀 LawVriksh One-Command Deployment"
    echo "=============================================="
    echo "Domain: $DOMAIN"
    echo "Frontend: https://$DOMAIN"
    echo "Backend API: https://$DOMAIN/api"
    echo "=============================================="
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for security reasons"
        error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu 24.04" /etc/os-release; then
        warning "This script is optimized for Ubuntu 24.04"
        warning "Continuing anyway, but some steps might fail"
    fi
    
    # Check if required files exist
    local required_files=("deploy-full-stack.sh" "deploy-services.sh")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            error "Required file not found: $file"
            exit 1
        fi
    done
    
    success "Prerequisites check passed"
}

# Confirm deployment
confirm_deployment() {
    echo ""
    warning "⚠️  IMPORTANT: This will deploy LawVriksh to production"
    warning "⚠️  Make sure your domain $DOMAIN points to this server"
    echo ""
    info "This deployment will:"
    echo "  • Install Docker and Docker Compose"
    echo "  • Configure Nginx for $DOMAIN"
    echo "  • Deploy MySQL, Redis, Backend, and Frontend"
    echo "  • Create admin user: sahilsaurav2507@gmail.com"
    echo "  • Setup SSL certificate (requires manual confirmation)"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Deployment cancelled by user"
        exit 0
    fi
}

# Run system setup
run_system_setup() {
    log "Running system setup..."
    
    chmod +x deploy-full-stack.sh
    if ./deploy-full-stack.sh; then
        success "System setup completed successfully"
    else
        error "System setup failed"
        exit 1
    fi
}

# Run services deployment
run_services_deployment() {
    log "Running services deployment..."
    
    # Change to project directory
    cd /opt/$PROJECT_NAME
    
    chmod +x deploy-services.sh
    if ./deploy-services.sh; then
        success "Services deployment completed successfully"
    else
        error "Services deployment failed"
        exit 1
    fi
}

# Setup SSL certificate
setup_ssl() {
    log "Setting up SSL certificate..."
    
    echo ""
    info "Setting up SSL certificate for $DOMAIN"
    warning "You will need to confirm the certificate setup"
    echo ""
    
    if sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN; then
        success "SSL certificate setup completed"
    else
        warning "SSL certificate setup failed or was skipped"
        warning "You can run this command later:"
        echo "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    cd /opt/$PROJECT_NAME
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        success "Docker services are running"
    else
        warning "Some Docker services may not be running"
    fi
    
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
    
    # Verify admin setup
    if docker-compose exec -T backend python verify_admin.py &>/dev/null; then
        success "Admin user verification passed"
    else
        warning "Admin user verification failed"
    fi
}

# Show final summary
show_summary() {
    success "=============================================="
    success "🎉 LawVriksh Deployment Completed!"
    success "=============================================="
    
    info "Service URLs:"
    echo "🌐 Frontend: https://$DOMAIN"
    echo "🔗 Backend API: https://$DOMAIN/api"
    echo "📚 API Documentation: https://$DOMAIN/api/docs"
    echo ""
    
    info "Admin Access:"
    echo "👤 Email: sahilsaurav2507@gmail.com"
    echo "🔑 Password: Sahil@123"
    echo ""
    
    info "Management Commands (run from /opt/$PROJECT_NAME):"
    echo "📋 View logs: docker-compose logs -f [service]"
    echo "🔄 Restart: docker-compose restart [service]"
    echo "⏹️  Stop: docker-compose down"
    echo "🚀 Start: docker-compose up -d"
    echo "🔍 Status: docker-compose ps"
    echo ""
    
    info "Important Files:"
    echo "📁 Project directory: /opt/$PROJECT_NAME"
    echo "🔧 Environment: /opt/$PROJECT_NAME/.env"
    echo "📊 Logs: /opt/$PROJECT_NAME/logs/"
    echo ""
    
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        success "SSL certificate is installed and active"
    else
        warning "SSL certificate not found. Run:"
        echo "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    fi
    
    echo ""
    success "Deployment completed successfully! 🎉"
    info "Test your application at: https://$DOMAIN"
}

# Main deployment function
main() {
    show_banner
    check_prerequisites
    confirm_deployment
    
    log "Starting complete deployment process..."
    
    # Phase 1: System Setup
    log "Phase 1: System Setup"
    run_system_setup
    
    # Phase 2: Services Deployment
    log "Phase 2: Services Deployment"
    run_services_deployment
    
    # Phase 3: SSL Setup
    log "Phase 3: SSL Certificate Setup"
    setup_ssl
    
    # Phase 4: Verification
    log "Phase 4: Deployment Verification"
    verify_deployment
    
    # Show summary
    show_summary
}

# Handle script interruption
trap 'error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
