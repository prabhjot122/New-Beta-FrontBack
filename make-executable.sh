#!/bin/bash

# =============================================================================
# Make All Deployment Scripts Executable
# =============================================================================
# This script makes all deployment scripts executable
# Run this first: chmod +x make-executable.sh && ./make-executable.sh
# =============================================================================

echo "🔧 Making all deployment scripts executable..."

# List of scripts to make executable
scripts=(
    "deploy.sh"
    "setup-production.sh"
    "start-services.sh"
    "backup.sh"
    "health-check.sh"
    "make-executable.sh"
)

# Make scripts executable
for script in "${scripts[@]}"; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo "✅ Made $script executable"
    else
        echo "⚠️  $script not found"
    fi
done

echo ""
echo "🎉 All deployment scripts are now executable!"
echo ""
echo "📋 Next steps:"
echo "1. Run: ./deploy.sh"
echo "2. Run: ./setup-production.sh"
echo "3. Run: ./start-services.sh"
echo ""
echo "📚 For detailed instructions, see: DEPLOYMENT_GUIDE.md"
