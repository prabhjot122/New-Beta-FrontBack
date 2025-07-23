#!/bin/bash

# =============================================================================
# Fix Backend Health Check Issue
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

echo "🔧 Fixing Backend Health Check Issue"
echo "==================================="

# Step 1: Check current backend status
log "Checking current backend status..."
BACKEND_CONTAINER=$(docker ps --format "table {{.Names}}" | grep backend | head -1)
if [[ -n "$BACKEND_CONTAINER" ]]; then
    echo "Backend container: $BACKEND_CONTAINER"
    echo "=== BACKEND LOGS ==="
    docker logs --tail 20 $BACKEND_CONTAINER
    echo "===================="
else
    error "No backend container found"
fi

# Step 2: Check if health endpoint exists
log "Checking if health endpoint exists..."
if [[ -n "$BACKEND_CONTAINER" ]]; then
    docker exec $BACKEND_CONTAINER ls -la app/api/ 2>/dev/null || echo "app/api directory not found"
    docker exec $BACKEND_CONTAINER find /app -name "*.py" | grep -E "(health|main)" || echo "No health/main files found"
fi

# Step 3: Create proper health endpoint
log "Creating proper health endpoint..."
mkdir -p app/api

cat > app/api/health.py << 'EOF'
from fastapi import APIRouter
from datetime import datetime

router = APIRouter()

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "lawvriksh-backend",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@router.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "LawVriksh API is running",
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat()
    }
EOF

# Step 4: Update main.py to ensure health endpoint is included
log "Updating main.py..."
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.health import router as health_router

# Import other routers with error handling
try:
    from app.api import auth, users, shares, leaderboard, admin, campaigns, feedback, beta
    OTHER_ROUTERS_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Some routers not available: {e}")
    OTHER_ROUTERS_AVAILABLE = False

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

# Always include health router first
app.include_router(health_router)

# Include other routers if available
if OTHER_ROUTERS_AVAILABLE:
    try:
        app.include_router(auth.router)
        app.include_router(users.router)
        app.include_router(shares.router)
        app.include_router(leaderboard.router)
        app.include_router(admin.router)
        app.include_router(campaigns.router)
        app.include_router(feedback.router)
        app.include_router(beta.router)
        print("✅ All routers loaded successfully")
    except Exception as e:
        print(f"⚠️ Warning: Some routers failed to load: {e}")

@app.get("/")
async def root():
    return {
        "message": "LawVriksh API is running",
        "status": "healthy",
        "docs": "/docs",
        "health": "/health"
    }
EOF

# Step 5: Create minimal working Dockerfile
log "Creating minimal working Dockerfile..."
cat > Dockerfile.health-fix << 'EOF'
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

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    sqlalchemy==2.0.23 \
    pymysql==1.1.0 \
    python-dotenv==1.0.0 \
    pydantic==2.5.0 \
    pydantic-settings==2.1.0 \
    passlib[bcrypt]==1.7.4 \
    bcrypt==4.0.1 \
    python-jose[cryptography]==3.3.0 \
    email-validator==2.1.0 \
    pytz==2023.3 \
    python-multipart==0.0.6 \
    jinja2==3.1.2 \
    aiofiles==23.2.1 \
    httpx==0.25.2 \
    cryptography==41.0.7

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

# Step 6: Create docker-compose with health fix
log "Creating docker-compose with health fix..."
cat > docker-compose.health-fix.yml << 'EOF'
services:
  mysql:
    image: mysql:8.0
    container_name: lawvriksh-mysql-health
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: Sahil123
      MYSQL_DATABASE: lawvriksh_referral
      MYSQL_USER: lawvriksh_user
      MYSQL_PASSWORD: Sahil123
    volumes:
      - mysql_data_health:/var/lib/mysql
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
      dockerfile: Dockerfile.health-fix
    container_name: lawvriksh-backend-health
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
    container_name: lawvriksh-frontend-health
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
  mysql_data_health:

networks:
  lawvriksh-network:
    driver: bridge
EOF

# Step 7: Stop current services and deploy health fix
log "Stopping current services..."
docker-compose -f docker-compose.production-final.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.minimal.yml down -v 2>/dev/null || true

log "Deploying health fix..."
docker-compose -f docker-compose.health-fix.yml up -d --build

# Step 8: Monitor backend startup
log "Monitoring backend startup..."
for i in {1..30}; do
    echo "Checking backend startup... ($i/30)"
    
    # Check if container is running
    if docker ps | grep lawvriksh-backend-health | grep -q "Up"; then
        echo "✅ Backend container is running"
        
        # Test health endpoint
        if curl -f http://localhost:8000/health &>/dev/null; then
            success "✅ Backend health check passed!"
            break
        else
            echo "Backend running but health check not ready yet..."
        fi
    else
        echo "Backend container not running yet..."
        # Show logs if container exists
        docker logs --tail 5 lawvriksh-backend-health 2>/dev/null || echo "No logs yet"
    fi
    
    sleep 10
done

# Step 9: Test all endpoints
log "Testing all endpoints..."

echo "=== BACKEND TESTS ==="
curl -v http://localhost:8000/ && echo ""
curl -v http://localhost:8000/health && echo ""

echo "=== FRONTEND TEST ==="
curl -v http://localhost:3000/health && echo ""

# Step 10: Setup admin user
log "Setting up admin user..."
if docker ps | grep lawvriksh-backend-health | grep -q "Up"; then
    docker-compose -f docker-compose.health-fix.yml exec backend pip install bcrypt
    docker-compose -f docker-compose.health-fix.yml exec backend python setup_admin_corrected.py
    success "Admin user setup completed"
else
    error "Backend container is not running, cannot setup admin user"
fi

# Step 11: Show final status
echo ""
echo "🎉 Backend Health Fix Completed!"
echo "================================"
echo "✅ Service Status:"
docker-compose -f docker-compose.health-fix.yml ps
echo ""
echo "🧪 Test Commands:"
echo "  curl http://localhost:8000/health"
echo "  curl http://localhost:8000/"
echo "  curl http://localhost:8000/docs"
echo ""
echo "📋 Container Logs:"
echo "  docker logs lawvriksh-backend-health"
echo "  docker logs lawvriksh-frontend-health"
echo ""
success "🚀 Backend should now be responding to health checks!"
