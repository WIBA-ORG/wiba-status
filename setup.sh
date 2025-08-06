#!/bin/bash

# WIBA Status Page Setup Script
# This script helps initialize the status page repository

set -e

echo "🔋 WIBA Status Page Setup"
echo "=============================="

# Check if we're in the right directory
if [ ! -f "index.html" ] || [ ! -d ".github" ]; then
    echo "❌ Error: Please run this script from the wiba-status repository root"
    exit 1
fi

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v git &> /dev/null; then
    echo "❌ Git is required but not installed"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "⚠️ GitHub CLI (gh) is recommended for easier setup"
    echo "Install from: https://cli.github.com/"
fi

echo "✅ Prerequisites check complete"

# Create necessary directories
echo "📁 Creating directory structure..."
mkdir -p data/incidents
mkdir -p logs

# Initialize status.json if it doesn't exist
if [ ! -f "data/status.json" ]; then
    echo "📝 Creating initial status.json..."
    cat > data/status.json << 'EOF'
{
  "last_updated": "2025-01-20T12:00:00Z",
  "overall_status": {
    "status": "operational",
    "message": "All systems operational"
  },
  "services": [],
  "metrics": {
    "total_uptime": "100%",
    "avg_response_time": "0ms", 
    "total_deployments": "0",
    "success_rate": "100%",
    "active_services": "0",
    "incidents_resolved": "0"
  },
  "recent_deployments": [],
  "incidents": [],
  "system_info": {
    "version": "1.0.0",
    "environment": "production",
    "region": "self-hosted",
    "monitoring_interval": "5m"
  }
}
EOF
else
    echo "✅ status.json already exists"
fi

# Git setup
echo "🔄 Setting up git..."
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git repository initialized"
else
    echo "✅ Git repository already exists"
fi

# Check for GitHub remote
if ! git remote get-url origin &> /dev/null; then
    echo "⚠️ No git remote 'origin' found"
    echo "Please add your GitHub repository as origin:"
    echo "  git remote add origin https://github.com/WIBA-ORG/wiba-status.git"
else
    ORIGIN_URL=$(git remote get-url origin)
    echo "✅ Git remote origin: $ORIGIN_URL"
fi

# GitHub Pages setup instructions
echo ""
echo "🌐 GitHub Pages Setup Instructions:"
echo "1. Go to your repository settings: https://github.com/WIBA-ORG/wiba-status/settings/pages"
echo "2. Under 'Source', select 'GitHub Actions'"
echo "3. Save the settings"
echo ""

# Repository secrets setup
echo "🔐 Required Repository Secrets:"
echo "The following secrets should be set in your GitHub repository:"
echo "  - GITHUB_TOKEN (usually automatic for GitHub Actions)"
echo ""
echo "To set secrets, go to:"
echo "https://github.com/WIBA-ORG/wiba-status/settings/secrets/actions"
echo ""

# Check if GitHub CLI is available for easier setup
if command -v gh &> /dev/null; then
    echo "🚀 GitHub CLI detected! You can use these commands:"
    echo ""
    echo "Enable GitHub Pages:"
    echo "  gh api repos/WIBA-ORG/wiba-status/pages -X POST -f source=gh-pages"
    echo ""
    echo "Check repository status:"
    echo "  gh repo view WIBA-ORG/wiba-status"
    echo ""
fi

# Final setup steps
echo "🏁 Final Setup Steps:"
echo "1. Commit and push this repository to GitHub"
echo "2. Enable GitHub Pages (see instructions above)"
echo "3. Wait for the first monitoring workflow to run (every 5 minutes)"
echo "4. Visit your status page at: https://wiba-org.github.io/wiba-status"
echo ""
echo "Integration with deployment workflows:"
echo "- Your existing workflows will automatically update the status page"
echo "- Each deployment will create a status update"
echo "- Health checks run every 5 minutes"
echo ""
echo "✅ Setup complete! Your status page is ready to go."
echo ""
echo "Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Initial status page setup'"
echo "3. git push origin main"
echo "4. Enable GitHub Pages in repository settings"

# Test status page locally (if requested)
read -p "Would you like to test the status page locally? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗺️ Testing status page locally..."
    if command -v python3 &> /dev/null; then
        echo "Starting local server at http://localhost:8000"
        echo "Press Ctrl+C to stop"
        python3 -m http.server 8000
    elif command -v python &> /dev/null; then
        echo "Starting local server at http://localhost:8000"
        echo "Press Ctrl+C to stop"
        python -m SimpleHTTPServer 8000
    else
        echo "Python not found. Please install Python to test locally."
        echo "Alternatively, open index.html directly in your browser."
    fi
fi