#!/bin/bash

# =============================================================================
# LawVriksh Final Deployment Script
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

echo "🚀 LawVriksh Final Deployment"
echo "============================"

# Step 1: Clean up existing containers
log "Cleaning up existing containers..."
docker stop $(docker ps -q --filter "name=lawvriksh") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=lawvriksh") 2>/dev/null || true

# Step 2: Deploy services with new configuration
log "Deploying services..."
docker-compose -f docker-compose.final.yml up -d --build

# Step 3: Wait for services to start
log "Waiting for services to start..."
sleep 90

# Step 4: Check service status
log "Checking service status..."
docker-compose -f docker-compose.final.yml ps

# Step 5: Test backend
log "Testing backend..."
for i in {1..10}; do
    if curl -f http://localhost:8000/health 2>/dev/null; then
        success "Backend is healthy!"
        break
    else
        echo "Waiting for backend... ($i/10)"
        sleep 10
    fi
done

# Step 6: Test frontend
log "Testing frontend..."
for i in {1..10}; do
    if curl -f http://localhost:3001/ 2>/dev/null; then
        success "Frontend is healthy!"
        break
    else
        echo "Waiting for frontend... ($i/10)"
        sleep 10
    fi
done

# Step 7: Update nginx configuration
log "Updating nginx configuration..."
sudo cp nginx-lawvriksh-final.conf /etc/nginx/sites-available/lawvriksh-final
sudo rm -f /etc/nginx/sites-enabled/lawvriksh*
sudo ln -sf /etc/nginx/sites-available/lawvriksh-final /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Step 8: Setup admin user
log "Setting up admin user..."
docker-compose -f docker-compose.final.yml exec backend python setup_admin_corrected.py

# Step 9: Test complete application
log "Testing complete application..."

echo "=== BACKEND TESTS ==="
curl -s http://localhost:8000/health && echo ""
curl -s http://lawvriksh.com/api/health && echo ""

echo "=== FRONTEND TESTS ==="
curl -I http://localhost:3001/ 2>/dev/null | head -1
curl -I http://lawvriksh.com/ 2>/dev/null | head -1

echo "=== BETA REGISTRATION TEST ==="
curl -X POST http://lawvriksh.com/api/beta/signup \
  -H "Content-Type: application/json" \
  -d '{"name":"Final Deploy Test","email":"deploy@lawvriksh.com"}' \
  -s | head -1

echo ""
success "🎉 LawVriksh deployment completed!"
echo ""
echo "✅ Your application is now live at:"
echo "   🌐 Frontend: http://lawvriksh.com"
echo "   🔗 Backend API: http://lawvriksh.com/api/"
echo "   📚 API Docs: http://lawvriksh.com/docs"
echo "   👑 Admin: sahilsaurav2507@gmail.com / Sahil@123"
echo ""
echo "🔧 Services running on:"
echo "   Backend: localhost:8000"
echo "   Frontend: localhost:3001"
echo "   MySQL: localhost:3307"
echo ""
echo "📋 To monitor:"
echo "   docker-compose -f docker-compose.final.yml logs -f"
echo "   docker-compose -f docker-compose.final.yml ps"
