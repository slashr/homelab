#!/bin/bash

# Homelab Health Check Script
# This script performs basic health checks on the homelab infrastructure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
K3S_MASTER_IP="100.100.1.100"
K3S_MASTER_PORT="6443"
TAILSCALE_IP="100.100.1.100"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        return 1
    fi
    log "kubectl is available"
}

# Check K3S cluster connectivity
check_k3s_connectivity() {
    log "Checking K3S cluster connectivity..."
    
    if ! kubectl cluster-info --server="https://${K3S_MASTER_IP}:${K3S_MASTER_PORT}" &> /dev/null; then
        error "Cannot connect to K3S cluster at ${K3S_MASTER_IP}:${K3S_MASTER_PORT}"
        return 1
    fi
    
    log "K3S cluster is reachable"
}

# Check cluster nodes
check_cluster_nodes() {
    log "Checking cluster nodes..."
    
    local nodes=$(kubectl get nodes --no-headers | wc -l)
    if [ "$nodes" -lt 2 ]; then
        warn "Only $nodes nodes found in cluster (expected at least 2)"
    else
        log "Found $nodes nodes in cluster"
    fi
    
    # Check node status
    local not_ready=$(kubectl get nodes --no-headers | grep -v "Ready" | wc -l)
    if [ "$not_ready" -gt 0 ]; then
        error "$not_ready nodes are not ready"
        kubectl get nodes
        return 1
    fi
    
    log "All nodes are ready"
}

# Check critical pods
check_critical_pods() {
    log "Checking critical pods..."
    
    local namespaces=("kube-system" "argo-cd" "cert-manager")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            local failed_pods=$(kubectl get pods -n "$ns" --no-headers | grep -v "Running\|Completed" | wc -l)
            if [ "$failed_pods" -gt 0 ]; then
                warn "Found $failed_pods non-running pods in namespace $ns"
                kubectl get pods -n "$ns" --no-headers | grep -v "Running\|Completed"
            else
                log "All pods in namespace $ns are running"
            fi
        else
            warn "Namespace $ns not found"
        fi
    done
}

# Check ArgoCD applications
check_argocd_apps() {
    log "Checking ArgoCD applications..."
    
    if kubectl get namespace "argo-cd" &> /dev/null; then
        local apps=$(kubectl get applications -n argo-cd --no-headers | wc -l)
        if [ "$apps" -gt 0 ]; then
            log "Found $apps ArgoCD applications"
            
            local unhealthy=$(kubectl get applications -n argo-cd --no-headers | grep -v "Healthy" | wc -l)
            if [ "$unhealthy" -gt 0 ]; then
                warn "Found $unhealthy unhealthy ArgoCD applications"
                kubectl get applications -n argo-cd --no-headers | grep -v "Healthy"
            else
                log "All ArgoCD applications are healthy"
            fi
        else
            warn "No ArgoCD applications found"
        fi
    else
        warn "ArgoCD namespace not found"
    fi
}

# Check Tailscale connectivity
check_tailscale() {
    log "Checking Tailscale connectivity..."
    
    if command -v tailscale &> /dev/null; then
        if tailscale status &> /dev/null; then
            log "Tailscale is running"
            
            local peers=$(tailscale status --json | jq -r '.Peer | keys | length' 2>/dev/null || echo "0")
            if [ "$peers" -gt 0 ]; then
                log "Connected to $peers Tailscale peers"
            else
                warn "No Tailscale peers found"
            fi
        else
            error "Tailscale is not running"
            return 1
        fi
    else
        warn "Tailscale CLI not found"
    fi
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$usage" -gt 90 ]; then
        error "Disk usage is at ${usage}% - critical!"
        return 1
    elif [ "$usage" -gt 80 ]; then
        warn "Disk usage is at ${usage}% - getting high"
    else
        log "Disk usage is at ${usage}% - healthy"
    fi
}

# Check memory usage
check_memory() {
    log "Checking memory usage..."
    
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$usage" -gt 90 ]; then
        error "Memory usage is at ${usage}% - critical!"
        return 1
    elif [ "$usage" -gt 80 ]; then
        warn "Memory usage is at ${usage}% - getting high"
    else
        log "Memory usage is at ${usage}% - healthy"
    fi
}

# Main health check function
main() {
    log "Starting homelab health check..."
    
    local exit_code=0
    
    # Run all checks
    check_kubectl || exit_code=1
    check_k3s_connectivity || exit_code=1
    check_cluster_nodes || exit_code=1
    check_critical_pods || exit_code=1
    check_argocd_apps || exit_code=1
    check_tailscale || exit_code=1
    check_disk_space || exit_code=1
    check_memory || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        log "All health checks passed! ✅"
    else
        error "Some health checks failed! ❌"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"
