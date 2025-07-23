#!/bin/bash

# =============================================================================
# LawVriksh Complete Flow Verification Script
# =============================================================================
# Verifies both beta user registration and admin flows work correctly
# Tests: Beta signup, Admin login, Dashboard, User management, Analytics
# 
# Usage: ./verify-complete-flow.sh
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
ADMIN_EMAIL="sahilsaurav2507@gmail.com"
ADMIN_PASSWORD="Sahil@123"

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

# Test results tracking
BETA_TESTS_PASSED=0
BETA_TESTS_FAILED=0
ADMIN_TESTS_PASSED=0
ADMIN_TESTS_FAILED=0
FAILED_TESTS=()

# Test result functions
beta_test_passed() {
    ((BETA_TESTS_PASSED++))
    success "Beta: $1"
}

beta_test_failed() {
    ((BETA_TESTS_FAILED++))
    FAILED_TESTS+=("Beta: $1")
    error "Beta: $1"
}

admin_test_passed() {
    ((ADMIN_TESTS_PASSED++))
    success "Admin: $1"
}

admin_test_failed() {
    ((ADMIN_TESTS_FAILED++))
    FAILED_TESTS+=("Admin: $1")
    error "Admin: $1"
}

# Display verification banner
show_verification_banner() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🔍 LawVriksh Complete Flow Verification"
    echo "=================================================================="
    echo "Frontend: $FRONTEND_URL"
    echo "Backend API: $API_URL"
    echo ""
    echo "Testing Flows:"
    echo "  🎯 Beta User Registration (name + email)"
    echo "  👑 Admin Authentication & Management"
    echo "=================================================================="
    echo -e "${NC}"
}

# Test beta user registration flow
test_beta_registration_flow() {
    log "Testing Beta User Registration Flow..."
    
    # Test beta service health
    if curl -f -s http://localhost:8000/beta/health > /dev/null; then
        beta_test_passed "Beta service health check"
    else
        beta_test_failed "Beta service health check failed"
    fi
    
    # Test beta stats endpoint
    if curl -f -s http://localhost:8000/beta/stats > /dev/null; then
        beta_test_passed "Beta statistics endpoint"
    else
        beta_test_failed "Beta statistics endpoint failed"
    fi
    
    # Test beta registration with sample data
    local test_email="test-beta-$(date +%s)@example.com"
    local beta_signup_response=$(curl -s -X POST http://localhost:8000/beta/signup \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"Test Beta User\",\"email\":\"$test_email\"}" \
        -w "%{http_code}")
    
    if [[ "$beta_signup_response" == *"201"* ]]; then
        beta_test_passed "Beta user registration API"
        
        # Check if response contains expected fields
        if [[ "$beta_signup_response" == *"user_id"* ]] && [[ "$beta_signup_response" == *"message"* ]]; then
            beta_test_passed "Beta registration response structure"
        else
            beta_test_failed "Beta registration response structure incomplete"
        fi
    else
        beta_test_failed "Beta user registration API failed"
        echo "Response: $beta_signup_response"
    fi
    
    # Test frontend beta form accessibility
    if curl -f -s http://localhost:3000 > /dev/null; then
        beta_test_passed "Frontend beta form page accessibility"
    else
        beta_test_failed "Frontend beta form page not accessible"
    fi
}

