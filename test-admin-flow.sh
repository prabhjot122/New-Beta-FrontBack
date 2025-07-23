#!/bin/bash

# =============================================================================
# LawVriksh Admin Flow Test Script
# =============================================================================
# Tests the complete admin flow to ensure everything works correctly
# Tests: Admin Login, Dashboard, User Management, Analytics, Email System
# 
# Usage: ./test-admin-flow.sh
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
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()
ADMIN_TOKEN=""

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

# Display admin test banner
show_admin_test_banner() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "👑 LawVriksh Admin Flow Test Suite"
    echo "=================================================================="
    echo "Admin Login URL: $FRONTEND_URL/admin/login"
    echo "Admin Dashboard: $FRONTEND_URL/admin/dashboard"
    echo "Admin API: $API_URL/admin"
    echo "Admin Credentials: $ADMIN_EMAIL / $ADMIN_PASSWORD"
    echo "=================================================================="
    echo -e "${NC}"
}

# Test admin login API
test_admin_login_api() {
    log "Testing admin login API..."
    
    # Test admin login endpoint
    local login_response=$(curl -s -X POST http://localhost:8000/admin/login \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
        -w "%{http_code}")
    
    if [[ "$login_response" == *"200"* ]]; then
        test_passed "Admin login API endpoint"
        
        # Extract token from response
        ADMIN_TOKEN=$(echo "$login_response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$ADMIN_TOKEN" ]]; then
            test_passed "Admin JWT token generation"
        else
            test_failed "Admin JWT token extraction failed"
        fi
    else
        test_failed "Admin login API endpoint failed"
        echo "Response: $login_response"
    fi
}

# Test admin authentication
test_admin_authentication() {
    log "Testing admin authentication..."
    
    # Test regular auth login endpoint (should work for admin too)
    local auth_response=$(curl -s -X POST http://localhost:8000/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
        -w "%{http_code}")
    
    if [[ "$auth_response" == *"200"* ]]; then
        test_passed "Admin authentication through auth endpoint"
    else
        test_failed "Admin authentication through auth endpoint failed"
    fi
    
    # Test admin user validation
    if [[ -n "$ADMIN_TOKEN" ]]; then
        local user_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            http://localhost:8000/auth/me \
            -w "%{http_code}")
        
        if [[ "$user_response" == *"200"* ]] && [[ "$user_response" == *"is_admin"* ]]; then
            test_passed "Admin user validation"
        else
            test_failed "Admin user validation failed"
        fi
    fi
}

# Test admin dashboard API
test_admin_dashboard_api() {
    log "Testing admin dashboard API..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        test_failed "Admin dashboard API (no token available)"
        return
    fi
    
    # Test dashboard endpoint
    local dashboard_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        http://localhost:8000/admin/dashboard \
        -w "%{http_code}")
    
    if [[ "$dashboard_response" == *"200"* ]]; then
        test_passed "Admin dashboard API"
        
        # Check if response contains expected fields
        if [[ "$dashboard_response" == *"overview"* ]] && [[ "$dashboard_response" == *"total_users"* ]]; then
            test_passed "Admin dashboard data structure"
        else
            test_failed "Admin dashboard data structure incomplete"
        fi
    else
        test_failed "Admin dashboard API failed"
        echo "Response: $dashboard_response"
    fi
}

# Test admin user management API
test_admin_user_management() {
    log "Testing admin user management API..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        test_failed "Admin user management API (no token available)"
        return
    fi
    
    # Test users list endpoint
    local users_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        "http://localhost:8000/admin/users?page=1&limit=10" \
        -w "%{http_code}")
    
    if [[ "$users_response" == *"200"* ]]; then
        test_passed "Admin users list API"
        
        # Check if response contains expected fields
        if [[ "$users_response" == *"users"* ]] && [[ "$users_response" == *"pagination"* ]]; then
            test_passed "Admin users list data structure"
        else
            test_failed "Admin users list data structure incomplete"
        fi
    else
        test_failed "Admin users list API failed"
    fi
    
    # Test user search
    local search_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        "http://localhost:8000/admin/users?search=admin&page=1&limit=10" \
        -w "%{http_code}")
    
    if [[ "$search_response" == *"200"* ]]; then
        test_passed "Admin user search API"
    else
        test_failed "Admin user search API failed"
    fi
}

# Test admin analytics API
test_admin_analytics() {
    log "Testing admin analytics API..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        test_failed "Admin analytics API (no token available)"
        return
    fi
    
    # Test analytics endpoint
    local analytics_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        http://localhost:8000/admin/analytics \
        -w "%{http_code}")
    
    if [[ "$analytics_response" == *"200"* ]]; then
        test_passed "Admin analytics API"
    else
        test_failed "Admin analytics API failed"
    fi
    
    # Test platform stats
    local stats_response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
        http://localhost:8000/admin/platform-stats \
        -w "%{http_code}")
    
    if [[ "$stats_response" == *"200"* ]]; then
        test_passed "Admin platform stats API"
    else
        test_failed "Admin platform stats API failed"
    fi
}

# Test admin bulk email API
test_admin_bulk_email() {
    log "Testing admin bulk email API..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        test_failed "Admin bulk email API (no token available)"
        return
    fi
    
    # Test bulk email endpoint (with test data)
    local email_response=$(curl -s -X POST \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"subject":"Test Email","body":"This is a test email","min_points":0}' \
        http://localhost:8000/admin/send-bulk-email \
        -w "%{http_code}")
    
    if [[ "$email_response" == *"200"* ]] || [[ "$email_response" == *"202"* ]]; then
        test_passed "Admin bulk email API"
    else
        warning "Admin bulk email API (may require email configuration)"
    fi
}

