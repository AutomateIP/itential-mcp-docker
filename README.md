# 🐳 Itential MCP Server - Docker Deployment (Streamable HTTP Transport)

This directory contains Docker Compose configuration for deploying the Itential MCP Server in a containerized environment using **Streamable HTTP** transport.

> **Note**: The Itential MCP Server supports multiple transport methods (stdio, sse, streamable-http). This Docker setup is optimized for **streamable-http transport** which is ideal for containerized deployments and web-based integrations. For stdio transport, see the [main documentation](../README.md).

## 📋 Prerequisites

- Docker Engine 20.10+ 
- Docker Compose 2.0+
- Access to an Itential Platform instance
- OAuth credentials or basic auth credentials for Itential Platform

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

Use the provided start script for a fully automated setup:

```bash
# Clone the repository
git clone https://github.com/itential/itential-mcp.git
cd itential-mcp/itential-mcp-docker

# Run the automated setup script
./start.sh
```

The script will:
- ✅ Check all prerequisites (Docker, Docker Compose)
- ✅ Create configuration from template
- ✅ Prompt for your Itential Platform details
- ✅ Build and start the Docker containers
- ✅ Verify service health
- ✅ Display connection URLs and useful commands

**Script Options:**
```bash
./start.sh -d                    # Enable debug logging
./start.sh -c my-config.conf     # Use existing config file
./start.sh --no-build            # Skip Docker build
./start.sh --no-start            # Setup only, don't start
./start.sh --help                # Show all options
```

### Option 2: Manual Setup

If you prefer manual setup:

#### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/itential/itential-mcp.git
cd itential-mcp/itential-mcp-docker

# Copy configuration template
cp itential-mcp.conf.example itential-mcp.conf
```

#### 2. Configure Server

Edit the `itential-mcp.conf` file with your Itential Platform details:

```ini
[platform]
# Required: Itential Platform connection
host = your-platform-host.com

# Required: Authentication (choose OAuth or Basic Auth)
client_id = your-oauth-client-id
client_secret = your-oauth-client-secret
```

#### 3. Deploy

```bash
# Build and start the service
docker-compose up -d

# View logs
docker-compose logs -f itential-mcp

# Check health
curl http://localhost:8000/health
```

## 🔧 Configuration Options

The server is configured using the `itential-mcp.conf` configuration file. All options can also be overridden using environment variables.

### Server Configuration

Configure in the `[server]` section of `itential-mcp.conf`:

| Option | Default | Description |
|--------|---------|-------------|
| `transport` | `streamable-http` | Transport protocol (stdio, sse, streamable-http) |
| `host` | `0.0.0.0` | Server bind address |
| `port` | `8000` | Internal server port |
| `path` | `/mcp` | URL path for requests |
| `log_level` | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL) |

```ini
[server]
transport = streamable-http
host = 0.0.0.0
port = 8000
log_level = INFO
```

### Platform Connection

Configure in the `[platform]` section of `itential-mcp.conf`:

| Option | Default | Description |
|--------|---------|-------------|
| `host` | **Required** | Itential Platform hostname |
| `port` | `0` | Platform port (0 = auto-detect) |
| `disable_tls` | `false` | Disable HTTPS |
| `disable_verify` | `false` | Skip certificate verification |
| `timeout` | `30` | Connection timeout (seconds) |

```ini
[platform]
host = your-platform-host.com
port = 443
disable_tls = false
timeout = 30
```

### Authentication

**OAuth (Recommended):**
```ini
[platform]
client_id = your-oauth-client-id
client_secret = your-oauth-client-secret
```

**Basic Auth (Alternative):**
```ini
[platform]
user = admin
password = admin
```

### Tool Filtering

```ini
[server]
# Include only specific tools
include_tags = workflows,devices,jobs

# Exclude experimental tools
exclude_tags = experimental,beta,deprecated
```

## 🌐 Access URLs

Once deployed, the MCP server is accessible at:

- **External (from host)**: `http://localhost:8000/mcp`
- **Internal (from other containers)**: `http://itential-mcp:8000/mcp`
- **Health Check**: `http://localhost:8000/health`

## 📊 Available Tools

The MCP server provides comprehensive tools for Itential Platform automation including workflow management, device operations, compliance monitoring, and infrastructure management.

