#!/bin/bash
# Setup script for WIBA Status Page custom domain (status.wiba.dev)
# This script configures nginx and helps with SSL setup

set -e

echo "🚀 WIBA Status Page Custom Domain Setup"
echo "========================================"

# Check if running as root or with sudo access
if [ "$EUID" -eq 0 ]; then
    SUDO_CMD=""
    echo "✅ Running as root"
elif sudo -n true 2>/dev/null; then
    SUDO_CMD="sudo"
    echo "✅ Sudo access confirmed"
else
    echo "❌ This script requires sudo access to configure nginx"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "❌ Nginx is not installed. Please install nginx first:"
    echo "   Ubuntu/Debian: sudo apt update && sudo apt install nginx"
    echo "   CentOS/RHEL: sudo yum install nginx"
    exit 1
fi

echo "✅ Nginx is installed"

# Create web root directory
echo "📁 Creating web root directory..."
$SUDO_CMD mkdir -p /var/www/status
$SUDO_CMD chown $USER:$USER /var/www/status

# Copy status page files
echo "📄 Copying status page files..."
cp -r index.html assets/ data/ /var/www/status/

# Create health endpoint
echo "OK" > /var/www/status/health

# Set proper permissions
$SUDO_CMD chown -R www-data:www-data /var/www/status
$SUDO_CMD chmod -R 644 /var/www/status
$SUDO_CMD find /var/www/status -type d -exec chmod 755 {} \;

echo "✅ Status page files deployed to /var/www/status"

# Check if nginx configuration already exists
NGINX_CONFIG="/etc/nginx/sites-available/wiba-status"
if [ -f "$NGINX_CONFIG" ]; then
    echo "⚠️  Nginx configuration already exists at $NGINX_CONFIG"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping nginx configuration..."
        SKIP_NGINX=true
    fi
fi

if [ "$SKIP_NGINX" != "true" ]; then
    echo "📝 Creating nginx configuration..."
    $SUDO_CMD cp nginx-status-config.conf "$NGINX_CONFIG"
    
    # Enable the site
    $SUDO_CMD ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/wiba-status
    
    echo "✅ Nginx configuration created and enabled"
fi

# Test nginx configuration
echo "🔍 Testing nginx configuration..."
if $SUDO_CMD nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed"
    echo "Please check the configuration and try again"
    exit 1
fi

# Ask if user wants to reload nginx now
read -p "Do you want to reload nginx now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "⚠️  Remember to reload nginx: sudo systemctl reload nginx"
else
    echo "🔄 Reloading nginx..."
    $SUDO_CMD systemctl reload nginx
    echo "✅ Nginx reloaded successfully"
fi

echo ""
echo "🎉 WIBA Status Page Custom Domain Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. 📡 DNS Configuration:"
echo "   Add an A record for 'status.wiba.dev' pointing to your server's IP"
echo "   Example: status.wiba.dev → YOUR_SERVER_IP"
echo ""
echo "2. 🔒 SSL Certificate (Let's Encrypt):"
echo "   Run: sudo certbot --nginx -d status.wiba.dev"
echo "   This will automatically configure HTTPS for your status page"
echo ""
echo "3. ✅ Verify Setup:"
echo "   Test HTTP: curl -H 'Host: status.wiba.dev' http://localhost/"
echo "   After SSL: https://status.wiba.dev"
echo ""
echo "4. 🔄 GitHub Actions:"
echo "   The deploy-to-custom-domain.yml workflow will automatically"
echo "   keep your custom domain synchronized with GitHub Pages"
echo ""

# Test local access
echo "🧪 Testing local access..."
if curl -f -H "Host: status.wiba.dev" http://localhost/health &>/dev/null; then
    echo "✅ Local health check passed"
else
    echo "⚠️  Local health check failed - nginx may need to be restarted"
    echo "   Try: sudo systemctl restart nginx"
fi

# Check if this is being run in GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
    echo ""
    echo "🤖 Running in GitHub Actions environment"
    echo "✅ Custom domain setup complete for automated deployment"
fi

echo ""
echo "📚 Additional Resources:"
echo "   • Nginx docs: https://nginx.org/en/docs/"
echo "   • Let's Encrypt: https://letsencrypt.org/"
echo "   • Certbot: https://certbot.eff.org/"
echo ""
echo "🔗 Your status page will be available at:"
echo "   Primary: https://status.wiba.dev (after DNS and SSL setup)"
echo "   Backup:  https://wiba-org.github.io/wiba-status"