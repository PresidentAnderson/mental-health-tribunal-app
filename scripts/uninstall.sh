#!/bin/bash
set -euo pipefail

# Sovereign Autonomy Pack Uninstaller
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SOVEREIGN]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

usage() {
    cat << EOF
Sovereign Autonomy Pack Uninstaller

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --confirm               Confirm uninstallation (required)
    --preserve-labels       Keep GitHub labels
    --preserve-agents       Keep AGENTS/ directory
    -h, --help              Show this help

EXAMPLES:
    $0 --confirm
    $0 --confirm --preserve-labels --preserve-agents

EOF
}

check_installation() {
    local version_marker=".sovereign/autonomy/VERSION"
    
    if [ ! -f "$version_marker" ]; then
        error "Autonomy pack not found. Nothing to uninstall."
        exit 1
    fi
    
    local version
    version=$(cat "$version_marker")
    log "Found autonomy pack installation: v$version"
    
    return 0
}

remove_workflows() {
    log "Removing autonomy workflows..."
    
    local workflows_dir=".github/workflows"
    
    if [ -f "$workflows_dir/autonomous-agent-loop.yml" ]; then
        rm "$workflows_dir/autonomous-agent-loop.yml"
        success "Removed: autonomous-agent-loop.yml"
    fi
    
    if [ -f "$workflows_dir/autonomy-pr-review-gate.yml" ]; then
        rm "$workflows_dir/autonomy-pr-review-gate.yml"
        success "Removed: autonomy-pr-review-gate.yml"
    fi
}

remove_makefile_integration() {
    log "Removing Makefile integration..."
    
    if [ -f "Makefile.autonomy" ]; then
        rm "Makefile.autonomy"
        success "Removed: Makefile.autonomy"
    fi
    
    # Remove include line from main Makefile
    if [ -f "Makefile" ] && grep -q "include Makefile.autonomy" "Makefile"; then
        # Remove the include line and any preceding comment
        sed -i '/# Sovereign Autonomy Pack/d; /include Makefile\.autonomy/d' "Makefile"
        success "Removed autonomy integration from Makefile"
    fi
}

remove_agent_workspace() {
    log "Removing agent workspace..."
    
    if [ -d ".agent-workspace" ]; then
        rm -rf ".agent-workspace"
        success "Removed: .agent-workspace/"
    fi
    
    # Remove any implementation files
    for impl in IMPLEMENTATION_*.md; do
        if [ -f "$impl" ]; then
            rm "$impl"
            success "Removed: $impl"
        fi
    done
    
    # Remove session summaries
    for session in AUTONOMOUS_SESSION_*.md; do
        if [ -f "$session" ]; then
            rm "$session"
            success "Removed: $session"
        fi
    done
}

remove_labels() {
    log "Removing autonomy GitHub labels..."
    
    local repo_name
    repo_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
    
    if [ -z "$repo_name" ]; then
        warn "Cannot determine repository name. Skipping label removal."
        return
    fi
    
    local labels=(
        "priority:critical"
        "priority:high"
        "priority:medium"
        "priority:low"
        "status:pr-created"
        "status:agent-assigned"
        "agent:handoff"
        "agent:validated"
        "review:claude-required"
        "security:review-required"
        "security:cleared"
    )
    
    for label in "${labels[@]}"; do
        if gh label list --repo "$repo_name" --json name --jq '.[].name' | grep -q "^$label$"; then
            gh label delete "$label" --repo "$repo_name" --confirm 2>/dev/null || true
            success "Removed label: $label"
        fi
    done
}

remove_version_marker() {
    log "Removing installation marker..."
    
    if [ -d ".sovereign/autonomy" ]; then
        rm -rf ".sovereign/autonomy"
        success "Removed: .sovereign/autonomy/"
    fi
    
    # Remove .sovereign directory if empty
    if [ -d ".sovereign" ] && [ -z "$(ls -A .sovereign)" ]; then
        rmdir ".sovereign"
        success "Removed empty .sovereign/ directory"
    fi
}

main() {
    local confirm=false
    local preserve_labels=false
    local preserve_agents=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --confirm)
                confirm=true
                shift
                ;;
            --preserve-labels)
                preserve_labels=true
                shift
                ;;
            --preserve-agents)
                preserve_agents=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Require confirmation
    if [ "$confirm" != true ]; then
        error "Uninstallation requires --confirm flag for safety"
        echo "This will remove:"
        echo "  - Autonomy workflows (.github/workflows/)"
        echo "  - Makefile integration"
        echo "  - Agent workspace and generated files"
        echo "  - GitHub labels (unless --preserve-labels)"
        echo "  - AGENTS/ directory (unless --preserve-agents)"
        echo "  - Installation markers (.sovereign/autonomy/)"
        echo ""
        echo "Run with --confirm to proceed"
        exit 1
    fi
    
    # Banner
    echo "🗑️  Sovereign Autonomy Pack Uninstaller"
    echo ""
    
    # Check if git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        error "Not in a git repository"
        exit 1
    fi
    
    # Check installation
    check_installation
    
    # Confirm one more time
    echo ""
    warn "This will permanently remove the Sovereign Autonomy Pack from this repository."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Uninstallation cancelled"
        exit 0
    fi
    
    # Remove components
    remove_workflows
    remove_makefile_integration
    remove_agent_workspace
    
    if [ "$preserve_labels" != true ]; then
        remove_labels
    else
        log "Preserving GitHub labels (--preserve-labels)"
    fi
    
    if [ "$preserve_agents" != true ]; then
        if [ -d "AGENTS" ]; then
            rm -rf "AGENTS"
            success "Removed: AGENTS/ directory"
        fi
    else
        log "Preserving AGENTS/ directory (--preserve-agents)"
    fi
    
    remove_version_marker
    
    # Final message
    echo ""
    success "🎉 Sovereign Autonomy Pack successfully uninstalled!"
    echo ""
    log "What was removed:"
    echo "  ✅ Autonomy workflows"
    echo "  ✅ Makefile integration"
    echo "  ✅ Agent workspace and generated files"
    echo "  ✅ Installation markers"
    [ "$preserve_labels" != true ] && echo "  ✅ GitHub labels"
    [ "$preserve_agents" != true ] && echo "  ✅ AGENTS/ directory"
    echo ""
    
    if [ "$preserve_labels" = true ] || [ "$preserve_agents" = true ]; then
        log "Preserved components can be removed manually if needed"
    fi
    
    log "Repository is now clean of autonomy pack components"
}

main "$@"