# Test admin frontend routes
test_admin_frontend_routes() {
    log "Testing admin frontend routes..."
    
    # Test admin login page
    if curl -f -s http://localhost:3000/admin/login > /dev/null; then
        test_passed "Admin login page accessibility"
    else
        test_failed "Admin login page not accessible"
    fi
    
    # Test admin dashboard page (should redirect to login if not authenticated)
    local dashboard_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/admin/dashboard)
    if [[ "$dashboard_status" == "200" ]] || [[ "$dashboard_status" == "302" ]]; then
        test_passed "Admin dashboard page routing"
    else
        test_failed "Admin dashboard page routing failed"
    fi
}

# Test admin database setup
test_admin_database_setup() {
    log "Testing admin database setup..."
    
    # Check if admin user exists in database
    local admin_check=$(docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-defaultpass} \
        -e "SELECT id, name, email, is_admin FROM lawvriksh_referral.users WHERE email='$ADMIN_EMAIL' AND is_admin=1;" \
        2>/dev/null | tail -n +2)
    
    if [[ -n "$admin_check" ]] && [[ "$admin_check" != *"ERROR"* ]]; then
        test_passed "Admin user exists in database"
        echo "Admin user details: $admin_check"
    else
        test_failed "Admin user not found in database"
    fi
    
    # Test admin password hash
    local password_check=$(docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD:-defaultpass} \
        -e "SELECT CASE WHEN password_hash LIKE '\$2b\$%' THEN 'VALID_BCRYPT' ELSE 'INVALID_HASH' END as hash_status FROM lawvriksh_referral.users WHERE email='$ADMIN_EMAIL';" \
        2>/dev/null | tail -n 1)
    
    if [[ "$password_check" == "VALID_BCRYPT" ]]; then
        test_passed "Admin password hash is valid bcrypt"
    else
        test_failed "Admin password hash is invalid"
    fi
}

# Test admin permissions
test_admin_permissions() {
    log "Testing admin permissions..."
    
    if [[ -z "$ADMIN_TOKEN" ]]; then
        test_failed "Admin permissions (no token available)"
        return
    fi
    
    # Test admin-only endpoints
    local admin_endpoints=(
        "/admin/dashboard:Dashboard access"
        "/admin/users:User management"
        "/admin/analytics:Analytics access"
        "/admin/platform-stats:Platform statistics"
    )
    
    for endpoint_info in "${admin_endpoints[@]}"; do
        local endpoint="${endpoint_info%%:*}"
        local description="${endpoint_info##*:}"
        
        local response=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            "http://localhost:8000$endpoint" \
            -w "%{http_code}")
        
        if [[ "$response" == *"200"* ]]; then
            test_passed "Admin permission: $description"
        else
            test_failed "Admin permission failed: $description"
        fi
    done
}

# Test admin flow integration
test_admin_flow_integration() {
    log "Testing complete admin flow integration..."
    
    # Test the complete flow: login -> dashboard -> users -> analytics
    if [[ -n "$ADMIN_TOKEN" ]]; then
        test_passed "Admin flow integration: Authentication successful"
        
        # Test dashboard access
        local dashboard_test=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            http://localhost:8000/admin/dashboard \
            -w "%{http_code}")
        
        if [[ "$dashboard_test" == *"200"* ]]; then
            test_passed "Admin flow integration: Dashboard accessible"
        else
            test_failed "Admin flow integration: Dashboard access failed"
        fi
        
        # Test user management access
        local users_test=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
            http://localhost:8000/admin/users \
            -w "%{http_code}")
        
        if [[ "$users_test" == *"200"* ]]; then
            test_passed "Admin flow integration: User management accessible"
        else
            test_failed "Admin flow integration: User management access failed"
        fi
    else
        test_failed "Admin flow integration: Authentication failed"
    fi
}

# Show admin test summary
show_admin_test_summary() {
    echo ""
    echo "=================================================================="
    echo "👑 Admin Flow Test Results Summary"
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
        success "All admin tests passed! 🎉"
    fi
    
    echo ""
    echo "=================================================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        success "🎉 Admin flow is working correctly!"
        info "Admin access details:"
        echo "  📧 Email: $ADMIN_EMAIL"
        echo "  🔑 Password: $ADMIN_PASSWORD"
        echo "  🌐 Login URL: $FRONTEND_URL/admin/login"
        echo "  📊 Dashboard: $FRONTEND_URL/admin/dashboard"
        echo "  🔗 API Docs: $API_URL/docs"
    else
        warning "⚠️  Some admin tests failed. Please check the issues above."
        info "Common fixes:"
        echo "  • Verify admin user: docker-compose exec backend python verify_admin.py"
        echo "  • Reset admin user: docker-compose exec backend python setup_admin.py"
        echo "  • Check admin credentials in .env file"
        echo "  • Restart backend: docker-compose restart backend"
    fi
    
    echo "=================================================================="
}

# Main admin test function
main() {
    show_admin_test_banner
    
    # Change to deployment directory if it exists
    if [[ -d "/opt/lawvriksh" ]]; then
        cd /opt/lawvriksh
        log "Running admin tests from /opt/lawvriksh"
    else
        log "Running admin tests from current directory"
    fi
    
    # Run all admin tests
    test_admin_database_setup
    test_admin_login_api
    test_admin_authentication
    test_admin_dashboard_api
    test_admin_user_management
    test_admin_analytics
    test_admin_bulk_email
    test_admin_frontend_routes
    test_admin_permissions
    test_admin_flow_integration
    
    # Show summary
    show_admin_test_summary
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
