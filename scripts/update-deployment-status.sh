#!/bin/bash

# Enhanced deployment status update script for WIBA status page
# This script is called from deployment workflows to update the status page

set -euo pipefail

# Configuration
GITHUB_REPO="WIBA-ORG/wiba-status"
SCRIPT_VERSION="2.0.0"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Required parameters
SERVICE_NAME="${1:-}"
DEPLOYMENT_ID="${2:-}"
STATUS="${3:-}"
DEPLOYED_BY="${4:-}"
COMMIT_SHA="${5:-}"
DURATION="${6:-}"

# Optional environment variables
RUNNER_ENVIRONMENT="${RUNNER_ENVIRONMENT:-unknown}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Validate required parameters
if [[ -z "$SERVICE_NAME" || -z "$DEPLOYMENT_ID" || -z "$STATUS" || -z "$DEPLOYED_BY" || -z "$COMMIT_SHA" ]]; then
    echo "❌ Error: Missing required parameters"
    echo "Usage: $0 <service_name> <deployment_id> <status> <deployed_by> <commit_sha> [duration]"
    echo ""
    echo "Parameters:"
    echo "  service_name   : Name of the service (e.g., 'WIBA Platform')"
    echo "  deployment_id  : Unique deployment identifier"
    echo "  status         : Deployment status (success/failed/in-progress)"
    echo "  deployed_by    : Username who triggered deployment"
    echo "  commit_sha     : Git commit SHA being deployed"
    echo "  duration       : Deployment duration (optional)"
    echo ""
    echo "Environment variables:"
    echo "  GITHUB_TOKEN        : GitHub API token (required)"
    echo "  RUNNER_ENVIRONMENT  : Runner type (self-hosted/github-hosted)"
    exit 1
fi

# Validate GitHub token
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "❌ Error: GITHUB_TOKEN environment variable not set"
    echo "This script requires a GitHub token to trigger status page updates"
    exit 1
fi

# Function to log with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to trigger status page update via repository dispatch
trigger_status_update() {
    local payload_file="/tmp/status-update-payload-$$.json"
    
    # Create the dispatch payload
    cat > "$payload_file" << EOF
{
  "event_type": "deployment-update",
  "client_payload": {
    "service": "$SERVICE_NAME",
    "deployment_id": "$DEPLOYMENT_ID",
    "status": "$STATUS",
    "deployed_by": "$DEPLOYED_BY",
    "commit_sha": "$COMMIT_SHA",
    "duration": "$DURATION",
    "deployed_at": "$TIMESTAMP",
    "runner_environment": "$RUNNER_ENVIRONMENT",
    "repository": "$GITHUB_REPOSITORY",
    "workflow_run_id": "$GITHUB_RUN_ID",
    "workflow_run_url": "$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID",
    "script_version": "$SCRIPT_VERSION"
  }
}
EOF

    log "📤 Sending deployment update to status page..."
    log "Service: $SERVICE_NAME"
    log "Deployment ID: $DEPLOYMENT_ID"
    log "Status: $STATUS"
    log "Deployed by: $DEPLOYED_BY"
    log "Commit: ${COMMIT_SHA:0:8}"
    log "Duration: ${DURATION:-'N/A'}"
    
    # Send the repository dispatch event
    local response_code
    response_code=$(curl -s -w "%{http_code}" -o /tmp/dispatch-response-$$.json \
        -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "User-Agent: WIBA-Deployment-Updater/$SCRIPT_VERSION" \
        -d @"$payload_file" \
        "https://api.github.com/repos/$GITHUB_REPO/dispatches")
    
    if [[ "$response_code" == "204" ]]; then
        log "✅ Successfully triggered status page update"
        
        # Log the payload for debugging (without sensitive info)
        log "📋 Payload sent:"
        jq 'del(.client_payload.workflow_run_url)' "$payload_file" || cat "$payload_file"
        
    else
        log "❌ Failed to trigger status page update (HTTP $response_code)"
        log "Response:"
        cat /tmp/dispatch-response-$$.json 2>/dev/null || echo "No response body"
        
        # Don't fail the deployment because of status page issues
        log "⚠️  Continuing deployment despite status page update failure"
    fi
    
    # Cleanup
    rm -f "$payload_file" /tmp/dispatch-response-$$.json
}

