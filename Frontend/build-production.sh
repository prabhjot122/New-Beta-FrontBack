#!/bin/bash

# =============================================================================
# Frontend Production Build Script
# =============================================================================
# This script builds the frontend for production deployment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if we're in the Frontend directory
if [[ ! -f "package.json" ]]; then
    error "This script must be run from the Frontend directory"
fi

log "Starting Frontend Production Build"
log "=================================="

# Clean previous builds
if [[ -d "dist" ]]; then
    log "Cleaning previous build..."
    rm -rf dist
fi

# Install dependencies
log "Installing dependencies..."
npm ci --only=production

# Run build
log "Building for production..."
npm run build

# Verify build
if [[ ! -d "dist" ]]; then
    error "Build failed - dist directory not created"
fi

# Check if build contains required files
if [[ ! -f "dist/index.html" ]]; then
    error "Build failed - index.html not found in dist"
fi

log "Build completed successfully!"
log "Build output is in the 'dist' directory"

# Show build size
if command -v du &> /dev/null; then
    BUILD_SIZE=$(du -sh dist | cut -f1)
    info "Build size: $BUILD_SIZE"
fi

# Show files in build
info "Build contents:"
ls -la dist/

log "=================================="
log "Frontend build ready for deployment!"
log "Deploy the 'dist' directory to your web server"
