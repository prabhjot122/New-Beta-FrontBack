#!/bin/bash

# =============================================================================
# LawVriksh Deployment Health Check Script
# =============================================================================
# Quick health check for all services after deployment
# Tests: Database, Backend API, Frontend, CORS, Authentication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:3000"
PRODUCTION_BACKEND="https://lawvriksh.com/api"
PRODUCTION_FRONTEND="https://lawvriksh.com"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

test_passed() {
    ((TESTS_PASSED++))
    success "$1"
}

test_failed() {
    ((TESTS_FAILED++))
    error "$1"
}

# Health check functions
check_service_health() {
    local service_name="$1"
    local url="$2"
    
    log "Checking $service_name health..."
    
    if curl -f -s --max-time 10 "$url" > /dev/null 2>&1; then
        test_passed "$service_name is healthy"
    else
        test_failed "$service_name health check failed"
    fi
}

check_api_endpoints() {
    local base_url="$1"
    local env_name="$2"
    
    log "Testing $env_name API endpoints..."
    
    # Health endpoint
    if curl -f -s --max-time 5 "$base_url/health" | grep -q "healthy" 2>/dev/null; then
        test_passed "$env_name health endpoint"
    else
        test_failed "$env_name health endpoint"
    fi
    
    # Beta endpoints
    if curl -f -s --max-time 5 "$base_url/beta/health" > /dev/null 2>&1; then
        test_passed "$env_name beta service"
    else
        test_failed "$env_name beta service"
    fi
    
    # API docs
    if curl -f -s --max-time 5 "$base_url/docs" > /dev/null 2>&1; then
        test_passed "$env_name API documentation"
    else
        test_failed "$env_name API documentation"
    fi
}

check_cors() {
    local api_url="$1"
    local origin="$2"
    local env_name="$3"
    
    log "Testing $env_name CORS configuration..."
    
    local cors_response=$(curl -s --max-time 5 \
        -H "Origin: $origin" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        -X OPTIONS "$api_url/health" -I 2>/dev/null || echo "")
    
    if echo "$cors_response" | grep -q "Access-Control-Allow-Origin"; then
        test_passed "$env_name CORS headers"
    else
        test_failed "$env_name CORS headers missing"
    fi
}

check_database_schema() {
    local api_url="$1"
    local env_name="$2"
    
    log "Testing $env_name database schema..."
    
    # Try to get beta stats (requires database)
    if curl -f -s --max-time 5 "$api_url/beta/stats" > /dev/null 2>&1; then
        test_passed "$env_name database connectivity"
    else
        test_failed "$env_name database connectivity"
    fi
}

# Main execution
main() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🏥 LawVriksh Deployment Health Check"
    echo "=================================================================="
    echo -e "${NC}"
    
    # Check local development environment
    log "Checking local development environment..."
    check_service_health "Local Backend" "$BACKEND_URL/health"
    check_service_health "Local Frontend" "$FRONTEND_URL"
    check_api_endpoints "$BACKEND_URL" "Local"
    check_cors "$BACKEND_URL" "http://localhost:3000" "Local"
    check_database_schema "$BACKEND_URL" "Local"
    
    echo ""
    
    # Check production environment
    log "Checking production environment..."
    check_service_health "Production Backend" "$PRODUCTION_BACKEND/health"
    check_service_health "Production Frontend" "$PRODUCTION_FRONTEND"
    check_api_endpoints "$PRODUCTION_BACKEND" "Production"
    check_cors "$PRODUCTION_BACKEND" "https://lawvriksh.com" "Production"
    check_database_schema "$PRODUCTION_BACKEND" "Production"
    
    # Summary
    echo ""
    echo -e "${GREEN}=================================================================="
    echo "📊 Health Check Summary"
    echo "=================================================================="
    echo -e "✅ Tests Passed: $TESTS_PASSED"
    echo -e "❌ Tests Failed: $TESTS_FAILED"
    echo -e "📈 Success Rate: $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED) ))%"
    echo "=================================================================="
    echo -e "${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All health checks passed! Deployment is healthy.${NC}"
        exit 0
    else
        echo -e "${RED}💥 Some health checks failed. Please review the issues above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
