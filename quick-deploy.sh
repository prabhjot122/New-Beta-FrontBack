#!/bin/bash

# =============================================================================
# LawVriksh Quick Deployment Script
# =============================================================================
# This script provides a simple interface for deployment
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                    LawVriksh Deployment                     ║
║              Production-Ready Deployment Tool               ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${GREEN}🚀 Welcome to LawVriksh Production Deployment!${NC}"
echo ""
echo "This script will deploy:"
echo "  ✅ Backend (FastAPI) → https://lawvriksh.com/api/"
echo "  ✅ Frontend (React) → https://lawvriksh.com"
echo "  ✅ MySQL Database → Port 3307"
echo "  ✅ Monitoring (Prometheus + Grafana)"
echo "  ✅ Automated Backups → sahilsaurav2507@gmail.com"
echo "  ✅ Security (Firewall + Fail2Ban)"
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo -e "${RED}⚠️  Warning: This script is optimized for Ubuntu 24.04${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if .env.production exists
if [[ ! -f ".env.production" ]]; then
    echo -e "${YELLOW}📝 Setting up environment configuration...${NC}"
    cp .env.example .env.production
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Please update .env.production with your credentials:${NC}"
    echo "  • JWT_SECRET_KEY (generate a secure random key)"
    echo "  • SMTP_PASSWORD (your Hostinger email password)"
    echo "  • Any other production-specific values"
    echo ""
    read -p "Press Enter after updating .env.production to continue..."
fi

echo -e "${GREEN}🔧 Starting deployment process...${NC}"
echo ""

# Run the main deployment script
if [[ -f "deploy-production.sh" ]]; then
    chmod +x deploy-production.sh
    ./deploy-production.sh
else
    echo -e "${RED}❌ deploy-production.sh not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Test your application at https://lawvriksh.com"
echo "  2. Check API at https://lawvriksh.com/api/docs"
echo "  3. Monitor at http://your-server-ip:3001 (Grafana)"
echo "  4. Review logs: docker-compose logs -f"
echo ""
echo -e "${BLUE}📖 For detailed information, see PRODUCTION_DEPLOYMENT_GUIDE.md${NC}"