For a complete list of available tools and their documentation, see the [main project README](../README.md#-available-tools).

## 🔍 Monitoring & Health Checks

### Health Check Endpoint

```bash
curl http://localhost:8000/health
```

### Container Health

```bash
# Check container status
docker-compose ps

# View detailed health
docker inspect itential-mcp-server | jq '.[0].State.Health'

# Monitor logs
docker-compose logs -f --tail=100 itential-mcp
```

### Resource Monitoring

```bash
# Container resource usage
docker stats itential-mcp-server

# Detailed container info
docker-compose exec itential-mcp ps aux
```

## 🛠️ Development & Debugging

### Development Mode

```bash
# Enable debug logging in itential-mcp.conf
sed -i 's/log_level = INFO/log_level = DEBUG/' itential-mcp.conf

# Restart with new config
docker-compose restart itential-mcp

# Follow debug logs
docker-compose logs -f itential-mcp
```

### Interactive Debugging

```bash
# Access container shell
docker-compose exec itential-mcp /bin/bash

# Test platform connectivity (get host from config)
docker-compose exec itential-mcp curl -k https://your-platform-host.com/health

# Check configuration
docker-compose exec itential-mcp cat /app/itential-mcp.conf
```

### Local Development

```bash
# Mount local code for development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

## 🚨 Troubleshooting

### Common Issues

**Connection Refused:**
```bash
# Check if platform is accessible from container
docker-compose exec itential-mcp ping $ITENTIAL_MCP_PLATFORM_HOST

# For local development, use host.docker.internal
ITENTIAL_MCP_PLATFORM_HOST=host.docker.internal
```

**Authentication Failures:**
```bash
# Verify OAuth credentials
curl -X POST https://$ITENTIAL_MCP_PLATFORM_HOST/oauth/token \
  -d "client_id=$ITENTIAL_MCP_PLATFORM_CLIENT_ID" \
  -d "client_secret=$ITENTIAL_MCP_PLATFORM_CLIENT_SECRET" \
  -d "grant_type=client_credentials"

# Test basic auth
curl -u $ITENTIAL_MCP_PLATFORM_USER:$ITENTIAL_MCP_PLATFORM_PASSWORD \
  https://$ITENTIAL_MCP_PLATFORM_HOST/health
```

**SSL/TLS Issues:**
```bash
# For self-signed certificates
ITENTIAL_MCP_PLATFORM_DISABLE_VERIFY=true

# For HTTP-only connections
ITENTIAL_MCP_PLATFORM_DISABLE_TLS=true
```

**Performance Issues:**
```bash
# Increase timeout for slow networks
ITENTIAL_MCP_PLATFORM_TIMEOUT=60

# Adjust container resources in docker-compose.yml
```

### Log Analysis

```bash
# Search for specific errors
docker-compose logs itential-mcp | grep -i error

# Filter authentication logs
docker-compose logs itential-mcp | grep -i auth

# Monitor real-time activity
docker-compose logs -f itential-mcp | grep -E "(GET|POST|PUT|DELETE)"
```

## 🔒 Security Considerations

### Production Deployment

1. **Use OAuth Authentication**:
   ```bash
   # Avoid basic auth in production
   ITENTIAL_MCP_PLATFORM_CLIENT_ID=prod-client-id
   ITENTIAL_MCP_PLATFORM_CLIENT_SECRET=prod-client-secret
   ```

2. **Enable TLS**:
   ```bash
   ITENTIAL_MCP_PLATFORM_DISABLE_TLS=false
   ITENTIAL_MCP_PLATFORM_DISABLE_VERIFY=false
   ```

3. **Restrict Network Access**:
   ```yaml
   # In docker-compose.yml, bind to specific interface
   ports:
     - "127.0.0.1:8000:8000"  # localhost only
   ```

4. **Use Secrets Management**:
   ```bash
   # Use Docker secrets or external secret management
   docker secret create mcp_client_secret client_secret.txt
   ```

### Environment Security

```bash
# Secure .env file permissions
chmod 600 .env

# Use environment-specific configurations
cp .env.example .env.prod
cp .env.example .env.dev
```

## 📈 Scaling & Production

### Resource Limits

Adjust in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'      # Increase for high load
      memory: 1G       # Increase for large responses
    reservations:
      cpus: '1.0'
      memory: 512M
```

### Multiple Instances

```bash
# Scale horizontally
docker-compose up -d --scale itential-mcp=3

# Use load balancer (nginx, traefik, etc.)
```

### Monitoring Integration

```yaml
# Add monitoring services
services:
  prometheus:
    image: prom/prometheus
    # ... configuration

  grafana:
    image: grafana/grafana
    # ... configuration
```

## 🤝 Integration Examples

### LLM Integration

```json
# Example: Claude Desktop integration
{
  "mcpServers": {
    "itential": {
      "command": "curl",
      "args": ["-X", "POST", "http://localhost:8000/mcp"]
    }
  }
}
```

### API Gateway Integration

```nginx
# Nginx reverse proxy
location /mcp/ {
    proxy_pass http://itential-mcp:8000/mcp/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

## 📚 Additional Resources

- [Itential MCP Server Documentation](../README.md)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Itential Platform Documentation](https://docs.itential.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🆘 Support

For issues and questions:

1. Check the [troubleshooting section](#-troubleshooting)
2. Review container logs: `docker-compose logs itential-mcp`
3. Open an issue on [GitHub](https://github.com/itential/itential-mcp/issues)
4. Contact Itential Support for platform-specific issues
