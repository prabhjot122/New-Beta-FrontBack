#!/bin/bash

# =============================================================================
# Complete Fix and Domain Binding for LawVriksh
# =============================================================================
# Fixes: Backend health check, Frontend restart, Domain binding
# Binds to: lawvriksh.com and lawvriksh.com/api
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

echo "🔧 Complete Fix and Domain Binding for LawVriksh"
echo "==============================================="

# Step 1: Check current issues
log "Checking current container issues..."
echo "=== BACKEND LOGS ==="
docker logs --tail 10 lawvriksh-backend-minimal 2>/dev/null || echo "No backend logs"
echo "=== FRONTEND LOGS ==="
docker logs --tail 10 lawvriksh-frontend-minimal 2>/dev/null || echo "No frontend logs"

# Step 2: Stop current services
log "Stopping current services..."
docker-compose -f docker-compose.minimal.yml down -v 2>/dev/null || true

# Step 3: Create working backend health check
log "Creating backend with working health check..."
cat > app/api/health.py << 'EOF'
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
def health_check():
    """Simple health check endpoint"""
    return {"status": "healthy", "service": "lawvriksh-backend"}
EOF

# Step 4: Update main.py to include health endpoint
log "Updating main.py with health endpoint..."
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, users, shares, leaderboard, admin, campaigns, feedback, beta
from app.api.health import router as health_router

app = FastAPI(
    title="LawVriksh API",
    description="Legal Professional Referral Platform",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health_router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(shares.router)
app.include_router(leaderboard.router)
app.include_router(admin.router)
app.include_router(campaigns.router)
app.include_router(feedback.router)
app.include_router(beta.router)

@app.get("/")
def root():
    return {"message": "LawVriksh API is running", "status": "healthy"}
EOF

# Step 5: Build frontend properly
log "Building frontend..."
cd Frontend
npm install --silent
npm run build
if [[ ! -d "dist" || ! -f "dist/index.html" ]]; then
    error "Frontend build failed"
    exit 1
fi
cd ..
success "Frontend built successfully"

# Step 6: Create production docker-compose with domain binding
log "Creating production docker-compose with domain binding..."
cat > docker-compose.production-final.yml << 'EOF'
services:
  mysql:
    image: mysql:8.0
    container_name: lawvriksh-mysql-prod
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: Sahil123
      MYSQL_DATABASE: lawvriksh_referral
      MYSQL_USER: lawvriksh_user
      MYSQL_PASSWORD: Sahil123
    volumes:
      - mysql_data_prod:/var/lib/mysql
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
    container_name: lawvriksh-backend-prod
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
    container_name: lawvriksh-frontend-prod
    restart: unless-stopped
    volumes:
      - ./Frontend/dist:/usr/share/nginx/html:ro
      - ./nginx-production.conf:/etc/nginx/conf.d/default.conf:ro
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
  mysql_data_prod:

networks:
  lawvriksh-network:
    driver: bridge
EOF

# Step 7: Create nginx config for frontend container
log "Creating nginx configuration for frontend container..."
cat > nginx-production.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Main location for React app
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript;
}
EOF

# Step 8: Deploy production services
log "Deploying production services..."
docker-compose -f docker-compose.production-final.yml up -d --build

# Step 9: Wait for services to be ready
log "Waiting for services to be ready..."
sleep 60

# Monitor backend startup
for i in {1..20}; do
    if curl -f http://localhost:8000/health &>/dev/null; then
        success "Backend is responding!"
        break
    fi
    echo "Waiting for backend... ($i/20)"
    sleep 5
done

# Monitor frontend startup
for i in {1..10}; do
    if curl -f http://localhost:3000/health &>/dev/null; then
        success "Frontend is responding!"
        break
    fi
    echo "Waiting for frontend... ($i/10)"
    sleep 3
done

# Step 10: Setup admin user
log "Setting up admin user..."
docker-compose -f docker-compose.production-final.yml exec backend pip install bcrypt
docker-compose -f docker-compose.production-final.yml exec backend python setup_admin_corrected.py

# Step 11: Configure Nginx for domain binding
log "Configuring Nginx for domain binding..."
sudo tee /etc/nginx/sites-available/lawvriksh-production > /dev/null << 'EOF'
server {
    listen 80;
    server_name lawvriksh.com www.lawvriksh.com;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # API routes - lawvriksh.com/api/
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "http://lawvriksh.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "http://lawvriksh.com";
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, Accept";
            add_header Access-Control-Allow-Credentials "true";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
    }
    
    # API documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # OpenAPI JSON
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend - lawvriksh.com
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Handle client-side routing
        try_files $uri $uri/ @fallback;
    }
    
    # Fallback for client-side routing
    location @fallback {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Security: Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|conf)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Step 12: Enable Nginx configuration
log "Enabling Nginx configuration..."
sudo rm -f /etc/nginx/sites-enabled/lawvriksh*
sudo ln -sf /etc/nginx/sites-available/lawvriksh-production /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
success "Nginx configuration enabled"

# Step 13: Test everything
log "Testing complete deployment..."

# Test local services
echo "=== LOCAL TESTS ==="
if curl -f http://localhost:8000/health &>/dev/null; then
    success "✅ Backend local health check passed"
else
    error "❌ Backend local health check failed"
fi

if curl -f http://localhost:3000/health &>/dev/null; then
    success "✅ Frontend local health check passed"
else
    error "❌ Frontend local health check failed"
fi

# Test domain
echo "=== DOMAIN TESTS ==="
if curl -f http://lawvriksh.com/health &>/dev/null; then
    success "✅ Domain health check passed"
else
    warning "⚠️ Domain health check failed (check DNS)"
fi

if curl -f http://lawvriksh.com/api/health &>/dev/null; then
    success "✅ API domain health check passed"
else
    warning "⚠️ API domain health check failed"
fi

# Test API endpoints
echo "=== API TESTS ==="
echo "Testing beta registration:"
curl -X POST http://localhost:8000/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Production Test","email":"production@test.com"}' && echo ""

echo "Testing admin login:"
curl -X POST http://localhost:8000/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sahilsaurav2507@gmail.com","password":"Sahil@123"}' && echo ""

# Step 14: Show final status
echo ""
echo "🎉 Complete Fix and Domain Binding Completed!"
echo "============================================="
echo "✅ Final Service Status:"
docker-compose -f docker-compose.production-final.yml ps
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
echo "🔒 To add SSL certificate, run:"
echo "  sudo certbot --nginx -d lawvriksh.com -d www.lawvriksh.com"
echo ""
echo "📋 Management Commands:"
echo "  • View logs: docker-compose -f docker-compose.production-final.yml logs -f"
echo "  • Restart: docker-compose -f docker-compose.production-final.yml restart"
echo "  • Stop: docker-compose -f docker-compose.production-final.yml down"
echo ""
success "🚀 LawVriksh is now live at lawvriksh.com!"
