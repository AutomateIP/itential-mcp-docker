#!/bin/bash

# =============================================================================
# Itential MCP Server - Quick Start Script
# =============================================================================
# This script automates the setup and deployment of the Itential MCP Server
# in a Docker environment with streamable-http transport.
#
# Usage: ./start.sh [options]
# Options:
#   -h, --help          Show this help message
#   -c, --config        Path to existing config file (optional)
#   -d, --debug         Enable debug logging
#   --no-build          Skip Docker build (use existing image)
#   --no-start          Setup only, don't start containers
#
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CONFIG_FILE=""
DEBUG_MODE=false
NO_BUILD=false
NO_START=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
Itential MCP Server - Quick Start Script

This script automates the setup and deployment of the Itential MCP Server
in a Docker environment with streamable-http transport.

USAGE:
    ./start.sh [OPTIONS]

OPTIONS:
    -h, --help          Show this help message and exit
    -c, --config FILE   Use existing configuration file
    -d, --debug         Enable debug logging
    --no-build          Skip Docker build (use existing image)
    --no-start          Setup only, don't start containers

EXAMPLES:
    ./start.sh                          # Full setup with interactive config
    ./start.sh -d                       # Setup with debug logging enabled
    ./start.sh -c my-config.conf        # Use existing config file
    ./start.sh --no-build               # Skip build, use existing image
    ./start.sh --no-start               # Setup only, don't start containers

REQUIREMENTS:
    - Docker Engine 20.10+
    - Docker Compose 2.0+
    - Access to an Itential Platform instance
    - OAuth credentials or basic auth credentials

For more information, see README.md
EOF
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--debug)
                DEBUG_MODE=true
                shift
                ;;
            --no-build)
                NO_BUILD=true
                shift
                ;;
            --no-start)
                NO_START=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        print_error "Please install Docker Engine 20.10+ and try again"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available"
        print_error "Please install Docker Compose 2.0+ and try again"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        print_error "Please start Docker and try again"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to setup configuration
setup_config() {
    print_status "Setting up configuration..."
    
    if [[ -n "$CONFIG_FILE" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            print_status "Using provided config file: $CONFIG_FILE"
            cp "$CONFIG_FILE" "$SCRIPT_DIR/itential-mcp.conf"
        else
            print_error "Config file not found: $CONFIG_FILE"
            exit 1
        fi
    elif [[ -f "$SCRIPT_DIR/itential-mcp.conf" ]]; then
        print_warning "Configuration file already exists"
        read -p "Do you want to reconfigure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_interactive_config
        else
            print_status "Using existing configuration"
        fi
    else
        setup_interactive_config
    fi
    
    # Enable debug mode if requested
    if [[ "$DEBUG_MODE" == true ]]; then
        print_status "Enabling debug logging..."
        sed -i.bak 's/log_level = INFO/log_level = DEBUG/' "$SCRIPT_DIR/itential-mcp.conf" 2>/dev/null || true
        sed -i.bak 's/# log_level = INFO/log_level = DEBUG/' "$SCRIPT_DIR/itential-mcp.conf" 2>/dev/null || true
    fi
    
    print_success "Configuration setup complete"
}

# Function for interactive configuration
setup_interactive_config() {
    print_status "Creating configuration from template..."
    
    if [[ ! -f "$SCRIPT_DIR/itential-mcp.conf.example" ]]; then
        print_error "Configuration template not found: itential-mcp.conf.example"
        exit 1
    fi
    
    cp "$SCRIPT_DIR/itential-mcp.conf.example" "$SCRIPT_DIR/itential-mcp.conf"
    
    echo
    print_status "Please provide your Itential Platform details:"
    echo
    
    # Get Platform Host
    read -p "Itential Platform hostname (e.g., platform.company.com): " platform_host
    if [[ -n "$platform_host" ]]; then
        sed -i.bak "s/host = your-platform-host.com/host = $platform_host/" "$SCRIPT_DIR/itential-mcp.conf"
    fi
    
    # Get Platform Port
    read -p "Platform port (press Enter for auto-detect): " platform_port
    if [[ -n "$platform_port" ]]; then
        sed -i.bak "s/port = 0/port = $platform_port/" "$SCRIPT_DIR/itential-mcp.conf"
    fi
    
    # Choose authentication method
    echo
    print_status "Choose authentication method:"
    echo "1) OAuth (recommended)"
    echo "2) Basic Auth"
    read -p "Select option (1-2): " auth_choice
    
    case $auth_choice in
        1)
            echo
            read -p "OAuth Client ID: " client_id
            read -p "OAuth Client Secret: " client_secret
            
            if [[ -n "$client_id" ]]; then
                sed -i.bak "s/client_id = your-oauth-client-id/client_id = $client_id/" "$SCRIPT_DIR/itential-mcp.conf"
            fi
            if [[ -n "$client_secret" ]]; then
                sed -i.bak "s/client_secret = your-oauth-client-secret/client_secret = $client_secret/" "$SCRIPT_DIR/itential-mcp.conf"
            fi
            ;;
        2)
            echo
            read -p "Username: " username
            read -s -p "Password: " password
            echo
            
            if [[ -n "$username" ]]; then
                sed -i.bak "s/# user = admin/user = $username/" "$SCRIPT_DIR/itential-mcp.conf"
            fi
            if [[ -n "$password" ]]; then
                sed -i.bak "s/# password = admin/password = $password/" "$SCRIPT_DIR/itential-mcp.conf"
            fi
            
            # Comment out OAuth settings
            sed -i.bak "s/client_id = your-oauth-client-id/# client_id = your-oauth-client-id/" "$SCRIPT_DIR/itential-mcp.conf"
            sed -i.bak "s/client_secret = your-oauth-client-secret/# client_secret = your-oauth-client-secret/" "$SCRIPT_DIR/itential-mcp.conf"
            ;;
        *)
            print_warning "Invalid choice. Using OAuth with placeholder values."
            print_warning "Please edit itential-mcp.conf manually with your credentials."
            ;;
    esac
    
    # Clean up backup files
    rm -f "$SCRIPT_DIR/itential-mcp.conf.bak"
    
    echo
    print_success "Interactive configuration complete"
    print_status "You can edit itential-mcp.conf manually for additional customization"
}

