#!/bin/bash

# =============================================================================
# LawVriksh Deployment Test Script
# =============================================================================
# Tests the complete deployment to ensure everything works correctly
# Tests: Frontend, Backend API, Beta Registration, Admin Setup, Nginx
# 
# Usage: ./test-deployment.sh
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
FRONTEND_URL="https://$DOMAIN"
API_URL="https://$DOMAIN/api"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Test result functions
test_passed() {
    ((TESTS_PASSED++))
    success "$1"
}

test_failed() {
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
    error "$1"
}

# Display test banner
show_test_banner() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🧪 LawVriksh Deployment Test Suite"
    echo "=================================================================="
    echo "Frontend URL: $FRONTEND_URL"
    echo "Backend API: $API_URL"
    echo "=================================================================="
    echo -e "${NC}"
}

# Test Docker services
test_docker_services() {
    log "Testing Docker services..."
    
    # Check if docker-compose is running
    if docker-compose ps | grep -q "Up"; then
        test_passed "Docker services are running"
    else
        test_failed "Docker services are not running"
        return 1
    fi
    
    # Check individual services
    local services=("mysql" "redis" "backend" "frontend")
    for service in "${services[@]}"; do
        if docker-compose ps | grep "$service" | grep -q "Up"; then
            test_passed "Service $service is running"
        else
            test_failed "Service $service is not running"
        fi
    done
}

# Test backend health
test_backend_health() {
    log "Testing backend health..."
    
    # Test local backend health
    if curl -f -s http://localhost:8000/health > /dev/null; then
        test_passed "Backend health check (localhost:8000)"
    else
        test_failed "Backend health check failed (localhost:8000)"
    fi
    
    # Test backend through nginx (if SSL is configured)
    if curl -f -s -k "$API_URL/health" > /dev/null; then
        test_passed "Backend health check through nginx ($API_URL/health)"
    else
        warning "Backend health check through nginx failed (SSL may not be configured yet)"
    fi
}

# Test frontend health
test_frontend_health() {
    log "Testing frontend health..."
    
    # Test local frontend
    if curl -f -s http://localhost:3000 > /dev/null; then
        test_passed "Frontend is accessible (localhost:3000)"
    else
        test_failed "Frontend is not accessible (localhost:3000)"
    fi
    
    # Test frontend through nginx (if SSL is configured)
    if curl -f -s -k "$FRONTEND_URL" > /dev/null; then
        test_passed "Frontend is accessible through nginx ($FRONTEND_URL)"
    else
        warning "Frontend through nginx failed (SSL may not be configured yet)"
    fi
}

# Test beta registration API
test_beta_registration() {
    log "Testing beta registration API..."
    
    # Test beta health endpoint
    if curl -f -s http://localhost:8000/beta/health > /dev/null; then
        test_passed "Beta service health check"
    else
        test_failed "Beta service health check failed"
    fi
    
    # Test beta stats endpoint
    if curl -f -s http://localhost:8000/beta/stats > /dev/null; then
        test_passed "Beta stats endpoint"
    else
        test_failed "Beta stats endpoint failed"
    fi
    
    # Test beta registration endpoint (with test data)
    local test_email="test-$(date +%s)@example.com"
    local test_response=$(curl -s -X POST http://localhost:8000/beta/signup \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Test User\",\"email\":\"$test_email\"}" \
        -w "%{http_code}")
    
    if [[ "$test_response" == *"201"* ]] || [[ "$test_response" == *"400"* ]]; then
        test_passed "Beta registration endpoint is working"
    else
        test_failed "Beta registration endpoint failed"
    fi
}

