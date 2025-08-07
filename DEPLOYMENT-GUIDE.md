# WIBA Status Page - Comprehensive Deployment Guide

This guide covers the complete setup of the WIBA Status Page system with dual deployment to GitHub Pages and a custom domain (status.wiba.dev).

## 📋 Overview

The WIBA Status Page provides:
- **Dual deployment**: GitHub Pages (backup) + Custom domain (primary)
- **Real-time monitoring**: 5-minute health checks of all WIBA services
- **Deployment tracking**: Integration with existing CI/CD workflows
- **Incident management**: Automated incident creation and tracking
- **Performance metrics**: Response times, uptime, and availability charts

## 🚀 Quick Start

### 1. Custom Domain Setup

Run the automated setup script:

```bash
cd /home/arman/wiba-repos/wiba-status
./setup-custom-domain.sh
```

This script will:
- Create `/var/www/status` directory
- Deploy status page files
- Configure nginx for `status.wiba.dev`
- Set proper permissions
- Test the configuration

### 2. DNS Configuration

Add an A record to your DNS provider:

```
Type: A
Name: status
Value: YOUR_SERVER_IP
TTL: 3600 (or default)
```

For Cloudflare, AWS Route 53, or your DNS provider:
- **Subdomain**: `status`
- **Target**: Your server's public IP address
- **Proxy status**: DNS only (orange cloud off for initial setup)

### 3. SSL Certificate Setup

Install and configure Let's Encrypt SSL:

```bash
# Install certbot if not already installed
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Generate SSL certificate for status.wiba.dev
sudo certbot --nginx -d status.wiba.dev

# Verify certificate
sudo certbot certificates
```

### 4. Verify Deployment

Test your status page:

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://status.wiba.dev

# Test HTTPS
curl -I https://status.wiba.dev

# Test health endpoint
curl https://status.wiba.dev/health
```

## 🔄 Automatic Updates

The status page is automatically updated through GitHub Actions:

### Monitoring (Every 5 minutes)
- **Workflow**: `.github/workflows/monitor-status.yml`
- **Triggers**: Schedule (cron), repository dispatch events
- **Actions**: Health checks, status updates, incident detection

### Deployment Tracking
- **Integration**: Existing deployment workflows in `wiba-platform` and `wiba-web-interface`
- **Updates**: Real-time deployment status, success/failure tracking
- **Rollback**: Automatic incident creation on deployment failures

### Custom Domain Sync
- **Workflow**: `.github/workflows/deploy-to-custom-domain.yml`
- **Frequency**: On changes, daily sync, manual trigger
- **Target**: `/var/www/status` on your server

## 🛠️ Configuration

### Environment Variables

Set these in your repository secrets:

```bash
GITHUB_TOKEN=ghp_...  # For API access and status updates
```

### Service Monitoring

Edit `.github/workflows/monitor-status.yml` to customize:

```javascript
const SERVICES = [
  {
    name: 'WIBA Platform',
    url: 'https://wiba.dev/api/health',
    critical: true,
    timeout: 30000
  },
  // Add more services as needed
];
```

### Nginx Configuration

The nginx configuration supports:
- **SSL termination** with Let's Encrypt
- **Security headers** (HSTS, CSP, X-Frame-Options)
- **Gzip compression** for better performance
- **CORS headers** for GitHub Pages integration
- **Health endpoint** at `/health`

## 📊 Monitoring Services

The status page monitors these services by default:

### Core Services (Critical)
- **WIBA Platform**: Backend API and core services
- **WIBA Web Interface**: Frontend website
- **vLLM Service**: AI model inference (port 8000)
- **Database**: Primary database connectivity

### API Endpoints (Non-critical)
- **API - Detect**: `/api/detect` endpoint
- **API - Extract**: `/api/extract` endpoint  
- **API - Stance**: `/api/stance` endpoint

### Infrastructure
- **Status Page**: This status page service
- **Nginx**: Web server health

## 🚨 Incident Management

### Automatic Incidents
- Created automatically on deployment failures
- Triggered by critical service outages
- Integrated with GitHub Issues (with `incident` label)

### Manual Incidents
```bash
# Via GitHub Actions workflow dispatch
# Go to Actions → Manage Incidents → Run workflow

