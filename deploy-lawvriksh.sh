#!/bin/bash

# =============================================================================
# LawVriksh One-Command Complete Deployment Script
# =============================================================================
# Complete deployment of LawVriksh on Ubuntu with Docker
# Includes: System setup, Docker, Services, Nginx, SSL, Testing
# 
# Usage: ./deploy-lawvriksh.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
step() { echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] 🚀 $1${NC}"; }

# Display main banner
show_main_banner() {
    clear
    echo -e "${GREEN}"
    cat << 'EOF'
================================================================
🚀 LawVriksh Complete Ubuntu Docker Deployment
================================================================
                    
    ██╗      █████╗ ██╗    ██╗██╗   ██╗██████╗ ██╗██╗  ██╗███████╗██╗  ██╗
    ██║     ██╔══██╗██║    ██║██║   ██║██╔══██╗██║██║ ██╔╝██╔════╝██║  ██║
    ██║     ███████║██║ █╗ ██║██║   ██║██████╔╝██║█████╔╝ ███████╗███████║
    ██║     ██╔══██║██║███╗██║╚██╗ ██╔╝██╔══██╗██║██╔═██╗ ╚════██║██╔══██║
    ███████╗██║  ██║╚███╔███╔╝ ╚████╔╝ ██║  ██║██║██║  ██╗███████║██║  ██║
    ╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝   ╚═══╝  ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                    
================================================================
🎯 Features: Beta Registration, Admin Panel, Analytics
🐳 Stack: Docker, MySQL, FastAPI, React, Nginx
🌐 Domain: lawvriksh.com
📁 Location: /opt/lawvriksh
================================================================
EOF
    echo -e "${NC}"
    
    info "This script will:"
    echo "  1. 🔧 Install system dependencies (Docker, Nginx, etc.)"
    echo "  2. 🔥 Setup firewall and security"
    echo "  3. 📁 Create project structure"
    echo "  4. 🐳 Deploy Docker services (MySQL, Backend, Frontend)"
    echo "  5. 🌐 Configure Nginx reverse proxy"
    echo "  6. 🔐 Setup SSL certificate (optional)"
    echo "  7. 🧪 Run comprehensive tests"
    echo ""
    
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Deployment cancelled by user"
        exit 0
    fi
}

# Check prerequisites
check_prerequisites() {
    step "Checking prerequisites..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        warning "This script is designed for Ubuntu. Current OS: $ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    success "OS check passed: $PRETTY_NAME"
    
    # Check permissions
    if [[ $EUID -eq 0 ]]; then
        warning "Running as root"
    elif sudo -n true 2>/dev/null; then
        success "Sudo access confirmed"
    else
        error "This script requires sudo access"
        exit 1
    fi
    
    # Check internet connectivity
    if ping -c 1 google.com &> /dev/null; then
        success "Internet connectivity confirmed"
    else
        error "No internet connectivity"
        exit 1
    fi
}

# Run system setup
run_system_setup() {
    step "Running system setup..."
    
    if [[ -f "./deploy-ubuntu-complete.sh" ]]; then
        chmod +x deploy-ubuntu-complete.sh
        ./deploy-ubuntu-complete.sh
    else
        error "deploy-ubuntu-complete.sh not found"
        exit 1
    fi
    
    success "System setup completed"
}

# Deploy services
deploy_application_services() {
    step "Deploying application services..."
    
    # Change to project directory
    cd $PROJECT_DIR
    
    if [[ -f "./deploy-services-complete.sh" ]]; then
        chmod +x deploy-services-complete.sh
        ./deploy-services-complete.sh
    else
        error "deploy-services-complete.sh not found"
        exit 1
    fi
    
    success "Application services deployed"
}

# Setup web server
setup_web_server() {
    step "Setting up web server..."
    
    cd $PROJECT_DIR
    
    if [[ -f "./setup-nginx.sh" ]]; then
        chmod +x setup-nginx.sh
        ./setup-nginx.sh
    else
        error "setup-nginx.sh not found"
        exit 1
    fi
    
    success "Web server configured"
}

