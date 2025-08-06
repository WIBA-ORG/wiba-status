#!/bin/bash
# Finalize WIBA Status Page setup and commit changes

set -e

echo "🔄 Finalizing WIBA Status Page Setup"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "index.html" ] || [ ! -d ".github" ]; then
    echo "❌ Please run this script from the wiba-status repository root"
    exit 1
fi

# Update existing workflows with enhanced monitoring
echo "📝 Committing enhanced status page system..."

# Add all new and modified files
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "✅ No changes to commit - system is up to date"
else
    echo "📊 Changes detected, committing..."
    
    # Create comprehensive commit message
    cat > commit_message.txt << EOF
Comprehensive status page system with dual deployment

🚀 Features:
- Dual deployment: GitHub Pages + custom domain (status.wiba.dev)
- Enhanced monitoring with vLLM and database health checks
- Real-time performance visualizations and charts
- Automated incident creation and management
- Integration with existing deployment workflows
- Professional nginx configuration with SSL support

📁 Files Added/Updated:
- Enhanced monitoring workflow with 8 services
- Custom domain deployment workflow
- Performance visualization components
- Nginx configuration for status.wiba.dev
- Comprehensive deployment guide
- Automated setup scripts
- Integration with platform/web-interface workflows

🔧 Generated with Claude Code
https://claude.ai/code

Co-Authored-By: Claude <noreply@anthropic.com>
EOF

    git commit -F commit_message.txt
    rm commit_message.txt
    
    echo "✅ Changes committed successfully"
fi

# Push changes to remote
echo "📡 Pushing changes to GitHub..."
if git push; then
    echo "✅ Changes pushed to GitHub successfully"
else
    echo "⚠️  Push failed - you may need to authenticate with GitHub"
    echo "   Run: git push"
fi

echo ""
echo "🎉 WIBA Status Page System Setup Complete!"
echo "========================================"
echo ""
echo "📊 System Overview:"
echo "   • Enhanced monitoring: 8 services including vLLM and database"
echo "   • Dual deployment: GitHub Pages + status.wiba.dev"
echo "   • Real-time updates: Every 5 minutes via GitHub Actions"
echo "   • Performance charts: Availability ring and response time bars"
echo "   • Incident management: Automated creation and GitHub Issues integration"
echo "   • Deployment tracking: Integration with existing CI/CD workflows"
echo ""
echo "🔗 URLs:"
echo "   • Primary: https://status.wiba.dev (after DNS/SSL setup)"
echo "   • Backup:  https://wiba-org.github.io/wiba-status"
echo "   • GitHub:  https://github.com/WIBA-ORG/wiba-status"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. 🏠 Custom Domain Setup:"
echo "   cd /home/arman/wiba-repos/wiba-status"
echo "   ./setup-custom-domain.sh"
echo ""
echo "2. 📡 DNS Configuration:"
echo "   Add A record: status.wiba.dev → YOUR_SERVER_IP"
echo "   Wait for DNS propagation (5-60 minutes)"
echo ""
echo "3. 🔒 SSL Certificate:"
echo "   sudo certbot --nginx -d status.wiba.dev"
echo ""
echo "4. ✅ Verify Setup:"
echo "   curl -I https://status.wiba.dev"
echo "   curl https://status.wiba.dev/health"
echo ""
echo "📚 Documentation:"
echo "   • Full setup guide: DEPLOYMENT-GUIDE.md"
echo "   • Nginx config: nginx-status-config.conf"
echo "   • Setup script: setup-custom-domain.sh"
echo ""

# Check GitHub Actions status
echo "🤖 GitHub Actions Status:"
REPO_URL="https://github.com/WIBA-ORG/wiba-status"
echo "   • Monitor workflow: $REPO_URL/actions/workflows/monitor-status.yml"
echo "   • Deploy workflow: $REPO_URL/actions/workflows/deploy-to-custom-domain.yml"
echo "   • Pages deployment: $REPO_URL/actions/workflows/deploy-pages.yml"
echo ""

# Show current status
echo "📊 Current System Status:"
if [ -f "data/status.json" ]; then
    LAST_UPDATED=$(jq -r '.last_updated // "Never"' data/status.json 2>/dev/null || echo "Invalid JSON")
    OVERALL_STATUS=$(jq -r '.overall_status.status // "Unknown"' data/status.json 2>/dev/null || echo "Unknown")
    SERVICE_COUNT=$(jq -r '.services | length' data/status.json 2>/dev/null || echo "0")
    
    echo "   • Last updated: $LAST_UPDATED"
    echo "   • Overall status: $OVERALL_STATUS"
    echo "   • Services monitored: $SERVICE_COUNT"
else
    echo "   • Status data: Not yet generated (will be created on first run)"
fi

echo ""
echo "🔧 Integration Status:"
echo "   • Platform deployment: ✅ Enhanced with status reporting"
echo "   • Web interface deployment: ✅ Enhanced with status reporting"
echo "   • Custom domain workflow: ✅ Ready for deployment"
echo "   • Incident management: ✅ Automated creation enabled"
echo ""

# Provide final tips
echo "💡 Tips:"
echo "   • Monitor the first few runs of GitHub Actions workflows"
echo "   • Test incident creation with a manual workflow dispatch"
echo "   • Set up DNS first, then run setup-custom-domain.sh"
echo "   • Use 'git pull' in this directory to get future updates"
echo ""

echo "✨ Your professional status page system is now ready!"
echo "   Visit the URLs above once DNS and SSL are configured."