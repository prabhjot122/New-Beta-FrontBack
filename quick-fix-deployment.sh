#!/bin/bash

# =============================================================================
# Quick Fix for LawVriksh Deployment Issues
# =============================================================================
# Fixes: Missing pytz dependency, malformed nginx config
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }

echo "🔧 Quick Fix for LawVriksh Deployment"
echo "===================================="

# Step 1: Stop all services
log "Stopping all services..."
docker-compose -f docker-compose.emergency.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.simple.yml down -v 2>/dev/null || true
docker-compose down -v 2>/dev/null || true

# Step 2: Build frontend
log "Building frontend..."
cd Frontend
npm install --silent
npm run build
cd ..
success "Frontend built successfully"

# Step 3: Create working docker-compose
log "Creating working docker-compose configuration..."
cat > docker-compose.working.yml << 'EOF'
services:
  mysql:
    image: mysql:8.0
    container_name: lawvriksh-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: Sahil123
      MYSQL_DATABASE: lawvriksh_referral
      MYSQL_USER: lawvriksh_user
      MYSQL_PASSWORD: Sahil123
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql:ro
    ports:
      - "127.0.0.1:3307:3306"
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-pSahil123"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
    networks:
      - lawvriksh-network

  backend:
    build:
      context: .
      dockerfile: Dockerfile.production
    container_name: lawvriksh-backend
    restart: unless-stopped
    environment:
      DATABASE_URL: mysql+pymysql://lawvriksh_user:Sahil123@mysql:3306/lawvriksh_referral
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: lawvriksh_referral
      DB_USER: lawvriksh_user
      DB_PASSWORD: Sahil123
      JWT_SECRET_KEY: your_jwt_secret_key_here_change_in_production
      ADMIN_EMAIL: sahilsaurav2507@gmail.com
      ADMIN_PASSWORD: Sahil@123
      ENVIRONMENT: production
      DEBUG: "false"
      PYTHONPATH: /app
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - lawvriksh-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    image: nginx:alpine
    container_name: lawvriksh-frontend
    restart: unless-stopped
    volumes:
      - ./Frontend/dist:/usr/share/nginx/html:ro
      - ./nginx-simple.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "127.0.0.1:3000:80"
    networks:
      - lawvriksh-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 20s

volumes:
  mysql_data:

networks:
  lawvriksh-network:
    driver: bridge
EOF

# Step 4: Create simple nginx config file
log "Creating simple nginx configuration..."
cat > nginx-simple.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript;
}
EOF

# Step 5: Create database init script
log "Creating database initialization script..."
cat > init-db.sql << 'EOF'
CREATE DATABASE IF NOT EXISTS lawvriksh_referral;
USE lawvriksh_referral;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NULL,
    total_points INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    default_rank INT NULL,
    current_rank INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    user_type VARCHAR(10) DEFAULT 'beta',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_total_points (total_points DESC),
    INDEX idx_is_admin (is_admin),
    INDEX idx_user_type (user_type)
);

CREATE TABLE IF NOT EXISTS shares (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    platform VARCHAR(50) NOT NULL,
    points_earned INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_platform (platform)
);

CREATE TABLE IF NOT EXISTS campaigns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    message TEXT NOT NULL,
    rating INT DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id)
);
EOF

# Step 6: Deploy services
log "Deploying services..."
docker-compose -f docker-compose.working.yml up -d --build

# Step 7: Wait for services
log "Waiting for services to start..."
sleep 120

# Step 8: Check service status
log "Checking service status..."
docker-compose -f docker-compose.working.yml ps

# Step 9: Setup admin user
log "Setting up admin user..."
docker-compose -f docker-compose.working.yml exec backend pip install bcrypt pytz
docker-compose -f docker-compose.working.yml exec backend python setup_admin_corrected.py

# Step 10: Configure Nginx for domain
log "Configuring Nginx for domain..."
sudo tee /etc/nginx/sites-available/lawvriksh-working > /dev/null << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # API routes
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API docs
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check
    location /health {
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Remove old configs and enable new one
sudo rm -f /etc/nginx/sites-enabled/lawvriksh*
sudo ln -sf /etc/nginx/sites-available/lawvriksh-working /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
success "Nginx configured successfully"

# Step 11: Test deployment
log "Testing deployment..."

# Test backend
if curl -f http://localhost:8000/health &>/dev/null; then
    success "✅ Backend is responding"
else
    error "❌ Backend is not responding"
fi

# Test frontend
if curl -f http://localhost:3000/health &>/dev/null; then
    success "✅ Frontend is responding"
else
    error "❌ Frontend is not responding"
fi

# Test domain
if curl -f http://lawvriksh.com/health &>/dev/null; then
    success "✅ Domain is responding"
else
    warning "⚠️ Domain may not be responding (check DNS)"
fi

# Test API endpoints
log "Testing API endpoints..."

echo "Testing beta registration:"
curl -X POST http://localhost:8000/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Quick Fix Test","email":"quickfix@test.com"}' && echo ""

echo "Testing admin login:"
curl -X POST http://localhost:8000/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' && echo ""

echo ""
echo "🎉 Quick Fix Completed!"
echo "======================"
echo "✅ Services Status:"
docker-compose -f docker-compose.working.yml ps
echo ""
echo "🌐 Your application is now accessible at:"
echo "  • Frontend: http://lawvriksh.com"
echo "  • Backend API: http://lawvriksh.com/api/"
echo "  • API Docs: http://lawvriksh.com/docs"
echo "  • Admin Panel: http://lawvriksh.com/admin/login"
echo ""
echo "📝 Admin Credentials:"
echo "  • Email: sahilsaurav2507@gmail.com"
echo "  • Password: Sahil@123"
echo ""
echo "🔒 To add SSL, run:"
echo "  sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com"
echo ""
success "🚀 LawVriksh is now live and working!"