# Run tests
run_deployment_tests() {
    step "Running deployment tests..."
    
    cd $PROJECT_DIR
    
    if [[ -f "./test-deployment.sh" ]]; then
        chmod +x test-deployment.sh
        ./test-deployment.sh
    else
        warning "test-deployment.sh not found, skipping tests"
    fi
    
    success "Deployment tests completed"
}

# Setup SSL certificate
setup_ssl_certificate() {
    step "SSL Certificate Setup"
    
    info "SSL certificate setup is optional but recommended for production."
    echo ""
    warning "Before setting up SSL, ensure:"
    echo "  • Your domain ($DOMAIN) points to this server's IP"
    echo "  • Port 80 and 443 are open in your firewall"
    echo "  • You have a valid email address for Let's Encrypt"
    echo ""
    
    read -p "Setup SSL certificate now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Setting up SSL certificate..."
        
        # Get email for Let's Encrypt
        read -p "Enter your email address for Let's Encrypt: " email
        
        if [[ -n "$email" ]]; then
            sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email "$email" --agree-tos --non-interactive
            success "SSL certificate installed successfully"
        else
            warning "No email provided, skipping SSL setup"
        fi
    else
        info "SSL setup skipped. You can run it later with:"
        echo "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    fi
}

# Show final status
show_final_status() {
    step "Deployment Summary"
    
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🎉 LawVriksh Deployment Completed!"
    echo "=================================================================="
    echo -e "${NC}"
    
    # Check service status
    info "Service Status:"
    cd $PROJECT_DIR
    docker-compose ps 2>/dev/null || echo "Docker services not found"
    
    echo ""
    info "Application URLs:"
    echo "  🌐 Frontend: http://$DOMAIN"
    echo "  🔗 Backend API: http://$DOMAIN/api/"
    echo "  📚 API Documentation: http://$DOMAIN/docs"
    echo "  👑 Admin Panel: http://$DOMAIN/admin/login"
    echo ""
    
    info "Admin Credentials:"
    echo "  📧 Email: sahilsaurav2507@gmail.com"
    echo "  🔑 Password: Sahil@123"
    echo ""
    
    info "Test Commands:"
    echo "  # Test beta registration"
    echo "  curl -X POST http://$DOMAIN/api/beta/signup \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"name\":\"Test User\",\"email\":\"test@example.com\"}'"
    echo ""
    echo "  # Test admin login"
    echo "  curl -X POST http://$DOMAIN/api/admin/login \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"email\":\"sahilsaurav2507@gmail.com\",\"password\":\"Sahil@123\"}'"
    echo ""
    
    info "Management Commands:"
    echo "  # View logs: cd $PROJECT_DIR && docker-compose logs -f"
    echo "  # Restart services: cd $PROJECT_DIR && docker-compose restart"
    echo "  # Update application: cd $PROJECT_DIR && git pull && docker-compose up -d --build"
    echo ""
    
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        success "SSL certificate is installed - your site is secure! 🔒"
        echo "  🔐 HTTPS: https://$DOMAIN"
    else
        warning "SSL certificate not installed. Run: sudo certbot --nginx -d $DOMAIN"
    fi
    
    echo ""
    success "🚀 LawVriksh is now live and ready for beta users!"
}

# Main deployment function
main() {
    # Show banner and get confirmation
    show_main_banner
    
    # Check prerequisites
    check_prerequisites
    
    # Run deployment steps
    log "Starting LawVriksh deployment..."
    
    # Step 1: System setup
    run_system_setup
    
    # Step 2: Deploy services
    deploy_application_services
    
    # Step 3: Setup web server
    setup_web_server
    
    # Step 4: Run tests
    run_deployment_tests
    
    # Step 5: Setup SSL (optional)
    setup_ssl_certificate
    
    # Step 6: Show final status
    show_final_status
    
    success "🎉 Complete deployment finished successfully!"
}

# Handle script interruption
trap 'error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@"