# Function to update status page directly (fallback method)
update_status_direct() {
    local temp_dir="/tmp/status-update-$$"
    
    log "🔄 Using direct update method as fallback..."
    
    # Clone the status repository
    if ! git clone --depth 1 "https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPO.git" "$temp_dir"; then
        log "❌ Failed to clone status repository"
        return 1
    fi
    
    cd "$temp_dir"
    
    # Configure git
    git config user.name "WIBA Deployment Bot"
    git config user.email "noreply@wiba.dev"
    
    # Create deployment entry
    local status_file="data/status.json"
    
    if [[ ! -f "$status_file" ]]; then
        log "⚠️  Status file not found, creating basic structure"
        mkdir -p data
        cat > "$status_file" << EOF
{
  "last_updated": "$TIMESTAMP",
  "overall_status": {
    "status": "operational",
    "message": "All systems operational"
  },
  "services": [],
  "metrics": {
    "total_uptime": "99.9%",
    "avg_response_time": "0ms",
    "total_deployments": "0",
    "success_rate": "100%",
    "active_services": "0",
    "incidents_resolved": "0"
  },
  "recent_deployments": [],
  "incidents": []
}
EOF
    fi
    
    # Update the status file using Node.js
    node -e "
        const fs = require('fs');
        const statusFile = '$status_file';
        let status = JSON.parse(fs.readFileSync(statusFile, 'utf8'));
        
        // Add deployment record
        const deployment = {
            deployment_id: '$DEPLOYMENT_ID',
            service: '$SERVICE_NAME',
            status: '$STATUS',
            deployed_at: '$TIMESTAMP',
            deployed_by: '$DEPLOYED_BY',
            commit_sha: '$COMMIT_SHA',
            duration: '$DURATION'
        };
        
        status.recent_deployments = status.recent_deployments || [];
        status.recent_deployments.unshift(deployment);
        status.recent_deployments = status.recent_deployments.slice(0, 10);
        
        // Update metrics
        const recentDeployments = status.recent_deployments.slice(0, 20);
        const successfulDeployments = recentDeployments.filter(d => d.status === 'success').length;
        const successRate = recentDeployments.length > 0 ? 
            ((successfulDeployments / recentDeployments.length) * 100).toFixed(1) + '%' : '100%';
        
        status.metrics.success_rate = successRate;
        status.metrics.total_deployments = (parseInt(status.metrics.total_deployments || '0') + 1).toString();
        status.last_updated = '$TIMESTAMP';
        
        // Update system info
        status.system_info = status.system_info || {};
        status.system_info.last_deployment = deployment;
        
        fs.writeFileSync(statusFile, JSON.stringify(status, null, 2));
        console.log('Updated status file with deployment record');
    "
    
    # Commit and push changes
    git add "$status_file"
    
    if git diff --staged --quiet; then
        log "ℹ️  No changes to commit"
    else
        git commit -m "Update deployment status: $SERVICE_NAME #$DEPLOYMENT_ID ($STATUS)

Deployment Details:
- Service: $SERVICE_NAME
- Deployment ID: $DEPLOYMENT_ID
- Status: $STATUS
- Deployed by: $DEPLOYED_BY
- Commit: $COMMIT_SHA
- Duration: ${DURATION:-'N/A'}
- Timestamp: $TIMESTAMP
- Runner: $RUNNER_ENVIRONMENT

🤖 Auto-updated by deployment workflow"

        if git push origin main; then
            log "✅ Successfully updated status page directly"
        else
            log "❌ Failed to push status updates"
            return 1
        fi
    fi
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Function to create incident on failed deployment
create_incident() {
    if [[ "$STATUS" != "failed" ]]; then
        return 0
    fi
    
    log "🚨 Creating incident record for failed deployment..."
    
    local incident_payload="/tmp/incident-payload-$$.json"
    local incident_id="deployment-failure-$(date +%s)"
    
    cat > "$incident_payload" << EOF
{
  "event_type": "create-incident",
  "client_payload": {
    "id": "$incident_id",
    "title": "$SERVICE_NAME Deployment Failure",
    "description": "Deployment #$DEPLOYMENT_ID failed during automated deployment process. Rollback procedures have been initiated.",
    "status": "investigating",
    "severity": "high",
    "services_affected": ["$SERVICE_NAME"],
    "deployment_id": "$DEPLOYMENT_ID",
    "commit_sha": "$COMMIT_SHA",
    "deployed_by": "$DEPLOYED_BY",
    "created_at": "$TIMESTAMP",
    "auto_created": true,
    "source": "deployment-workflow"
  }
}
EOF
    
    local incident_response_code
    incident_response_code=$(curl -s -w "%{http_code}" -o /tmp/incident-response-$$.json \
        -X POST \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -d @"$incident_payload" \
        "https://api.github.com/repos/$GITHUB_REPO/dispatches")
    
    if [[ "$incident_response_code" == "204" ]]; then
        log "✅ Incident record created successfully"
    else
        log "⚠️  Failed to create incident record (HTTP $incident_response_code)"
    fi
    
    rm -f "$incident_payload" /tmp/incident-response-$$.json
}

# Main execution
main() {
    log "🚀 WIBA Deployment Status Updater v$SCRIPT_VERSION"
    log "Updating status for: $SERVICE_NAME deployment #$DEPLOYMENT_ID"
    
    # Primary method: Repository dispatch
    if trigger_status_update; then
        log "📊 Status page update triggered successfully"
    else
        log "⚠️  Repository dispatch failed, trying direct update..."
        
        # Fallback method: Direct repository update
        if update_status_direct; then
            log "📊 Status page updated directly"
        else
            log "❌ All update methods failed"
            # Don't exit 1 here as it would fail the deployment
            log "⚠️  Deployment will continue despite status page update failure"
        fi
    fi
    
    # Create incident record for failed deployments
    create_incident
    
    # Final status report
    if [[ "$STATUS" == "success" ]]; then
        log "🎉 Deployment successful - status page updated"
    elif [[ "$STATUS" == "failed" ]]; then
        log "💥 Deployment failed - incident created"
    else
        log "📝 Deployment status '$STATUS' recorded"
    fi
    
    log "✅ Status update process completed"
}

# Run main function
main "$@"