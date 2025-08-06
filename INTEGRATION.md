# WIBA Status Page Integration Guide

This guide explains how to integrate the WIBA status page with your deployment workflows and monitoring systems.

## Quick Start

1. Run the setup script: `./setup.sh`
2. Enable GitHub Pages in repository settings
3. Your existing workflows will automatically update the status page

## Manual Status Updates

You can manually update deployment status using the provided script:

```bash
# Update deployment status
GITHUB_TOKEN="your_token" ./scripts/update-deployment-status.sh \
  "WIBA Platform" \
  "123" \
  "success" \
  "arman" \
  "abc123def456" \
  "2m 15s"
```

## GitHub Actions Integration

### Repository Dispatch Events

Send deployment updates via repository dispatch:

```bash
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "deployment-update",
    "client_payload": {
      "service": "WIBA Platform",
      "deployment_id": "123",
      "status": "success",
      "deployed_at": "2025-01-20T10:30:00Z",
      "deployed_by": "arman",
      "commit_sha": "abc123def456",
      "duration": "2m 15s"
    }
  }' \
  "https://api.github.com/repos/WIBA-ORG/wiba-status/dispatches"
```

### Workflow Integration

Add this step to your deployment workflows:

```yaml
- name: Update status page
  if: always()
  run: |
    curl -s -o update-status.sh https://raw.githubusercontent.com/WIBA-ORG/wiba-status/main/scripts/update-deployment-status.sh
    chmod +x update-status.sh
    
    GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}" ./update-status.sh \
      "Your Service Name" \
      "${{ github.run_number }}" \
      "${{ job.status }}" \
      "${{ github.actor }}" \
      "${{ github.sha }}" \
      "Duration here"
```

## Incident Management

### Creating Incidents via Issues

1. Create a GitHub issue in the status repository
2. Add the `incident` label
3. Add severity labels: `low`, `medium`, `high`, or `critical`
4. The incident will automatically appear on the status page

### Manual Incident Creation

Trigger the incident workflow manually:

1. Go to Actions → Manage Incidents → Run workflow
2. Fill in incident details
3. The incident will be created and displayed

### Incident Labels

- `incident` - Marks the issue as an incident
- `critical`, `high`, `medium`, `low` - Severity levels
- `in-progress` - Incident is being worked on

## Monitoring Configuration

The status page automatically monitors these services:

- **WIBA Platform**: https://wiba.dev/api/health
- **WIBA Web Interface**: https://wiba.dev/
- **API Endpoints**: /api/detect, /api/extract, /api/stance
- **vLLM Service**: Internal health check
- **Database**: Connectivity check

### Adding New Services

Edit `.github/workflows/monitor-status.yml` and add to the `SERVICES` array:

```javascript
{
  name: 'New Service',
  description: 'Description of the service',
  url: 'https://your-service-url/health',
  timeout: 30000,
  expectedContent: 'ok',
  critical: true
}
```

## Status Data Format

The status page uses JSON data stored in `data/status.json`:

```json
{
  "last_updated": "2025-01-20T12:00:00Z",
  "overall_status": {
    "status": "operational",
    "message": "All systems operational"
  },
  "services": [
    {
      "name": "Service Name",
      "description": "Service description",
      "status": "operational",
      "response_time": "45ms",
      "uptime": "99.9%",
      "message": null
    }
  ],
  "metrics": {
    "total_uptime": "99.87%",
    "avg_response_time": "171ms",
    "total_deployments": "47",
    "success_rate": "98.9%"
  },
  "recent_deployments": [],
  "incidents": []
}
```

## Status Values

### Service Status
- `operational` - Service is working normally
- `degraded` - Service has issues but is functional
- `down` - Service is not responding
- `maintenance` - Service is under maintenance

### Overall Status
- `operational` - All critical services working
- `degraded` - Some services have issues
- `down` - Critical services are down
- `maintenance` - System under maintenance

## Customization

### Theme
The status page supports dark/light themes. Users can toggle using the theme button.

### Styling
Edit `assets/style.css` to customize the appearance.

### Functionality
Edit `assets/script.js` to modify behavior.

## Troubleshooting

### Status Page Not Updating
1. Check GitHub Actions are running successfully
2. Verify GitHub Pages is enabled
3. Check repository secrets are configured
4. Ensure workflows have necessary permissions

### Monitoring Not Working
1. Check service URLs are accessible
2. Verify timeout values are appropriate
3. Check for firewall or network issues
4. Review workflow logs for errors

### Integration Issues
1. Verify GITHUB_TOKEN is available in workflows
2. Check repository dispatch events are being sent
3. Ensure status update script is accessible
4. Verify repository permissions

## API Reference

### Repository Dispatch Events

#### deployment-update
Updates deployment information:
```json
{
  "event_type": "deployment-update",
  "client_payload": {
    "service": "string",
    "deployment_id": "string",
    "status": "success|failed",
    "deployed_at": "ISO date string",
    "deployed_by": "string",
    "commit_sha": "string",
    "duration": "string"
  }
}
```

#### service-update
Triggers immediate health check:
```json
{
  "event_type": "service-update",
  "client_payload": {
    "service": "string",
    "trigger": "string"
  }
}
```

## Security Considerations

- Repository dispatch events require a valid GitHub token
- Status data is public via GitHub Pages
- Avoid including sensitive information in status messages
- Use repository secrets for tokens and credentials

## Support

For issues or questions:
1. Check the workflow logs in GitHub Actions
2. Review this documentation
3. Create an issue in the status repository
4. Check GitHub Pages deployment status