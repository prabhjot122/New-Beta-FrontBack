#!/bin/bash

# =============================================================================
# Lawvriksh Backend Health Check Script
# =============================================================================
# This script performs comprehensive health checks on all services
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COMPOSE_FILE="docker-compose.production.yml"
API_URL="http://localhost:8000"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Check Docker services
check_docker_services() {
    log "Checking Docker services..."
    
    services=("mysql" "rabbitmq" "redis" "backend" "celery-worker" "celery-beat")
    all_healthy=true
    
    for service in "${services[@]}"; do
        if docker-compose -f $COMPOSE_FILE ps $service | grep -q "Up"; then
            success "$service is running"
        else
            fail "$service is not running"
            all_healthy=false
        fi
    done
    
    if $all_healthy; then
        success "All Docker services are running"
    else
        fail "Some Docker services are not running"
    fi
    
    return $all_healthy
}

# Check API health endpoint
check_api_health() {
    log "Checking API health endpoint..."
    
    if curl -f -s "${API_URL}/health" > /dev/null; then
        success "API health endpoint is responding"
        
        # Get detailed health info
        health_response=$(curl -s "${API_URL}/health")
        echo "Health Response: $health_response"
    else
        fail "API health endpoint is not responding"
        return 1
    fi
}

# Check database connectivity
check_database() {
    log "Checking database connectivity..."
    
    if docker-compose -f $COMPOSE_FILE exec -T mysql mysqladmin ping -h localhost --silent; then
        success "Database is responding"
        
        # Check database size
        db_size=$(docker-compose -f $COMPOSE_FILE exec -T mysql mysql -e "
            SELECT 
                ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size (MB)'
            FROM information_schema.tables 
            WHERE table_schema = 'lawvriksh_production';" --skip-column-names -s)
        
        info "Database size: ${db_size} MB"
    else
        fail "Database is not responding"
        return 1
    fi
}

# Check RabbitMQ
check_rabbitmq() {
    log "Checking RabbitMQ..."
    
    if docker-compose -f $COMPOSE_FILE exec -T rabbitmq rabbitmq-diagnostics -q ping; then
        success "RabbitMQ is responding"
        
        # Check queue status
        queue_info=$(docker-compose -f $COMPOSE_FILE exec -T rabbitmq rabbitmqctl list_queues name messages 2>/dev/null || echo "Unable to get queue info")
        info "Queue info: $queue_info"
    else
        fail "RabbitMQ is not responding"
        return 1
    fi
}

# Check Redis
check_redis() {
    log "Checking Redis..."
    
    if docker-compose -f $COMPOSE_FILE exec -T redis redis-cli ping | grep -q "PONG"; then
        success "Redis is responding"
        
        # Check Redis info
        redis_info=$(docker-compose -f $COMPOSE_FILE exec -T redis redis-cli info memory | grep used_memory_human || echo "Unable to get Redis info")
        info "Redis memory usage: $redis_info"
    else
        fail "Redis is not responding"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    
    # Check available disk space
    disk_usage=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -lt 80 ]; then
        success "Disk space is adequate (${disk_usage}% used)"
    elif [ "$disk_usage" -lt 90 ]; then
        warning "Disk space is getting low (${disk_usage}% used)"
    else
        fail "Disk space is critically low (${disk_usage}% used)"
    fi
    
    # Show detailed disk usage
    info "Disk usage details:"
    df -h .
}

# Check memory usage
check_memory() {
    log "Checking memory usage..."
    
    # Get memory info
    memory_info=$(free -h)
    echo "$memory_info"
    
    # Check if memory usage is high
    memory_percent=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ "$memory_percent" -lt 80 ]; then
        success "Memory usage is normal (${memory_percent}%)"
    elif [ "$memory_percent" -lt 90 ]; then
        warning "Memory usage is high (${memory_percent}%)"
    else
        fail "Memory usage is critically high (${memory_percent}%)"
    fi
}

