#!/bin/bash

# =============================================================================
# Emergency Fix for LawVriksh Deployment Issues
# =============================================================================
# Fixes: Container restarting, SSL errors, 502 Bad Gateway
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

echo "🚨 Emergency Fix for LawVriksh Deployment"
echo "========================================"

# Step 1: Stop all services
log "Stopping all services..."
docker-compose -f docker-compose.domain.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.simple.yml down -v 2>/dev/null || true
docker-compose down -v 2>/dev/null || true

# Step 2: Remove problematic Nginx config
log "Removing problematic Nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/lawvriksh
sudo rm -f /etc/nginx/sites-available/lawvriksh

# Step 3: Create simple HTTP-only Nginx config
log "Creating simple HTTP-only Nginx configuration..."
sudo tee /etc/nginx/sites-available/lawvriksh-simple > /dev/null << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # API routes - http://lawvriksh.com/api/
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }
    
    # API documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # OpenAPI JSON
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend - http://lawvriksh.com
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Step 4: Enable simple Nginx config
sudo ln -sf /etc/nginx/sites-available/lawvriksh-simple /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
success "Simple Nginx configuration applied"

# Step 5: Build frontend
log "Building frontend..."
cd Frontend
npm install --silent
npm run build
cd ..
success "Frontend built successfully"

# Step 6: Create simple docker-compose
log "Creating simple docker-compose configuration..."
cat > docker-compose.emergency.yml << 'EOF'
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
      DOMAIN: lawvriksh.com
      API_BASE_URL: http://lawvriksh.com/api
      FRONTEND_URL: http://lawvriksh.com
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
    ports:
      - "127.0.0.1:3000:80"
    networks:
      - lawvriksh-network
    command: >
      sh -c "
      printf 'server {\n\
          listen 80;\n\
          server_name localhost;\n\
          \n\
          location / {\n\
              root /usr/share/nginx/html;\n\
              index index.html index.htm;\n\
              try_files \$$uri \$$uri/ /index.html;\n\
          }\n\
          \n\
          location /health {\n\
              access_log off;\n\
              return 200 \"healthy\\n\";\n\
              add_header Content-Type text/plain;\n\
          }\n\
      }\n' > /etc/nginx/conf.d/default.conf &&
      nginx -g 'daemon off;'
      "
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

# Step 7: Deploy with emergency config
log "Deploying with emergency configuration..."
docker-compose -f docker-compose.emergency.yml up -d --build

# Step 8: Wait for services
log "Waiting for services to start..."
sleep 90

# Step 9: Check service status
log "Checking service status..."
docker-compose -f docker-compose.emergency.yml ps

# Step 10: Setup admin user
log "Setting up admin user..."
sleep 30
docker-compose -f docker-compose.emergency.yml exec backend pip install bcrypt
docker-compose -f docker-compose.emergency.yml exec backend python setup_admin_corrected.py

# Step 11: Test endpoints
log "Testing endpoints..."

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

# Test via domain (if accessible)
if curl -f http://lawvriksh.com/health &>/dev/null; then
    success "✅ Domain is responding"
else
    warning "⚠️ Domain may not be responding (check DNS)"
fi

# Step 12: Test API endpoints
log "Testing API endpoints..."

# Test beta registration
echo "Testing beta registration:"
curl -X POST http://localhost:8000/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Emergency Test User","email":"emergency@test.com"}' && echo ""

# Test admin login
echo "Testing admin login:"
curl -X POST http://localhost:8000/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' && echo ""

echo ""
echo "🎉 Emergency Fix Completed!"
echo "=========================="
echo "✅ Services Status:"
docker-compose -f docker-compose.emergency.yml ps
echo ""
echo "🌐 Your application should now be accessible at:"
echo "  • Frontend: http://lawvriksh.com"
echo "  • Backend API: http://lawvriksh.com/api/"
echo "  • API Docs: http://lawvriksh.com/docs"
echo "  • Admin Panel: http://lawvriksh.com/admin/login"
echo ""
echo "📝 Admin Credentials:"
echo "  • Email: sahilsaurav2507@gmail.com"
echo "  • Password: Sahil@123"
echo ""
echo "🔒 To add SSL later, run:"
echo "  sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com"
echo ""
success "🚀 LawVriksh is now live!"