# Test admin setup
test_admin_setup() {
    log "Testing admin setup..."

    # Test admin login endpoint
    local admin_login_response=$(curl -s -X POST http://localhost:8000/admin/login \
        -H "Content-Type: application/json" \
        -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' \
        -w "%{http_code}")

    if [[ "$admin_login_response" == *"200"* ]]; then
        test_passed "Admin login endpoint"

        # Extract token for further tests
        local admin_token=$(echo "$admin_login_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

        if [[ -n "$admin_token" ]]; then
            # Test admin dashboard
            local dashboard_response=$(curl -s -H "Authorization: Bearer $admin_token" \
                http://localhost:8000/admin/dashboard \
                -w "%{http_code}")

            if [[ "$dashboard_response" == *"200"* ]]; then
                test_passed "Admin dashboard API"
            else
                test_failed "Admin dashboard API failed"
            fi

            # Test admin users endpoint
            local users_response=$(curl -s -H "Authorization: Bearer $admin_token" \
                http://localhost:8000/admin/users \
                -w "%{http_code}")

            if [[ "$users_response" == *"200"* ]]; then
                test_passed "Admin users management API"
            else
                test_failed "Admin users management API failed"
            fi
        fi
    else
        test_failed "Admin login endpoint failed"
    fi
}

# Test admin flow
test_admin_flow() {
    log "Testing admin flow..."

    # Test admin-specific login endpoint
    local admin_api_response=$(curl -s -X POST http://localhost:8000/admin/login \
        -H "Content-Type: application/json" \
        -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' \
        -w "%{http_code}")

    if [[ "$admin_api_response" == *"200"* ]]; then
        test_passed "Admin API login endpoint"

        # Extract token for further tests
        local admin_token=$(echo "$admin_api_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

        if [[ -n "$admin_token" ]]; then
            # Test admin dashboard
            local dashboard_response=$(curl -s -H "Authorization: Bearer $admin_token" \
                http://localhost:8000/admin/dashboard \
                -w "%{http_code}")

            if [[ "$dashboard_response" == *"200"* ]]; then
                test_passed "Admin dashboard API"
            else
                test_failed "Admin dashboard API failed"
            fi

            # Test admin users endpoint
            local users_response=$(curl -s -H "Authorization: Bearer $admin_token" \
                http://localhost:8000/admin/users \
                -w "%{http_code}")

            if [[ "$users_response" == *"200"* ]]; then
                test_passed "Admin users management API"
            else
                test_failed "Admin users management API failed"
            fi
        fi
    else
        test_failed "Admin API login endpoint failed"
    fi

    # Test admin frontend route
    if curl -f -s http://localhost:3000/admin/login > /dev/null; then
        test_passed "Admin login page accessibility"
    else
        test_failed "Admin login page not accessible"
    fi
}

# Test nginx configuration
test_nginx_configuration() {
    log "Testing nginx configuration..."
    
    # Test nginx configuration syntax
    if sudo nginx -t > /dev/null 2>&1; then
        test_passed "Nginx configuration syntax"
    else
        test_failed "Nginx configuration syntax error"
    fi
    
    # Check if nginx is running
    if systemctl is-active --quiet nginx; then
        test_passed "Nginx service is running"
    else
        test_failed "Nginx service is not running"
    fi
    
    # Check if lawvriksh site is enabled
    if [[ -f "/etc/nginx/sites-enabled/lawvriksh" ]]; then
        test_passed "LawVriksh nginx site is enabled"
    else
        test_failed "LawVriksh nginx site is not enabled"
    fi
}

# Test database connectivity
test_database() {
    log "Testing database connectivity..."
    
    # Test MySQL connection
    if docker-compose exec -T mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-defaultpass} > /dev/null 2>&1; then
        test_passed "MySQL database connectivity"
    else
        test_failed "MySQL database connectivity failed"
    fi
    
    # Test if admin user exists in database
    local admin_check=$(docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-defaultpass} -e "SELECT COUNT(*) FROM lawvriksh_referral.users WHERE email='sahilsaurav2507@gmail.com' AND is_admin=1;" 2>/dev/null | tail -n 1)
    
    if [[ "$admin_check" == "1" ]]; then
        test_passed "Admin user exists in database"
    else
        test_failed "Admin user not found in database"
    fi
}

# Test SSL certificate (if configured)
test_ssl_certificate() {
    log "Testing SSL certificate..."
    
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        test_passed "SSL certificate exists"
        
        # Test SSL certificate validity
        if openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -checkend 86400 > /dev/null 2>&1; then
            test_passed "SSL certificate is valid"
        else
            test_failed "SSL certificate is expired or invalid"
        fi
    else
        warning "SSL certificate not found (run: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN)"
    fi
}

# Test API endpoints
test_api_endpoints() {
    log "Testing API endpoints..."
    
    local endpoints=(
        "/health:Health check"
        "/docs:API documentation"
        "/beta/health:Beta service health"
        "/beta/stats:Beta statistics"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        local endpoint="${endpoint_info%%:*}"
        local description="${endpoint_info##*:}"
        
        if curl -f -s "http://localhost:8000$endpoint" > /dev/null; then
            test_passed "$description endpoint ($endpoint)"
        else
            test_failed "$description endpoint failed ($endpoint)"
        fi
    done
}

# Test firewall configuration
test_firewall() {
    log "Testing firewall configuration..."
    
    if command -v ufw > /dev/null && ufw status | grep -q "Status: active"; then
        test_passed "UFW firewall is active"
        
        # Check if required ports are allowed
        if ufw status | grep -q "80/tcp"; then
            test_passed "HTTP port (80) is allowed"
        else
            test_failed "HTTP port (80) is not allowed"
        fi
        
        if ufw status | grep -q "443/tcp"; then
            test_passed "HTTPS port (443) is allowed"
        else
            test_failed "HTTPS port (443) is not allowed"
        fi
    else
        warning "UFW firewall is not active"
    fi
}

# Show test summary
show_test_summary() {
    echo ""
    echo "=================================================================="
    echo "🧪 Test Results Summary"
    echo "=================================================================="
    
    success "Tests Passed: $TESTS_PASSED"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        error "Tests Failed: $TESTS_FAILED"
        echo ""
        error "Failed Tests:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo "  ❌ $failed_test"
        done
    else
        success "All tests passed! 🎉"
    fi
    
    echo ""
    echo "=================================================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "🎉 Deployment is working correctly!"
        info "Next steps:"
        echo "  • Set up SSL certificate: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
        echo "  • Test the application at: $FRONTEND_URL"
        echo "  • Test the API at: $API_URL/docs"
        echo "  • Login as admin: sahilsaurav2507@gmail.com / Sahil@123"
    else
        warning "⚠️  Some tests failed. Please check the issues above."
        info "Common fixes:"
        echo "  • Restart services: docker-compose restart"
        echo "  • Check logs: docker-compose logs -f"
        echo "  • Verify environment: cat .env"
    fi
    
    echo "=================================================================="
}

# Main test function
main() {
    show_test_banner
    
    # Change to deployment directory if it exists
    if [[ -d "/opt/lawvriksh" ]]; then
        cd /opt/lawvriksh
        log "Running tests from /opt/lawvriksh"
    else
        log "Running tests from current directory"
    fi
    
    # Run all tests
    test_docker_services
    test_backend_health
    test_frontend_health
    test_beta_registration
    test_admin_setup
    test_admin_flow
    test_nginx_configuration
    test_database
    test_ssl_certificate
    test_api_endpoints
    test_firewall
    
    # Show summary
    show_test_summary
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