# Or via API
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -d '{"event_type":"create-incident","client_payload":{"title":"Service Down","description":"Details here","severity":"high"}}' \
  https://api.github.com/repos/WIBA-ORG/wiba-status/dispatches
```

## 📈 Performance Features

### Real-time Metrics
- **Overall uptime**: 30-day rolling average
- **Response times**: Per-service monitoring
- **Deployment success rate**: Last 20 deployments
- **Incident resolution**: 7-day count

### Visual Components
- **Availability ring chart**: Shows overall system health
- **Response time bars**: Per-service performance
- **Status indicators**: Color-coded service status
- **Historical data**: Deployment and incident timeline

## 🔧 Maintenance

### Log Files
Monitor these log files:
```bash
# Nginx access/error logs
tail -f /var/log/nginx/status.wiba.dev.access.log
tail -f /var/log/nginx/status.wiba.dev.error.log

# GitHub Actions logs (via web interface)
# https://github.com/WIBA-ORG/wiba-status/actions
```

### Manual Updates
```bash
# Update status page files
cd /home/arman/wiba-repos/wiba-status
git pull
cp -r index.html assets/ data/ /var/www/status/
sudo chown -R www-data:www-data /var/www/status
```

### Backup and Recovery
```bash
# Backup current deployment
sudo cp -r /var/www/status /backup/status-$(date +%Y%m%d)

# Restore from backup
sudo cp -r /backup/status-YYYYMMDD/* /var/www/status/
sudo chown -R www-data:www-data /var/www/status
```

## 🌐 DNS Providers

### Cloudflare
1. Login to Cloudflare dashboard
2. Select your domain (wiba.dev)
3. Go to DNS → Records
4. Add record: `A | status | YOUR_SERVER_IP | TTL: Auto`
5. Set proxy status to "DNS only" (gray cloud)

### AWS Route 53
1. Open Route 53 console
2. Select hosted zone for wiba.dev
3. Create record: `status.wiba.dev` → `A` → `YOUR_SERVER_IP`

### Other Providers
Most DNS providers support similar A record configuration:
- **Name/Host**: `status`
- **Type**: `A`
- **Value/Target**: Your server's IP address
- **TTL**: 3600 seconds (or default)

## 🔒 Security Considerations

### SSL/TLS
- **Automatic renewal**: Certbot handles Let's Encrypt renewal
- **Strong ciphers**: TLS 1.2+ only, secure cipher suites
- **HSTS**: HTTP Strict Transport Security enabled

### Headers
- **CSP**: Content Security Policy prevents XSS
- **X-Frame-Options**: Prevents clickjacking
- **X-Content-Type-Options**: Prevents MIME sniffing

### Access Control
- **Status data**: Read-only public access
- **Management**: GitHub repository permissions
- **Server access**: SSH key authentication recommended

## 📞 Support

### Troubleshooting

**Status page not loading:**
1. Check DNS propagation: `dig status.wiba.dev`
2. Test nginx: `sudo nginx -t && sudo systemctl status nginx`
3. Check SSL: `openssl s_client -connect status.wiba.dev:443`

**Monitoring not updating:**
1. Check GitHub Actions: [Actions page](https://github.com/WIBA-ORG/wiba-status/actions)
2. Verify webhook permissions
3. Review workflow logs

**Custom domain sync issues:**
1. Ensure `/var/www/status` exists and is writable
2. Check nginx configuration
3. Verify self-hosted runner connectivity

### Contact
- **GitHub Issues**: [WIBA Status Repository](https://github.com/WIBA-ORG/wiba-status/issues)
- **System Admin**: Check server logs and GitHub Actions

---

## 📚 Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Guide](https://letsencrypt.org/getting-started/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [DNS Configuration Guide](https://developers.cloudflare.com/dns/)

**Status Page URL:**
- 🔗 **Primary**: https://status.wiba.dev