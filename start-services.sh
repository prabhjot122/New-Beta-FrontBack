#!/bin/bash

# =============================================================================
# Lawvriksh Backend Service Startup Script
# =============================================================================
# This script starts all production services for the Lawvriksh backend
# Run this after setup-production.sh completes successfully
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="lawvriksh-backend"
COMPOSE_FILE="docker-compose.production.yml"

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

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker first."
    fi
    
    # Check if docker-compose file exists
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        error "$COMPOSE_FILE not found. Please run setup-production.sh first."
    fi
    
    # Check if environment file exists
    if [[ ! -f ".env.production" ]]; then
        error ".env.production not found. Please run setup-production.sh first."
    fi
    
    info "Prerequisites check passed"
}

# Initialize database
init_database() {
    log "Initializing database..."
    
    # Start only MySQL first
    docker-compose -f $COMPOSE_FILE up -d mysql
    
    # Wait for MySQL to be ready
    info "Waiting for MySQL to be ready..."
    timeout=60
    while ! docker-compose -f $COMPOSE_FILE exec mysql mysqladmin ping -h localhost --silent; do
        sleep 2
        timeout=$((timeout - 2))
        if [[ $timeout -le 0 ]]; then
            error "MySQL failed to start within 60 seconds"
        fi
    done
    
    # Run database initialization if needed
    if [[ -f "init_db.py" ]]; then
        info "Running database initialization..."
        docker-compose -f $COMPOSE_FILE run --rm backend python init_db.py
    fi
    
    info "Database initialization completed"
}

# Start all services
start_services() {
    log "Starting all services..."
    
    # Build and start all services
    docker-compose -f $COMPOSE_FILE up -d --build
    
    # Wait for services to be healthy
    info "Waiting for services to be healthy..."
    
    services=("mysql" "rabbitmq" "redis" "backend")
    for service in "${services[@]}"; do
        info "Checking $service..."
        timeout=120
        while ! docker-compose -f $COMPOSE_FILE ps $service | grep -q "healthy\|Up"; do
            sleep 5
            timeout=$((timeout - 5))
            if [[ $timeout -le 0 ]]; then
                warning "$service may not be fully ready, but continuing..."
                break
            fi
        done
    done
    
    info "All services started"
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if all containers are running
    info "Container status:"
    docker-compose -f $COMPOSE_FILE ps
    
    # Test API health endpoint
    info "Testing API health endpoint..."
    sleep 10  # Give services time to fully start
    
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        info "✅ API health check passed"
    else
        warning "❌ API health check failed - services may still be starting"
    fi
    
    # Test database connection
    info "Testing database connection..."
    if docker-compose -f $COMPOSE_FILE exec -T backend python -c "
from app.core.dependencies import get_db
try:
    db = next(get_db())
    print('✅ Database connection successful')
    db.close()
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
        info "✅ Database connection verified"
    else
        warning "❌ Database connection test failed"
    fi
    
    # Show service URLs
    echo
    info "=== Service URLs ==="
    echo "🌐 API Documentation: http://localhost:8000/docs"
    echo "📊 API Health Check: http://localhost:8000/health"
    echo "🐰 RabbitMQ Management: http://localhost:15672 (admin/admin)"
    echo "📈 Prometheus Metrics: http://localhost:8000/metrics"
    echo
    info "=== Production URLs (after DNS setup) ==="
    echo "🌐 Frontend: https://www.lawvriksh.com"
    echo "🔗 API: https://www.lawvriksh.com/api/"
    echo "📚 API Docs: https://www.lawvriksh.com/api/docs"
    echo
}

# Setup systemd service (optional)
setup_systemd_service() {
    log "Setting up systemd service for auto-start..."
    
    sudo tee /etc/systemd/system/lawvriksh-backend.service << EOF
[Unit]
Description=Lawvriksh Backend Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose -f $COMPOSE_FILE up -d
ExecStop=/usr/local/bin/docker-compose -f $COMPOSE_FILE down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable lawvriksh-backend.service
    
    info "Systemd service configured for auto-start on boot"
}

# Show logs
show_logs() {
    log "Showing recent logs..."
    docker-compose -f $COMPOSE_FILE logs --tail=50
}

# Main function
main() {
    log "Starting Lawvriksh Backend Services"
    log "==================================="
    
    check_prerequisites
    init_database
    start_services
    verify_deployment
    
    # Ask if user wants to setup systemd service
    echo
    read -p "Setup systemd service for auto-start on boot? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_systemd_service
    fi
    
    # Ask if user wants to see logs
    echo
    read -p "Show service logs? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs
    fi
    
    log "==================================="
    log "🎉 Lawvriksh Backend is now running!"
    log ""
    log "Next steps:"
    echo "1. Point your domain DNS to this server's IP"
    echo "2. Test the API at: http://your-server-ip:8000/health"
    echo "3. Access API docs at: http://your-server-ip:8000/docs"
    echo "4. Monitor logs with: docker-compose -f $COMPOSE_FILE logs -f"
    echo "5. Stop services with: docker-compose -f $COMPOSE_FILE down"
    log "==================================="
}

# Handle command line arguments
case "${1:-}" in
    "logs")
        docker-compose -f $COMPOSE_FILE logs -f
        ;;
    "stop")
        log "Stopping all services..."
        docker-compose -f $COMPOSE_FILE down
        ;;
    "restart")
        log "Restarting all services..."
        docker-compose -f $COMPOSE_FILE restart
        ;;
    "status")
        docker-compose -f $COMPOSE_FILE ps
        ;;
    "")
        main "$@"
        ;;
    *)
        echo "Usage: $0 [logs|stop|restart|status]"
        echo "  logs    - Show and follow logs"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  status  - Show service status"
        exit 1
        ;;
esac