# Check SSL certificate
check_ssl() {
    log "Checking SSL certificate..."
    
    if command -v openssl >/dev/null 2>&1; then
        # Check certificate expiration
        cert_info=$(echo | openssl s_client -servername www.lawvriksh.com -connect www.lawvriksh.com:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "Unable to check SSL")
        
        if [[ "$cert_info" != "Unable to check SSL" ]]; then
            success "SSL certificate is valid"
            echo "$cert_info"
        else
            warning "Unable to check SSL certificate (domain may not be configured yet)"
        fi
    else
        warning "OpenSSL not available, skipping SSL check"
    fi
}

# Check log files
check_logs() {
    log "Checking log files..."
    
    log_dirs=("logs/backend" "logs/mysql" "logs/rabbitmq" "logs/redis" "logs/celery")
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            log_size=$(du -sh "$log_dir" 2>/dev/null | cut -f1 || echo "0")
            info "$log_dir: $log_size"
            
            # Check for recent errors
            error_count=$(find "$log_dir" -name "*.log" -mtime -1 -exec grep -i "error\|exception\|failed" {} \; 2>/dev/null | wc -l || echo "0")
            if [ "$error_count" -gt 0 ]; then
                warning "Found $error_count recent errors in $log_dir"
            fi
        else
            warning "$log_dir directory not found"
        fi
    done
}

# Performance test
performance_test() {
    log "Running basic performance test..."
    
    # Test API response time
    start_time=$(date +%s.%N)
    if curl -f -s "${API_URL}/health" > /dev/null; then
        end_time=$(date +%s.%N)
        response_time=$(echo "$end_time - $start_time" | bc -l)
        response_time_ms=$(echo "$response_time * 1000" | bc -l | cut -d. -f1)
        
        if [ "$response_time_ms" -lt 500 ]; then
            success "API response time is good (${response_time_ms}ms)"
        elif [ "$response_time_ms" -lt 1000 ]; then
            warning "API response time is acceptable (${response_time_ms}ms)"
        else
            fail "API response time is slow (${response_time_ms}ms)"
        fi
    else
        fail "Unable to test API performance"
    fi
}

# Generate health report
generate_report() {
    log "Generating health report..."
    
    report_file="health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "Lawvriksh Backend Health Report"
        echo "==============================="
        echo "Generated: $(date)"
        echo ""
        echo "System Information:"
        echo "- OS: $(uname -a)"
        echo "- Uptime: $(uptime)"
        echo ""
        echo "Docker Information:"
        docker --version
        docker-compose --version
        echo ""
        echo "Service Status:"
        docker-compose -f $COMPOSE_FILE ps
        echo ""
        echo "Resource Usage:"
        echo "Memory:"
        free -h
        echo ""
        echo "Disk:"
        df -h
        echo ""
        echo "Docker Stats:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    } > "$report_file"
    
    info "Health report saved to: $report_file"
}

# Main health check function
main() {
    log "Starting Lawvriksh Backend Health Check"
    log "======================================="
    
    overall_health=true
    
    # Run all health checks
    check_docker_services || overall_health=false
    echo
    check_api_health || overall_health=false
    echo
    check_database || overall_health=false
    echo
    check_rabbitmq || overall_health=false
    echo
    check_redis || overall_health=false
    echo
    check_disk_space
    echo
    check_memory
    echo
    check_ssl
    echo
    check_logs
    echo
    performance_test
    echo
    
    # Generate report if requested
    if [[ "${1:-}" == "--report" ]]; then
        generate_report
    fi
    
    log "======================================="
    if $overall_health; then
        success "Overall system health: GOOD"
        exit 0
    else
        fail "Overall system health: ISSUES DETECTED"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "--report")
        main --report
        ;;
    "--docker")
        check_docker_services
        ;;
    "--api")
        check_api_health
        ;;
    "--database")
        check_database
        ;;
    "--performance")
        performance_test
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [--report|--docker|--api|--database|--performance]"
        echo "  --report      - Generate detailed health report"
        echo "  --docker      - Check only Docker services"
        echo "  --api         - Check only API health"
        echo "  --database    - Check only database"
        echo "  --performance - Run only performance test"
        exit 1
        ;;
esac
