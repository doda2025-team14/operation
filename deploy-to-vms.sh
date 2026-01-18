#!/usr/bin/env bash

# deploy-to-vms.sh
# A script to deploy the application to an existing Kubernetes cluster running on local VMs

set -e  # Exit on any error
set -o pipefail  # Capture pipeline failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ADMIN_CONF="./shared/admin.conf"
HELM_CHART_DIR="./chart"
HELM_RELEASE_NAME="my-release"
TARGET_CONTEXT="kubernetes-admin@kubernetes"

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
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if required files exist
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_files=()
    
    # Check for admin.conf
    if [ ! -f "$ADMIN_CONF" ]; then
        missing_files+=("$ADMIN_CONF (Make sure VMs are provisioned with 'vagrant up')")
    fi
    
    # Check for Helm chart directory
    if [ ! -d "$HELM_CHART_DIR" ]; then
        missing_files+=("$HELM_CHART_DIR (Helm chart directory not found)")
    fi
    
    # Check for required tools
    if ! command -v kubectl &> /dev/null; then
        missing_files+=("kubectl (Kubernetes CLI tool)")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_files+=("helm (Helm package manager)")
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "Missing prerequisites:"
        for item in "${missing_files[@]}"; do
            echo "  - $item"
        done
        return 1
    fi
    
    log_success "All prerequisites met"
    return 0
}

# Wait for Kubernetes API to be ready
wait_for_kubernetes() {
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for Kubernetes API to become available..."
    
    while [ $attempt -le $max_attempts ]; do
        if KUBECONFIG="$ADMIN_CONF" kubectl cluster-info --request-timeout=10s 2>/dev/null; then
            log_success "Kubernetes API is ready"
            return 0
        fi
        
        if [ $attempt -eq 1 ]; then
            log_info "Kubernetes API not ready yet (this may take a few minutes)..."
        fi
        
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "Still waiting for Kubernetes API (attempt $attempt/$max_attempts)..."
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "Kubernetes API did not become ready within $((max_attempts * 10)) seconds"
    log_info "Check VM status with: vagrant status"
    log_info "Check Kubernetes logs with: vagrant ssh ctrl --command 'sudo journalctl -u kubelet'"
    return 1
}

# Run finalization playbook
run_finalization() {
    local private_key=".vagrant/machines/ctrl/virtualbox/private_key"
    
    log_info "Running finalization playbook..."
    
    # Check if private key exists
    if [ ! -f "$private_key" ]; then
        log_warning "Vagrant private key not found at $private_key"
        log_warning "Trying to find alternative key path..."
        
        # Try to find the key
        local found_key=$(find .vagrant -name "private_key" -type f | head -1)
        if [ -n "$found_key" ] && [ -f "$found_key" ]; then
            private_key="$found_key"
            log_info "Using private key at: $private_key"
        else
            log_error "Could not find Vagrant private key"
            return 1
        fi
    fi
    
    # Run ansible playbook
    ansible-playbook -i inventory.cfg playbooks/finalization.yml \
        --private-key="$private_key" \
        -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' \
        -u vagrant --limit ctrl
    
    if [ $? -ne 0 ]; then
        log_error "Finalization playbook failed"
        return 1
    fi
    
    log_success "Finalization playbook completed"
    return 0
}

# Merge kubeconfig
merge_kubeconfig() {
    log_info "Merging kubeconfig..."
    
    # Create .kube directory if it doesn't exist
    mkdir -p "$HOME/.kube"
    
    # Merge configurations
    KUBECONFIG=~/.kube/config:./shared/admin.conf \
    kubectl config view --raw --flatten > ~/.kube/config.tmp && \
    mv ~/.kube/config.tmp ~/.kube/config
    
    if [ $? -ne 0 ]; then
        log_error "Failed to merge kubeconfigs"
        return 1
    fi
    
    # List available contexts
    log_info "Available contexts after merge:"
    kubectl config get-contexts
}

# Switch kubectl context
switch_context() {
    log_info "Switching kubectl context..."
    
    # Check if target context exists
    if kubectl config get-contexts "$TARGET_CONTEXT" >/dev/null 2>&1; then
        kubectl config use-context "$TARGET_CONTEXT"
        log_success "Switched to context: $TARGET_CONTEXT"
        return 0
    fi
    
    log_warning "Context '$TARGET_CONTEXT' not found"
    log_info "Available contexts:"
    kubectl config get-contexts
    
    # Try to find kubernetes context
    local kubernetes_contexts=$(kubectl config get-contexts -o name | grep -i kubernetes)
    
    if [ -n "$kubernetes_contexts" ]; then
        # Use the first kubernetes context found
        local selected_context=$(echo "$kubernetes_contexts" | head -1)
        log_info "Selecting context: $selected_context"
        kubectl config use-context "$selected_context"
        log_success "Switched to context: $selected_context"
        TARGET_CONTEXT="$selected_context"  # Update for later use
        return 0
    fi
    
    # No kubernetes context found, ask user to select
    log_error "Could not automatically determine the correct context"
    log_info "Please select a context from the list above and run:"
    log_info "  kubectl config use-context <context-name>"
    return 1
}

# Verify cluster connectivity
verify_cluster() {
    log_info "Verifying cluster connectivity..."
    
    if kubectl cluster-info --request-timeout=15s >/dev/null 2>&1; then
        log_success "Successfully connected to Kubernetes cluster"
        
        # Display cluster info
        echo ""
        kubectl cluster-info | head -5
        echo ""
        
        # Show nodes
        log_info "Cluster nodes:"
        kubectl get nodes --show-labels
        echo ""
        
        return 0
    else
        log_error "Cannot connect to Kubernetes cluster"
        return 1
    fi
}

# Deploy with Helm
deploy_helm() {
    log_info "Deploying with Helm..."
    
    # Update Helm dependencies
    log_info "Updating Helm dependencies..."
    if [ -f "$HELM_CHART_DIR/Chart.yaml" ]; then
        helm dependency update "$HELM_CHART_DIR"
    fi
    
    # Check if release already exists
    if helm status "$HELM_RELEASE_NAME" >/dev/null 2>&1; then
        log_warning "Helm release '$HELM_RELEASE_NAME' already exists"
        read -p "Do you want to upgrade the existing release? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Upgrading release: $HELM_RELEASE_NAME"
            helm upgrade "$HELM_RELEASE_NAME" "$HELM_CHART_DIR" --dependency-update
        else
            log_info "Skipping deployment (release already exists)"
            return 0
        fi
    else
        log_info "Installing new release: $HELM_RELEASE_NAME"
        helm install "$HELM_RELEASE_NAME" "$HELM_CHART_DIR" --dependency-update
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Helm deployment failed"
        return 1
    fi
    
    log_success "Helm deployment completed"
    return 0
}

# Main execution
main() {
    echo "========================================="
    echo "   Kubernetes Cluster Deployment Script   "
    echo "========================================="
    echo ""
    
    # Step 1: Check prerequisites
    check_prerequisites || exit 1
    
    # Step 2: Wait for Kubernetes API
    wait_for_kubernetes || exit 1
    
    # Step 3: Run finalization playbook
    run_finalization || exit 1

    export KUBECONFIG="$(pwd)/shared/admin.conf"
    log_info "Using VM kubeconfig: $KUBECONFIG"
    
    # Step 4: Merge kubeconfig
    merge_kubeconfig || exit 1
    
    # Step 5: Switch context
    switch_context || exit 1
    
    # Step 6: Verify cluster connectivity
    verify_cluster || exit 1
    
    # Step 7: Deploy with Helm
    deploy_helm || exit 1
}

# Run main function
main "$@"