# Function to build and start services
start_services() {
    print_status "Starting Itential MCP Server..."
    
    cd "$SCRIPT_DIR"
    
    if [[ "$NO_BUILD" == false ]]; then
        print_status "Building Docker image..."
        docker compose build
    else
        print_status "Skipping Docker build (using existing image)"
    fi
    
    if [[ "$NO_START" == false ]]; then
        print_status "Starting containers..."
        docker compose up -d
        
        # Wait for service to be ready
        print_status "Waiting for service to be ready..."
        sleep 5
        
        # Check health
        for i in {1..30}; do
            if curl -s http://localhost:8000/health > /dev/null 2>&1; then
                print_success "Service is healthy and ready!"
                break
            fi
            if [[ $i -eq 30 ]]; then
                print_warning "Service health check timed out"
                print_status "Check logs with: docker compose logs -f itential-mcp"
            else
                sleep 2
            fi
        done
    else
        print_status "Skipping container startup (setup only)"
    fi
}

# Function to show final status and instructions
show_final_status() {
    echo
    print_success "=== Itential MCP Server Setup Complete ==="
    echo
    
    if [[ "$NO_START" == false ]]; then
        print_status "Service URLs:"
        echo "  • MCP Server: http://localhost:8000/mcp"
        echo "  • Health Check: http://localhost:8000/health"
        echo
        
        print_status "Useful commands:"
        echo "  • View logs: docker compose logs -f itential-mcp"
        echo "  • Stop service: docker compose down"
        echo "  • Restart service: docker compose restart itential-mcp"
        echo "  • Check status: docker compose ps"
        echo
        
        print_status "Testing the service:"
        echo "  curl http://localhost:8000/health"
        echo
    fi
    
    print_status "Configuration file: $SCRIPT_DIR/itential-mcp.conf"
    print_status "For more information, see README.md"
    echo
}

# Main execution
main() {
    echo
    print_status "=== Itential MCP Server Quick Start ==="
    echo
    
    parse_args "$@"
    check_prerequisites
    setup_config
    start_services
    show_final_status
}

# Run main function with all arguments
main "$@"
