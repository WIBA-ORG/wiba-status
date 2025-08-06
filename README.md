# WIBA Status Page

Automated status monitoring for WIBA platform services hosted on GitHub Pages.

🔗 **Live Status Page**: [wiba-org.github.io/wiba-status](https://wiba-org.github.io/wiba-status)

## Services Monitored

- **WIBA Platform** (Backend API)
- **WIBA Web Interface** (Frontend)
- **vLLM Service** (AI Model Service)
- **Database Connectivity**
- **API Endpoints** (detect, extract, stance)
- **Overall System Health**

## Features

- ✅ Real-time status updates
- 📊 Historical uptime tracking
- 🚀 Deployment notifications
- 📈 Performance metrics
- 🔄 Automated health checks every 5 minutes
- 📱 Mobile-responsive design
- 🌙 Dark/light theme support

## Architecture

- **Status Page**: Static GitHub Pages site
- **Monitoring**: GitHub Actions workflows
- **Data Storage**: JSON files in repository
- **Updates**: Automated via GitHub API
- **Integration**: Hooks into existing deployment workflows

## Setup

1. Enable GitHub Pages for this repository
2. Configure repository secrets for status updates
3. Integration happens automatically via deployment workflows

## Status Data Format

Status information is stored in `/data/status.json` and updated automatically.