# Test admin authentication flow
test_admin_authentication_flow() {
    log "Testing Admin Authentication Flow..."
    
    # Test admin login page
    if curl -f -s http://localhost:3000/admin/login > /dev/null; then
        admin_test_passed "Admin login page accessibility"
    else
        admin_test_failed "Admin login page not accessible"
    fi
    
    # Test admin login API
    local admin_login_response=$(curl -s -X POST http://localhost:8000/admin/login \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
        -w "%{http_code}")
    
    if [[ "$admin_login_response" == *"200"* ]]; then
        admin_test_passed "Admin login API"
        
        # Extract admin token
        ADMIN_TOKEN=$(echo "$admin_login_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        
        if [[ -n "$ADMIN_TOKEN" ]]; then
            admin_test_passed "Admin JWT token generation"
        else
            admin_test_failed "Admin JWT token extraction failed"
        fi
    else
        admin_test_failed "Admin login API failed"
        echo "Response: $admin_login_response"
    fi
    
    # Test regular auth endpoint for admin
    local auth_response=$(curl -s -X POST http://localhost:8000/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
        -w "%{http_code}")
    
    if [[ "$auth_response" == *"200"* ]]; then
        admin_test_passed "Admin authentication through auth endpoint"
    else
        admin_test_failed "Admin authentication through auth endpoint failed"
    fi
}

# Test admin dashboard flow
test_admin_dashboard_flow() {
    log "Testing Admin Dashboard Flow..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        admin_test_failed "Admin dashboard flow (no token available)"
        return
    fi
    
    # Test admin dashboard API
    local dashboard_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        http://localhost:8000/admin/dashboard \
        -w "%{http_code}")
    
    if [[ "$dashboard_response" == *"200"* ]]; then
        admin_test_passed "Admin dashboard API"
        
        # Check dashboard data structure
        if [[ "$dashboard_response" == *"overview"* ]] && [[ "$dashboard_response" == *"total_users"* ]]; then
            admin_test_passed "Dashboard data structure"
        else
            admin_test_failed "Dashboard data structure incomplete"
        fi
    else
        admin_test_failed "Admin dashboard API failed"
    fi
    
    # Test admin users management
    local users_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        "http://localhost:8000/admin/users?page=1&limit=10" \
        -w "%{http_code}")
    
    if [[ "$users_response" == *"200"* ]]; then
        admin_test_passed "Admin users management API"
        
        # Check users data structure
        if [[ "$users_response" == *"users"* ]] && [[ "$users_response" == *"pagination"* ]]; then
            admin_test_passed "Users management data structure"
        else
            admin_test_failed "Users management data structure incomplete"
        fi
    else
        admin_test_failed "Admin users management API failed"
    fi
    
    # Test admin analytics
    local analytics_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        http://localhost:8000/admin/analytics \
        -w "%{http_code}")
    
    if [[ "$analytics_response" == *"200"* ]]; then
        admin_test_passed "Admin analytics API"
    else
        admin_test_failed "Admin analytics API failed"
    fi
}

# Test complete integration flow
test_integration_flow() {
    log "Testing Complete Integration Flow..."
    
    # Test that beta users appear in admin dashboard
    if [[ -n "$ADMIN_TOKEN" ]]; then
        local stats_before=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            http://localhost:8000/beta/stats)
        
        if [[ "$stats_before" == *"total_beta_users"* ]]; then
            admin_test_passed "Beta stats accessible to admin"
        else
            admin_test_failed "Beta stats not accessible to admin"
        fi
        
        # Test admin can see all users including beta users
        local all_users=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            "http://localhost:8000/admin/users?page=1&limit=100")
        
        if [[ "$all_users" == *"users"* ]]; then
            admin_test_passed "Admin can access all users including beta users"
        else
            admin_test_failed "Admin cannot access user list"
        fi
    fi
    
    # Test frontend routing integration
    local frontend_routes=("/" "/admin/login" "/thank-you")
    for route in "${frontend_routes[@]}"; do
        if curl -f -s "http://localhost:3000$route" > /dev/null; then
            beta_test_passed "Frontend route accessible: $route"
        else
            beta_test_failed "Frontend route not accessible: $route"
        fi
    done
}

