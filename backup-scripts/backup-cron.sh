#!/bin/sh

# =============================================================================
# LawVriksh Database Backup Script
# Runs daily at 2 AM, retains 4 days of backups
# Sends backup to Gmail: sahilsaurav2507@gmail.com
# =============================================================================

# Install required packages
apk add --no-cache mysql-client curl msmtp ca-certificates tzdata

# Set timezone
cp /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
echo "Asia/Kolkata" > /etc/timezone

# Configure msmtp for email
cat > /etc/msmtprc << EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        hostinger
host           ${SMTP_HOST}
port           ${SMTP_PORT}
from           ${SMTP_USER}
user           ${SMTP_USER}
password       ${SMTP_PASSWORD}

account default : hostinger
EOF

chmod 600 /etc/msmtprc

# Create backup function
backup_database() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="/backups/lawvriksh_backup_${TIMESTAMP}.sql"
    
    echo "$(date): Starting database backup..."
    
    # Create backup
    mysqldump -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASSWORD} \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --add-drop-database \
        --databases ${DB_NAME} > ${BACKUP_FILE}
    
    if [ $? -eq 0 ]; then
        echo "$(date): Database backup created successfully: ${BACKUP_FILE}"
        
        # Compress backup
        gzip ${BACKUP_FILE}
        BACKUP_FILE="${BACKUP_FILE}.gz"
        
        # Get file size
        BACKUP_SIZE=$(du -h ${BACKUP_FILE} | cut -f1)
        
        # Send email notification
        send_backup_email ${BACKUP_FILE} ${BACKUP_SIZE} "SUCCESS"
        
        # Clean old backups (keep 4 days)
        find /backups -name "lawvriksh_backup_*.sql.gz" -mtime +4 -delete
        
        echo "$(date): Backup completed successfully"
    else
        echo "$(date): Database backup failed"
        send_backup_email "" "" "FAILED"
    fi
}

# Send email notification
send_backup_email() {
    local backup_file=$1
    local backup_size=$2
    local status=$3
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    if [ "$status" = "SUCCESS" ]; then
        subject="✅ LawVriksh Database Backup Successful - $(date +%Y-%m-%d)"
        body="Database backup completed successfully!

Backup Details:
- Timestamp: ${timestamp}
- File: $(basename ${backup_file})
- Size: ${backup_size}
- Database: ${DB_NAME}
- Status: SUCCESS

The backup has been stored securely and old backups have been cleaned up.

This is an automated message from LawVriksh Backup Service."
    else
        subject="❌ LawVriksh Database Backup Failed - $(date +%Y-%m-%d)"
        body="Database backup failed!

Backup Details:
- Timestamp: ${timestamp}
- Database: ${DB_NAME}
- Status: FAILED

Please check the backup service logs and ensure the database is accessible.

This is an automated message from LawVriksh Backup Service."
    fi
    
    # Send email
    echo "Subject: ${subject}
To: ${BACKUP_EMAIL}
From: ${SMTP_USER}

${body}" | msmtp ${BACKUP_EMAIL}
    
    echo "$(date): Email notification sent to ${BACKUP_EMAIL}"
}

# Setup cron job
setup_cron() {
    echo "$(date): Setting up cron job for daily backups at 2 AM..."
    
    # Create cron job
    echo "0 2 * * * /scripts/backup-cron.sh backup" > /var/spool/cron/crontabs/root
    
    # Start crond
    crond -f -d 8 &
    
    echo "$(date): Cron job configured successfully"
}

# Main execution
case "$1" in
    "backup")
        backup_database
        ;;
    *)
        echo "$(date): Starting LawVriksh Backup Service..."
        
        # Create backup directory
        mkdir -p /backups
        
        # Setup cron
        setup_cron
        
        # Run initial backup
        backup_database
        
        # Keep container running
        while true; do
            sleep 3600  # Sleep for 1 hour
        done
        ;;
esac
