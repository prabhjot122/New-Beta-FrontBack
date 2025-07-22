#!/bin/bash

# =============================================================================
# Lawvriksh Backend Backup Script
# =============================================================================
# This script creates backups of the database and important files
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
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Create backup directory
create_backup_dir() {
    mkdir -p $BACKUP_DIR
    info "Backup directory: $BACKUP_DIR"
}

# Backup database
backup_database() {
    log "Creating database backup..."
    
    # Load environment variables
    source .env.production
    
    # Create database dump
    docker-compose -f $COMPOSE_FILE exec -T mysql mysqldump \
        -u root -p${MYSQL_ROOT_PASSWORD} \
        --single-transaction \
        --routines \
        --triggers \
        ${DB_NAME} > ${BACKUP_DIR}/database_${DATE}.sql
    
    # Compress the backup
    gzip ${BACKUP_DIR}/database_${DATE}.sql
    
    info "Database backup created: ${BACKUP_DIR}/database_${DATE}.sql.gz"
}

# Backup application files
backup_files() {
    log "Creating application files backup..."
    
    # Create tar archive of important files
    tar -czf ${BACKUP_DIR}/files_${DATE}.tar.gz \
        --exclude='logs/*' \
        --exclude='cache/*' \
        --exclude='backups/*' \
        --exclude='.git/*' \
        --exclude='__pycache__/*' \
        --exclude='*.pyc' \
        .
    
    info "Files backup created: ${BACKUP_DIR}/files_${DATE}.tar.gz"
}

# Backup Docker volumes
backup_volumes() {
    log "Creating Docker volumes backup..."
    
    # Backup MySQL data
    docker run --rm \
        -v lawvriksh-mysql-data:/data \
        -v $(pwd)/${BACKUP_DIR}:/backup \
        alpine tar -czf /backup/mysql_volume_${DATE}.tar.gz -C /data .
    
    # Backup RabbitMQ data
    docker run --rm \
        -v lawvriksh-rabbitmq-data:/data \
        -v $(pwd)/${BACKUP_DIR}:/backup \
        alpine tar -czf /backup/rabbitmq_volume_${DATE}.tar.gz -C /data .
    
    # Backup Redis data
    docker run --rm \
        -v lawvriksh-redis-data:/data \
        -v $(pwd)/${BACKUP_DIR}:/backup \
        alpine tar -czf /backup/redis_volume_${DATE}.tar.gz -C /data .
    
    info "Docker volumes backup completed"
}

# Clean old backups (keep last 7 days)
cleanup_old_backups() {
    log "Cleaning up old backups (keeping last 7 days)..."
    
    find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
    find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
    
    info "Old backups cleaned up"
}

# Create backup summary
create_summary() {
    log "Creating backup summary..."
    
    cat > ${BACKUP_DIR}/backup_${DATE}_summary.txt << EOF
Lawvriksh Backend Backup Summary
================================
Date: $(date)
Backup ID: ${DATE}

Files Created:
- database_${DATE}.sql.gz (Database dump)
- files_${DATE}.tar.gz (Application files)
- mysql_volume_${DATE}.tar.gz (MySQL volume)
- rabbitmq_volume_${DATE}.tar.gz (RabbitMQ volume)
- redis_volume_${DATE}.tar.gz (Redis volume)

Backup Location: ${BACKUP_DIR}

To restore:
1. Database: gunzip -c database_${DATE}.sql.gz | docker-compose exec -T mysql mysql -u root -p${DB_NAME}
2. Files: tar -xzf files_${DATE}.tar.gz
3. Volumes: Use restore.sh script

EOF
    
    info "Backup summary created: ${BACKUP_DIR}/backup_${DATE}_summary.txt"
}

# Main backup function
main() {
    log "Starting Lawvriksh Backend Backup"
    log "================================="
    
    create_backup_dir
    backup_database
    backup_files
    backup_volumes
    cleanup_old_backups
    create_summary
    
    log "================================="
    log "Backup completed successfully!"
    log "Backup ID: ${DATE}"
    log "Location: ${BACKUP_DIR}"
    log "================================="
}

# Handle command line arguments
case "${1:-}" in
    "database")
        create_backup_dir
        backup_database
        ;;
    "files")
        create_backup_dir
        backup_files
        ;;
    "volumes")
        create_backup_dir
        backup_volumes
        ;;
    "")
        main "$@"
        ;;
    *)
        echo "Usage: $0 [database|files|volumes]"
        echo "  database - Backup only database"
        echo "  files    - Backup only application files"
        echo "  volumes  - Backup only Docker volumes"
        exit 1
        ;;
esac