# Test database integration
test_database_integration() {
    log "Testing Database Integration..."
    
    # Check if admin user exists and has correct properties
    local admin_check=$(docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-defaultpass} \
        -e "SELECT id, name, email, is_admin, is_active FROM lawvriksh_referral.users WHERE email='$ADMIN_EMAIL';" \
        2>/dev/null | tail -n +2)
    
    if [[ -n "$admin_check" ]] && [[ "$admin_check" == *"1"* ]]; then
        admin_test_passed "Admin user exists in database with correct properties"
    else
        admin_test_failed "Admin user not found or incorrect properties in database"
    fi
    
    # Check if beta users table structure supports the flow
    local table_check=$(docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-defaultpass} \
        -e "DESCRIBE lawvriksh_referral.users;" 2>/dev/null)
    
    if [[ "$table_check" == *"name"* ]] && [[ "$table_check" == *"email"* ]] && [[ "$table_check" == *"is_admin"* ]]; then
        beta_test_passed "Database schema supports beta and admin flows"
    else
        beta_test_failed "Database schema incomplete for beta/admin flows"
    fi
}

# Show complete verification summary
show_verification_summary() {
    echo ""
    echo "=================================================================="
    echo "🔍 Complete Flow Verification Results"
    echo "=================================================================="
    
    echo ""
    info "Beta User Registration Flow:"
    success "  Tests Passed: $BETA_TESTS_PASSED"
    if [[ $BETA_TESTS_FAILED -gt 0 ]]; then
        error "  Tests Failed: $BETA_TESTS_FAILED"
    fi
    
    echo ""
    info "Admin Management Flow:"
    success "  Tests Passed: $ADMIN_TESTS_PASSED"
    if [[ $ADMIN_TESTS_FAILED -gt 0 ]]; then
        error "  Tests Failed: $ADMIN_TESTS_FAILED"
    fi
    
    local total_passed=$((BETA_TESTS_PASSED + ADMIN_TESTS_PASSED))
    local total_failed=$((BETA_TESTS_FAILED + ADMIN_TESTS_FAILED))
    
    echo ""
    echo "=================================================================="
    success "Total Tests Passed: $total_passed"
    
    if [[ $total_failed -gt 0 ]]; then
        error "Total Tests Failed: $total_failed"
        echo ""
        error "Failed Tests:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo "  ❌ $failed_test"
        done
    else
        success "All flows working perfectly! 🎉"
    fi
    
    echo ""
    echo "=================================================================="
    
    if [[ $total_failed -eq 0 ]]; then
        success "🎉 Complete LawVriksh platform is working correctly!"
        echo ""
        info "Beta User Flow:"
        echo "  🌐 Visit: $FRONTEND_URL"
        echo "  📝 Fill beta form with name + email"
        echo "  ✅ User registered and welcome email sent"
        echo ""
        info "Admin Management Flow:"
        echo "  🔐 Login: $FRONTEND_URL/admin/login"
        echo "  👤 Credentials: $ADMIN_EMAIL / $ADMIN_PASSWORD"
        echo "  📊 Dashboard: $FRONTEND_URL/admin/dashboard"
        echo "  👥 Manage users, analytics, and campaigns"
    else
        warning "⚠️  Some flows have issues. Please check the failed tests above."
        info "Common fixes:"
        echo "  • Restart services: docker-compose restart"
        echo "  • Check logs: docker-compose logs -f"
        echo "  • Verify admin setup: docker-compose exec backend python verify_admin.py"
        echo "  • Test individual components: ./test-admin-flow.sh"
    fi
    
    echo "=================================================================="
}

# Main verification function
main() {
    show_verification_banner
    
    # Change to deployment directory if it exists
    if [[ -d "/opt/lawvriksh" ]]; then
        cd /opt/lawvriksh
        log "Running verification from /opt/lawvriksh"
    else
        log "Running verification from current directory"
    fi
    
    # Run all flow tests
    test_beta_registration_flow
    test_admin_authentication_flow
    test_admin_dashboard_flow
    test_integration_flow
    test_database_integration
    
    # Show summary
    show_verification_summary
    
    # Exit with appropriate code
    local total_failed=$((BETA_TESTS_FAILED + ADMIN_TESTS_FAILED))
    if [[ $total_failed -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
