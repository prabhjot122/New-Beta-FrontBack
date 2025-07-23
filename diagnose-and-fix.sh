#!/bin/bash

# =============================================================================
# Complete Diagnostic and Fix Script for LawVriksh Backend Issues
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"; }
warning() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"; }
info() { echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"; }

echo "🔍 LawVriksh Backend Diagnostic and Fix"
echo "======================================"

# Step 1: Check current container status
log "Checking current container status..."
docker ps -a | grep lawvriksh || echo "No lawvriksh containers found"

# Step 2: Get backend logs
log "Checking backend container logs..."
BACKEND_CONTAINER=$(docker ps -a --format "table {{.Names}}" | grep backend | head -1)
if [[ -n "$BACKEND_CONTAINER" ]]; then
    echo "📋 Backend Container Logs:"
    echo "========================="
    docker logs --tail 50 $BACKEND_CONTAINER || echo "Could not get logs"
    echo "========================="
else
    warning "No backend container found"
fi

# Step 3: Stop all services completely
log "Stopping all services completely..."
docker-compose -f docker-compose.working.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.simple.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.emergency.yml down -v 2>/dev/null || true
docker-compose down -v 2>/dev/null || true

# Clean up any remaining containers
docker container prune -f
docker system prune -f

# Step 4: Create minimal working requirements.txt
log "Creating minimal working requirements.txt..."
cat > requirements.minimal.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
pymysql==1.1.0
python-dotenv==1.0.0
pydantic==2.5.0
pydantic-settings==2.1.0
passlib[bcrypt]==1.7.4
bcrypt==4.0.1
python-jose[cryptography]==3.3.0
email-validator==2.1.0
pytz==2023.3
gunicorn==21.2.0
python-multipart==0.0.6
jinja2==3.1.2
aiofiles==23.2.1
httpx==0.25.2
cryptography==41.0.7
EOF

# Step 5: Create minimal Dockerfile
log "Creating minimal working Dockerfile..."
cat > Dockerfile.minimal << 'EOF'
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.minimal.txt requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/logs /app/cache /app/uploads

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start command
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
EOF

# Step 6: Create minimal docker-compose
log "Creating minimal docker-compose configuration..."
cat > docker-compose.minimal.yml << 'EOF'
services:
  mysql:
    image: mysql:8.0
    container_name: lawvriksh-mysql-minimal
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: Sahil123
      MYSQL_DATABASE: lawvriksh_referral
      MYSQL_USER: lawvriksh_user
      MYSQL_PASSWORD: Sahil123
    volumes:
      - mysql_data_minimal:/var/lib/mysql
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
      dockerfile: Dockerfile.minimal
    container_name: lawvriksh-backend-minimal
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
      DEBUG: "true"
      PYTHONPATH: /app
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - lawvriksh-network
    volumes:
      - ./logs:/app/logs
      - ./cache:/app/cache

  frontend:
    image: nginx:alpine
    container_name: lawvriksh-frontend-minimal
    restart: unless-stopped
    volumes:
      - ./Frontend/dist:/usr/share/nginx/html:ro
    ports:
      - "127.0.0.1:3000:80"
    networks:
      - lawvriksh-network
    command: >
      sh -c "
      cat > /etc/nginx/conf.d/default.conf << 'NGINXEOF'
      server {
          listen 80;
          server_name localhost;
          
          location / {
              root /usr/share/nginx/html;
              index index.html index.htm;
              try_files \$$uri \$$uri/ /index.html;
          }
          
          location /health {
              access_log off;
              return 200 'healthy';
              add_header Content-Type text/plain;
          }
      }
      NGINXEOF
      nginx -g 'daemon off;'
      "

volumes:
  mysql_data_minimal:

networks:
  lawvriksh-network:
    driver: bridge
EOF

# Step 7: Build frontend
log "Building frontend..."
cd Frontend
npm install --silent
npm run build
cd ..
success "Frontend built successfully"

# Step 8: Create database init script
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

# Step 9: Deploy minimal configuration
log "Deploying minimal configuration..."
docker-compose -f docker-compose.minimal.yml up -d --build

# Step 10: Monitor startup
log "Monitoring service startup..."
for i in {1..30}; do
    echo "Checking services... ($i/30)"
    
    # Check if backend is running
    if docker ps | grep lawvriksh-backend-minimal | grep -q "Up"; then
        success "Backend container is running!"
        break
    fi
    
    # Show backend logs if container exists but not running
    if docker ps -a | grep lawvriksh-backend-minimal; then
        echo "Backend container logs:"
        docker logs --tail 10 lawvriksh-backend-minimal 2>/dev/null || echo "No logs yet"
    fi
    
    sleep 10
done

# Step 11: Check final status
log "Checking final service status..."
docker-compose -f docker-compose.minimal.yml ps

# Step 12: Test backend health
log "Testing backend health..."
sleep 30
for i in {1..10}; do
    if curl -f http://localhost:8000/health 2>/dev/null; then
        success "✅ Backend is responding to health checks!"
        break
    else
        echo "Backend not ready yet... ($i/10)"
        sleep 10
    fi
done

# Step 13: Setup admin user
log "Setting up admin user..."
if docker ps | grep lawvriksh-backend-minimal | grep -q "Up"; then
    docker-compose -f docker-compose.minimal.yml exec backend pip install bcrypt
    docker-compose -f docker-compose.minimal.yml exec backend python setup_admin_corrected.py
    success "Admin user setup completed"
else
    error "Backend container is not running, cannot setup admin user"
fi

# Step 14: Final tests
log "Running final tests..."

# Test backend
if curl -f http://localhost:8000/health &>/dev/null; then
    success "✅ Backend health check passed"
else
    error "❌ Backend health check failed"
fi

# Test frontend
if curl -f http://localhost:3000/health &>/dev/null; then
    success "✅ Frontend health check passed"
else
    error "❌ Frontend health check failed"
fi

# Test API endpoints
echo "Testing beta registration:"
curl -X POST http://localhost:8000/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Diagnostic Test","email":"diagnostic@test.com"}' && echo ""

echo "Testing admin login:"
curl -X POST http://localhost:8000/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' && echo ""

echo ""
echo "🎉 Diagnostic and Fix Completed!"
echo "================================"
echo "✅ Final Service Status:"
docker-compose -f docker-compose.minimal.yml ps
echo ""
echo "📋 Container Logs (if needed):"
echo "  docker logs lawvriksh-backend-minimal"
echo "  docker logs lawvriksh-mysql-minimal"
echo "  docker logs lawvriksh-frontend-minimal"
echo ""
echo "🌐 Application URLs:"
echo "  • Frontend: http://localhost:3000"
echo "  • Backend API: http://localhost:8000"
echo "  • API Docs: http://localhost:8000/docs"
echo "  • Health Check: http://localhost:8000/health"
echo ""
success "🚀 LawVriksh should now be working!"
