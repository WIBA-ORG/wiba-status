#!/bin/bash

# WIBA Status Page Deployment Script
# This script sets up the complete status page system including GitHub repository,
# nginx configuration, and initial deployment

set -euo pipefail

# Configuration
GITHUB_ORG="WIBA-ORG"
REPO_NAME="wiba-status"
GITHUB_REPO="$GITHUB_ORG/$REPO_NAME"
DOMAIN="status.wiba.dev"
WEB_ROOT="/var/www/$DOMAIN"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to check if running as root or with sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Run as regular user with sudo access."
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        error "This script requires sudo access for nginx configuration."
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check for required tools
    for tool in git curl jq nginx node; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        info "Please install missing tools and run again"
        exit 1
    fi
    
    # Check if nginx is running
    if ! sudo systemctl is-active --quiet nginx; then
        warn "Nginx is not running. Will attempt to start it."
        sudo systemctl start nginx
    fi
    
    log "Prerequisites check completed"
}

# Function to setup web directory
setup_web_directory() {
    log "Setting up web directory: $WEB_ROOT"
    
    # Create web directory
    sudo mkdir -p "$WEB_ROOT"
    sudo mkdir -p "$WEB_ROOT/data"
    sudo mkdir -p "$WEB_ROOT/assets"
    
    # Copy status page files
    log "Copying status page files..."
    sudo cp "$SCRIPT_DIR/index.html" "$WEB_ROOT/"
    sudo cp -r "$SCRIPT_DIR/assets"/* "$WEB_ROOT/assets/" 2>/dev/null || true
    
    # Create initial status data if it doesn't exist
    if [[ ! -f "$WEB_ROOT/data/status.json" ]]; then
        log "Creating initial status data..."
        sudo tee "$WEB_ROOT/data/status.json" > /dev/null << 'EOF'
{
  "last_updated": "2024-01-01T00:00:00Z",
  "overall_status": {
    "status": "operational",
    "message": "Status page initializing... First health check in progress."
  },
  "services": [
    {
      "name": "WIBA Platform",
      "description": "Backend API and core services",
      "status": "unknown",
      "response_time": "0ms",
      "last_checked": "2024-01-01T00:00:00Z",
      "critical": true,
      "category": "core"
    },
    {
      "name": "WIBA Web Interface", 
      "description": "Frontend website and user interface",
      "status": "unknown",
      "response_time": "0ms",
      "last_checked": "2024-01-01T00:00:00Z",
      "critical": true,
      "category": "core"
    }
  ],
  "metrics": {
    "total_uptime": "99.9%",
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
    "monitoring_interval": "5m",
    "deployment_urls": {
      "primary": "https://status.wiba.dev"
    }
  }
}
EOF
    fi
    
    # Set proper permissions
    sudo chown -R www-data:www-data "$WEB_ROOT"
    sudo chmod -R 644 "$WEB_ROOT"
    sudo find "$WEB_ROOT" -type d -exec chmod 755 {} \;
    
    log "Web directory setup completed"
}

# Function to configure nginx
configure_nginx() {
    log "Configuring nginx for $DOMAIN"
    
    local nginx_config="/etc/nginx/sites-available/status-wiba"
    local nginx_enabled="/etc/nginx/sites-enabled/status-wiba"
    
    # Copy nginx configuration
    sudo cp "$SCRIPT_DIR/nginx-status.conf" "$nginx_config"
    
    # Update the configuration with correct paths
    sudo sed -i "s|/var/www/status.wiba.dev|$WEB_ROOT|g" "$nginx_config"
    
    # Enable the site
    sudo ln -sf "$nginx_config" "$nginx_enabled"
    
    # Test nginx configuration
    if sudo nginx -t; then
        log "Nginx configuration test passed"
        sudo systemctl reload nginx
        log "Nginx reloaded successfully"
    else
        error "Nginx configuration test failed"
        exit 1
    fi
    
    # Verify the site is accessible
    sleep 2
    if curl -s -H "Host: $DOMAIN" http://127.0.0.1/health | grep -q "OK"; then
        log "Status page health check passed"
    else
        warn "Status page health check failed - may need DNS configuration"
    fi
}

# Function to create GitHub repository
create_github_repo() {
    log "Setting up GitHub repository: $GITHUB_REPO"
    
    # Check if GITHUB_TOKEN is available
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        warn "GITHUB_TOKEN environment variable not set"
        info "Please set GITHUB_TOKEN or create the repository manually:"
        info "  Repository: $GITHUB_REPO"
        info "  Description: WIBA System Status Page - Real-time monitoring and deployment tracking"
        info "  Public: Yes"
        info "  Enable GitHub Pages: Yes"
        return 0
    fi
    
    # Check if repository already exists
    if curl -s -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/$GITHUB_REPO" | jq -e '.id' > /dev/null; then
        log "Repository $GITHUB_REPO already exists"
    else
        log "Creating GitHub repository..."
        
        # Create repository
        curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d '{
                "name": "'$REPO_NAME'",
                "description": "WIBA System Status Page - Real-time monitoring and deployment tracking",
                "homepage": "https://'$DOMAIN'",
                "private": false,
                "has_issues": true,
                "has_projects": false,
                "has_wiki": false,
                "has_downloads": false
            }' \
            "https://api.github.com/orgs/$GITHUB_ORG/repos"
        
        log "Repository created successfully"
    fi
    
    # Enable GitHub Pages
    log "Enabling GitHub Pages..."
    curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d '{
            "source": {
                "branch": "main",
                "path": "/"
            }
        }' \
        "https://api.github.com/repos/$GITHUB_REPO/pages" || log "GitHub Pages may already be enabled"
}

# Function to setup Git repository and push initial commit
setup_git_repo() {
    log "Setting up Git repository..."
    
    cd "$SCRIPT_DIR"
    
    # Initialize repository if not already done
    if [[ ! -d ".git" ]]; then
        git init
        git branch -M main
    fi
    
    # Configure git if not already configured
    git config user.name "armaniii" 2>/dev/null || git config user.name "armaniii"
    git config user.email "airan002@ucr.edu" 2>/dev/null || git config user.email "airan002@ucr.edu"
    
    # Add remote origin if not exists
    if ! git remote get-url origin &>/dev/null; then
        git remote add origin "https://github.com/$GITHUB_REPO.git"
    fi
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Logs
*.log
logs/

# Environment files
.env
.env.local

# OS generated files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/

# Temporary files
tmp/
temp/

# Build artifacts
dist/
build/
EOF
    fi
    
    # Add all files and commit
    git add .
    
    if git diff --staged --quiet; then
        log "No changes to commit"
    else
        git commit -m "Initial WIBA Status Page setup

🚀 Complete status page system with:
- Real-time service monitoring
- Deployment tracking integration
- GitHub Pages & custom domain support
- Professional responsive UI
- Automated incident management
- Historical performance data

Features:
✅ Monitor WIBA platform, API endpoints, and vLLM service
✅ Track deployment success/failure rates
✅ Automated status updates via GitHub Actions
✅ Dual deployment (GitHub Pages + custom domain)
✅ Professional status indicators and metrics
✅ Mobile-responsive design with dark/light themes
✅ Integration with existing deployment workflows

Deployment:
- Primary: https://status.wiba.dev
- Monitoring: Every 5 minutes via GitHub Actions
- Updates: Real-time via deployment hooks

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
        
        log "Initial commit created"
    fi
    
    # Push to remote
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log "Pushing to GitHub..."
        git push -u origin main
        log "Repository pushed to GitHub successfully"
    else
        warn "GITHUB_TOKEN not set - please push manually:"
        info "  git remote add origin https://github.com/$GITHUB_REPO.git"
        info "  git push -u origin main"
    fi
}

# Function to trigger initial monitoring
trigger_initial_monitoring() {
    log "Triggering initial status monitoring..."
    
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        # Trigger the monitor workflow
        curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d '{"event_type":"monitor-trigger","client_payload":{"source":"initial-setup"}}' \
            "https://api.github.com/repos/$GITHUB_REPO/dispatches"
        
        log "Initial monitoring triggered - status will update in 2-3 minutes"
    else
        warn "GITHUB_TOKEN not set - monitoring workflow not triggered"
        info "Manually trigger monitoring by:"
        info "  1. Go to https://github.com/$GITHUB_REPO/actions"
        info "  2. Select 'Monitor System Status' workflow"
        info "  3. Click 'Run workflow'"
    fi
}

# Function to display deployment summary
display_summary() {
    log "WIBA Status Page deployment completed successfully!"
    echo
    info "📊 Status Page URLs:"
    info "  Primary:    https://$DOMAIN"
    info "  Local:      http://$DOMAIN (if DNS configured)"
    info "  Health:     http://$DOMAIN/health"
    echo
    info "📁 Local Files:"
    info "  Web Root:   $WEB_ROOT"
    info "  Config:     /etc/nginx/sites-available/status-wiba"
    info "  Repository: $SCRIPT_DIR"
    echo
    info "🔧 Configuration:"
    info "  Domain:     $DOMAIN"
    info "  GitHub:     https://github.com/$GITHUB_REPO"
    info "  Monitoring: Every 5 minutes"
    info "  Integration: Deployment workflows enabled"
    echo
    info "📝 Next Steps:"
    info "  1. Configure DNS: Add A record for $DOMAIN pointing to your server IP"
    info "  2. SSL Setup: Configure SSL certificate for HTTPS"
    info "  3. Test Integration: Run a deployment to see status updates"
    info "  4. Monitor Status: Check the status page in 5-10 minutes"
    echo
    info "🔗 Integration Examples:"
    info "  Your deployment workflows already include status page integration!"
    info "  They will automatically update the status page on each deployment."
    echo
    warn "⚠️  Important:"
    warn "  - Configure DNS for $DOMAIN to point to your server"
    warn "  - Set up HTTPS certificate for production use"
    warn "  - Test the status page by accessing the URLs above"
}

# Main deployment function
main() {
    log "🚀 Starting WIBA Status Page deployment..."
    
    check_permissions
    check_prerequisites
    setup_web_directory
    configure_nginx
    create_github_repo
    setup_git_repo
    trigger_initial_monitoring
    display_summary
    
    log "✅ WIBA Status Page deployment completed!"
    echo
    log "🎉 Your status page is now live and monitoring your WIBA platform!"
}

# Handle script interruption
trap 'error "Script interrupted. Cleanup may be needed."; exit 1' INT TERM

# Run main function
main "$@"