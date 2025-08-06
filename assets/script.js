class StatusPage {
    constructor() {
        this.statusData = null;
        this.lastUpdate = null;
        this.theme = localStorage.getItem('theme') || 'light';
        
        this.init();
    }
    
    init() {
        this.setupTheme();
        this.bindEvents();
        this.loadStatus();
        
        // Auto-refresh every 30 seconds
        setInterval(() => this.loadStatus(), 30000);
    }
    
    setupTheme() {
        document.documentElement.setAttribute('data-theme', this.theme);
        this.updateThemeIcon();
    }
    
    bindEvents() {
        const themeToggle = document.getElementById('theme-toggle');
        themeToggle.addEventListener('click', () => this.toggleTheme());
    }
    
    toggleTheme() {
        this.theme = this.theme === 'light' ? 'dark' : 'light';
        localStorage.setItem('theme', this.theme);
        document.documentElement.setAttribute('data-theme', this.theme);
        this.updateThemeIcon();
    }
    
    updateThemeIcon() {
        const icon = document.querySelector('.theme-icon');
        icon.textContent = this.theme === 'light' ? '🌙' : '☀️';
    }
    
    async loadStatus() {
        try {
            const response = await fetch('data/status.json?t=' + Date.now());
            if (!response.ok) {
                throw new Error('Failed to fetch status data');
            }
            
            this.statusData = await response.json();
            this.lastUpdate = new Date();
            
            this.renderStatus();
            this.updateLastUpdated();
        } catch (error) {
            console.error('Error loading status:', error);
            this.renderError();
        }
    }
    
    renderStatus() {
        if (!this.statusData) return;
        
        this.renderOverallStatus();
        this.renderServices();
        this.renderMetrics();
        this.renderPerformance();
        this.renderDeployments();
        this.renderIncidents();
        this.renderDeploymentInfo();
    }
    
    renderOverallStatus() {
        const overallStatus = document.getElementById('overall-status');
        const overallMessage = document.getElementById('overall-message');
        
        const status = this.statusData.overall_status;
        const statusDot = overallStatus.querySelector('.status-dot');
        const statusText = overallStatus.querySelector('.status-text');
        
        // Remove loading class and set status
        statusDot.className = `status-dot ${status.status}`;
        statusText.textContent = this.getStatusText(status.status);
        overallMessage.textContent = status.message;
        
        // Update card background based on status
        overallStatus.className = `status-card overall ${status.status}`;
    }
    
    renderServices() {
        const servicesGrid = document.getElementById('services-grid');
        const services = this.statusData.services;
        
        servicesGrid.innerHTML = services.map(service => `
            <div class="service-card ${service.status}">
                <div class="service-header">
                    <div class="service-info">
                        <div class="service-name">${service.name}</div>
                        <div class="service-description">${service.description}</div>
                    </div>
                    <div class="status-indicator">
                        <div class="status-dot ${service.status}"></div>
                        <span class="status-text">${this.getStatusText(service.status)}</span>
                    </div>
                </div>
                ${service.message ? `<div class="service-message">${service.message}</div>` : ''}
                <div class="service-metrics">
                    <div class="metric">
                        <div class="metric-value">${service.response_time || 'N/A'}</div>
                        <div class="metric-label">Response Time</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">${service.uptime || 'N/A'}</div>
                        <div class="metric-label">Uptime (24h)</div>
                    </div>
                </div>
            </div>
        `).join('');
    }
    
    renderMetrics() {
        const metricsGrid = document.getElementById('metrics-grid');
        const metrics = this.statusData.metrics;
        
        metricsGrid.innerHTML = Object.entries(metrics).map(([key, value]) => {
            const metricConfig = this.getMetricConfig(key);
            return `
                <div class="metric-card">
                    <div class="metric-value">${value}</div>
                    <div class="metric-label">${metricConfig.label}</div>
                </div>
            `;
        }).join('');
    }
    
    renderDeployments() {
        const deploymentsList = document.getElementById('deployments-list');
        const deployments = this.statusData.recent_deployments || [];
        
        if (deployments.length === 0) {
            deploymentsList.innerHTML = '<div class="no-data">No recent deployments</div>';
            return;
        }
        
        deploymentsList.innerHTML = deployments.map(deployment => `
            <div class="deployment-item">
                <div class="deployment-header">
                    <div class="deployment-title">
                        ${deployment.service} - Deployment #${deployment.deployment_id}
                    </div>
                    <div class="deployment-time">${this.formatDate(deployment.deployed_at)}</div>
                </div>
                <div class="deployment-details">
                    <div class="deployment-detail">
                        <div class="deployment-detail-value ${deployment.status}">
                            ${this.getStatusText(deployment.status)}
                        </div>
                        <div class="deployment-detail-label">Status</div>
                    </div>
                    <div class="deployment-detail">
                        <div class="deployment-detail-value">${deployment.deployed_by}</div>
                        <div class="deployment-detail-label">Deployed By</div>
                    </div>
                    <div class="deployment-detail">
                        <div class="deployment-detail-value">${deployment.commit_sha.substring(0, 8)}</div>
                        <div class="deployment-detail-label">Commit</div>
                    </div>
                    <div class="deployment-detail">
                        <div class="deployment-detail-value">${deployment.duration || 'N/A'}</div>
                        <div class="deployment-detail-label">Duration</div>
                    </div>
                </div>
            </div>
        `).join('');
    }
    
    renderIncidents() {
        const incidentsList = document.getElementById('incidents-list');
        const incidents = this.statusData.incidents || [];
        
        if (incidents.length === 0) {
            incidentsList.innerHTML = '<div class="no-data">No recent incidents - all systems operational!</div>';
            return;
        }
        
        incidentsList.innerHTML = incidents.map(incident => `
            <div class="incident-item">
                <div class="incident-header">
                    <div class="incident-title">${incident.title}</div>
                    <div class="incident-time">${this.formatDate(incident.created_at)}</div>
                </div>
                <div class="incident-description">${incident.description}</div>
                <div class="incident-status ${incident.status}">
                    <div class="status-dot ${incident.status}"></div>
                    ${incident.status}
                </div>
            </div>
        `).join('');
    }
    
    renderError() {
        const overallStatus = document.getElementById('overall-status');
        const statusDot = overallStatus.querySelector('.status-dot');
        const statusText = overallStatus.querySelector('.status-text');
        const overallMessage = document.getElementById('overall-message');
        
        statusDot.className = 'status-dot down';
        statusText.textContent = 'Error';
        overallMessage.textContent = 'Unable to load status data. Please try again later.';
        overallStatus.className = 'status-card overall down';
    }
    
    updateLastUpdated() {
        const lastUpdatedElement = document.getElementById('last-updated');
        if (this.lastUpdate) {
            lastUpdatedElement.textContent = this.formatDate(this.lastUpdate);
        }
    }
    
    getStatusText(status) {
        const statusTexts = {
            operational: 'Operational',
            degraded: 'Degraded',
            down: 'Down',
            maintenance: 'Maintenance',
            success: 'Success',
            failed: 'Failed'
        };
        return statusTexts[status] || 'Unknown';
    }
    
    getMetricConfig(key) {
        const configs = {
            total_uptime: { label: 'Overall Uptime (30d)' },
            avg_response_time: { label: 'Avg Response Time' },
            total_deployments: { label: 'Deployments (30d)' },
            success_rate: { label: 'Deployment Success Rate' },
            active_services: { label: 'Active Services' },
            incidents_resolved: { label: 'Incidents Resolved (7d)' }
        };
        return configs[key] || { label: key.replace(/_/g, ' ').toUpperCase() };
    }
    
    renderPerformance() {
        const performanceGrid = document.getElementById('performance-grid');
        const services = this.statusData.services || [];
        
        // Calculate performance metrics
        const operationalServices = services.filter(s => s.status === 'operational').length;
        const totalServices = services.length;
        const availabilityPercentage = totalServices > 0 ? ((operationalServices / totalServices) * 100).toFixed(1) : '0';
        
        // Calculate average response time
        const responseTimes = services
            .map(s => parseFloat(s.response_time?.replace('ms', '') || '0'))
            .filter(t => !isNaN(t) && t > 0);
        const avgResponseTime = responseTimes.length > 0 
            ? Math.round(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length)
            : 0;
        
        performanceGrid.innerHTML = `
            <div class="performance-card">
                <div class="performance-chart">
                    <div class="availability-ring">
                        <svg width="100" height="100" viewBox="0 0 100 100">
                            <circle cx="50" cy="50" r="45" fill="none" stroke="var(--color-border)" stroke-width="8"></circle>
                            <circle cx="50" cy="50" r="45" fill="none" stroke="var(--color-success)" stroke-width="8"
                                stroke-dasharray="${availabilityPercentage * 2.83} 283"
                                stroke-dashoffset="70.75" 
                                transform="rotate(-90 50 50)"></circle>
                        </svg>
                        <div class="availability-text">
                            <span class="availability-value">${availabilityPercentage}%</span>
                            <span class="availability-label">Available</span>
                        </div>
                    </div>
                </div>
                <div class="performance-stats">
                    <div class="performance-stat">
                        <span class="stat-value">${avgResponseTime}ms</span>
                        <span class="stat-label">Avg Response</span>
                    </div>
                    <div class="performance-stat">
                        <span class="stat-value">${operationalServices}/${totalServices}</span>
                        <span class="stat-label">Services Up</span>
                    </div>
                </div>
            </div>
            <div class="response-time-chart">
                <h4>Response Times by Service</h4>
                <div class="response-bars">
                    ${services.map(service => {
                        const responseTime = parseFloat(service.response_time?.replace('ms', '') || '0');
                        const maxTime = Math.max(...responseTimes, 1000); // At least 1000ms for scale
                        const percentage = (responseTime / maxTime) * 100;
                        
                        return `
                            <div class="response-bar-item">
                                <div class="service-name-small">${service.name}</div>
                                <div class="response-bar-container">
                                    <div class="response-bar ${service.status}" style="width: ${percentage}%"></div>
                                    <span class="response-time-value">${service.response_time || 'N/A'}</span>
                                </div>
                            </div>
                        `;
                    }).join('')}
                </div>
            </div>
        `;
    }
    
    renderDeploymentInfo() {
        const deploymentInfo = document.getElementById('deployment-info');
        const systemInfo = this.statusData.system_info || {};
        
        if (systemInfo.last_deployment) {
            const deployment = systemInfo.last_deployment;
            deploymentInfo.innerHTML = `
                ${deployment.service} #${deployment.deployment_id} 
                (${deployment.status}) by ${deployment.deployed_by}
            `;
        } else {
            deploymentInfo.textContent = 'GitHub Actions';
        }
    }
    
    formatDate(dateString) {
        try {
            const date = new Date(dateString);
            const now = new Date();
            const diffInMinutes = Math.floor((now - date) / (1000 * 60));
            
            if (diffInMinutes < 1) {
                return 'Just now';
            } else if (diffInMinutes < 60) {
                return `${diffInMinutes}m ago`;
            } else if (diffInMinutes < 1440) {
                const hours = Math.floor(diffInMinutes / 60);
                return `${hours}h ago`;
            } else {
                return date.toLocaleDateString('en-US', {
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
            }
        } catch (error) {
            return dateString;
        }
    }
}

// Initialize the status page when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new StatusPage();
});