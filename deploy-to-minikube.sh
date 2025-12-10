#!/usr/bin/env bash

# deploy-to-minikube
# A script to deploy to Minikube with setup for Istio and required addons

set -e  # Exit on error
set -o pipefail  # Exit on pipeline errors

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_commands=()
    
    if ! command_exists minikube; then
        missing_commands+=("minikube")
    fi
    
    if ! command_exists kubectl; then
        missing_commands+=("kubectl")
    fi
    
    if ! command_exists istioctl; then
        missing_commands+=("istioctl")
    fi
    
    if ! command_exists helm; then
        missing_commands+=("helm")
    fi
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_info "Please install them before running this script."
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Main setup function
setup() {
    log_info "Starting Minikube setup..."
    
    # 1. Delete existing Minikube cluster
    log_info "Deleting existing Minikube cluster..."
    minikube delete || log_warning "No existing cluster to delete"
    
    # 2. Start Minikube with specific configuration
    log_info "Starting Minikube with custom configuration..."
    minikube start \
        --memory=6144 \
        --cpus=4 \
        --driver=docker
    
    # 3. Wait for Minikube to be ready
    log_info "Waiting for Minikube to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s

    # 4. Enable addons
    log_info "Enabling Minikube addons..."
    minikube addons enable ingress
    
    # 5. Install Istio
    log_info "Installing Istio..."
    istioctl install -y
    
    # 6. Wait for Istio components
    log_info "Waiting for all Istio pods to be ready..."
    kubectl wait --for=condition=ready pod --all -n istio-system --timeout=120s
    
    # 7. Install Helm chart
    log_info "Installing Helm chart..."
    if [ -d "chart" ]; then
        helm install my-release chart/ --dependency-update
    else
        log_warning "chart/ directory not found, skipping Helm install..."
    fi
    
    # 8. Final status check
    log_info "Checking cluster status..."
    echo ""
    echo "=== MINIKUBE STATUS ==="
    minikube status
    echo ""
    echo "=== ISTIO COMPONENTS ==="
    kubectl get pods -n istio-system
    echo ""
    echo "=== DEFAULT NAMESPACE ==="
    kubectl get pods
    
    log_success "Setup completed!"
}

# Function to clean up on script exit
cleanup() {
    log_info "Cleaning up..."

}

# Set trap for cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    check_prerequisites
    setup
}

# Run main function
main "$@"