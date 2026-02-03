#!/bin/bash
set -euo pipefail

# Sovereign Autonomy Pack Synchronizer
# Version: 1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SYNC]${NC} $1"
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
Sovereign Autonomy Pack Synchronizer

Updates existing autonomy pack installations to the latest version while 
preserving local configuration and customizations.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --force                 Overwrite local modifications
    --dry-run               Show what would be updated
    --backup                Create backup before sync
    --from-url URL          Sync from specific canon URL
    --preserve-config       Keep all local configuration (default)
    -h, --help              Show this help

EXAMPLES:
    $0                      Standard sync (preserves config)
    $0 --dry-run            Preview changes
    $0 --force --backup     Force update with backup
    $0 --from-url https://... Sync from specific source

EOF
}

get_version() {
    if [ -f "$PACK_DIR/VERSION" ]; then
        cat "$PACK_DIR/VERSION"
    else
        echo "1.0.0"
    fi
}

get_installed_version() {
    local target_dir="${1:-.}"
    local version_file="$target_dir/.sovereign/autonomy/VERSION"
    
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo "none"
    fi
}

check_installation() {
    local target_dir="${1:-.}"
    
    if [ ! -f "$target_dir/.sovereign/autonomy/VERSION" ]; then
        error "No autonomy pack installation found in $target_dir"
        error "Run the installer first: ./install.sh"
        return 1
    fi
    
    return 0
}

create_backup() {
    local target_dir="${1:-.}"
    local backup_dir="$target_dir/.sovereign/autonomy/backups/$(date +%Y%m%d_%H%M%S)"
    
    log "Creating backup..."
    
    mkdir -p "$backup_dir"
    
    # Backup workflows
    if [ -d "$target_dir/.github/workflows" ]; then
        mkdir -p "$backup_dir/.github/workflows"
        cp "$target_dir/.github/workflows"/autonomous-*.yml "$backup_dir/.github/workflows/" 2>/dev/null || true
        cp "$target_dir/.github/workflows"/autonomy-*.yml "$backup_dir/.github/workflows/" 2>/dev/null || true
    fi
    
    # Backup agent instructions
    if [ -d "$target_dir/AGENTS" ]; then
        cp -r "$target_dir/AGENTS" "$backup_dir/" 2>/dev/null || true
    fi
    
    # Backup Makefile integration
    if [ -f "$target_dir/Makefile.autonomy" ]; then
        cp "$target_dir/Makefile.autonomy" "$backup_dir/" 2>/dev/null || true
    fi
    
    success "Backup created: $backup_dir"
    echo "$backup_dir" > "$target_dir/.sovereign/autonomy/LAST_BACKUP"
}

detect_local_modifications() {
    local target_dir="${1:-.}"
    local modifications=()
    
    # Check for workflow modifications
    local workflow_files=(
        ".github/workflows/autonomous-agent-loop.yml"
        ".github/workflows/autonomy-pr-review-gate.yml"
    )
    
    for workflow in "${workflow_files[@]}"; do
        if [ -f "$target_dir/$workflow" ] && [ -f "$PACK_DIR/workflows/$(basename "$workflow")" ]; then
            if ! cmp -s "$target_dir/$workflow" "$PACK_DIR/workflows/$(basename "$workflow")"; then
                modifications+=("$workflow")
            fi
        fi
    done
    
    # Check for agent instruction modifications
    if [ -d "$target_dir/AGENTS" ] && [ -d "$PACK_DIR/../root/AGENTS" ]; then
        for agent_file in "$target_dir/AGENTS"/*_AUTONOMOUS_INSTRUCTIONS.md; do
            if [ -f "$agent_file" ]; then
                local basename_file
                basename_file=$(basename "$agent_file")
                if [ -f "$PACK_DIR/../root/AGENTS/$basename_file" ]; then
                    if ! cmp -s "$agent_file" "$PACK_DIR/../root/AGENTS/$basename_file"; then
                        modifications+=("AGENTS/$basename_file")
                    fi
                fi
            fi
        done
    fi
    
    printf '%s\n' "${modifications[@]}"
}

update_workflows() {
    local target_dir="${1:-.}"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    
    log "Updating workflows..."
    
    local workflows_dir="$target_dir/.github/workflows"
    mkdir -p "$workflows_dir"
    
    local workflow_files=(
        "autonomous-agent-loop.yml"
        "autonomy-pr-review-gate.yml"
    )
    
    for workflow in "${workflow_files[@]}"; do
        local source_file="$PACK_DIR/workflows/$workflow"
        local target_file="$workflows_dir/$workflow"
        
        if [ ! -f "$source_file" ]; then
            warn "Source workflow not found: $source_file"
            continue
        fi
        
        if [ -f "$target_file" ] && [ "$force" != true ]; then
            if ! cmp -s "$source_file" "$target_file"; then
                warn "Local modifications detected in $workflow (use --force to overwrite)"
                continue
            fi
        fi
        
        if [ "$dry_run" = true ]; then
            log "[DRY-RUN] Would update: $workflow"
        else
            cp "$source_file" "$target_file"
            success "Updated: $workflow"
        fi
    done
}

update_agent_instructions() {
    local target_dir="${1:-.}"
    local force="${2:-false}"
    local dry_run="${3:-false}"
    
    log "Updating agent instructions..."
    
    local agents_dir="$target_dir/AGENTS"
    local source_agents_dir="$PACK_DIR/../root/AGENTS"
    
    if [ ! -d "$source_agents_dir" ]; then
        warn "Source agent instructions not found: $source_agents_dir"
        return
    fi
    
    mkdir -p "$agents_dir"
    
    for source_file in "$source_agents_dir"/*_AUTONOMOUS_INSTRUCTIONS.md; do
        if [ ! -f "$source_file" ]; then
            continue
        fi
        
        local basename_file
        basename_file=$(basename "$source_file")
        local target_file="$agents_dir/$basename_file"
        
        if [ -f "$target_file" ] && [ "$force" != true ]; then
            if ! cmp -s "$source_file" "$target_file"; then
                warn "Local modifications detected in $basename_file (use --force to overwrite)"
                continue
            fi
        fi
        
        if [ "$dry_run" = true ]; then
            log "[DRY-RUN] Would update: AGENTS/$basename_file"
        else
            cp "$source_file" "$target_file"
            success "Updated: AGENTS/$basename_file"
        fi
    done
}

update_version_marker() {
    local target_dir="${1:-.}"
    local dry_run="${2:-false}"
    
    local marker_dir="$target_dir/.sovereign/autonomy"
    local version_file="$marker_dir/VERSION"
    local sync_log="$marker_dir/SYNC_LOG.md"
    
    if [ "$dry_run" = true ]; then
        log "[DRY-RUN] Would update version marker to $(get_version)"
        return
    fi
    
    mkdir -p "$marker_dir"
    
    # Update version
    get_version > "$version_file"
    
    # Update sync log
    cat >> "$sync_log" << EOF

## Sync $(date -Iseconds)
**Version**: $(get_version)
**Script**: $0
**Options**: $*

### Changes Applied
- Workflows updated to latest version
- Agent instructions synchronized
- Version marker updated

🤖 Synchronized by Sovereign Autonomous System
EOF
    
    success "Version marker updated to v$(get_version)"
}

check_canon_updates() {
    local from_url="$1"
    
    if [ -n "$from_url" ]; then
        log "Checking for updates from: $from_url"
        
        # Download latest version info
        local latest_version
        latest_version=$(curl -fsSL "$from_url/VERSION" 2>/dev/null || echo "unknown")
        
        if [ "$latest_version" != "unknown" ]; then
            local current_version
            current_version=$(get_version)
            
            if [ "$latest_version" != "$current_version" ]; then
                log "Update available: v$current_version → v$latest_version"
                return 0
            else
                log "Already at latest version: v$current_version"
                return 1
            fi
        fi
    fi
    
    return 0
}

main() {
    local force=false
    local dry_run=false
    local backup=false
    local preserve_config=true
    local from_url=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                preserve_config=false
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --backup)
                backup=true
                shift
                ;;
            --from-url)
                from_url="$2"
                shift 2
                ;;
            --preserve-config)
                preserve_config=true
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
    
    echo "🔄 Sovereign Autonomy Pack Synchronizer v$(get_version)"
    echo ""
    
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        error "Not in a git repository"
        exit 1
    fi
    
    local target_dir="."
    
    # Check existing installation
    if ! check_installation "$target_dir"; then
        exit 1
    fi
    
    local installed_version
    installed_version=$(get_installed_version "$target_dir")
    local current_version
    current_version=$(get_version)
    
    log "Installed version: $installed_version"
    log "Available version: $current_version"
    
    # Check for updates from external source
    if [ -n "$from_url" ]; then
        if ! check_canon_updates "$from_url"; then
            log "No updates available"
            exit 0
        fi
    fi
    
    # Detect local modifications
    local modifications
    modifications=$(detect_local_modifications "$target_dir")
    
    if [ -n "$modifications" ] && [ "$preserve_config" = true ] && [ "$force" != true ]; then
        warn "Local modifications detected:"
        echo "$modifications" | sed 's/^/  - /'
        echo ""
        warn "Use --force to overwrite or continue sync with preservation"
        read -p "Continue with preservation? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log "Sync cancelled"
            exit 0
        fi
        force=false  # Ensure we preserve modifications
    fi
    
    # Create backup if requested
    if [ "$backup" = true ] && [ "$dry_run" != true ]; then
        create_backup "$target_dir"
    fi
    
    # Perform sync
    log "Starting synchronization..."
    
    update_workflows "$target_dir" "$force" "$dry_run"
    update_agent_instructions "$target_dir" "$force" "$dry_run"
    update_version_marker "$target_dir" "$dry_run"
    
    if [ "$dry_run" = true ]; then
        echo ""
        log "🔍 Dry run completed. No changes were made."
        log "Run without --dry-run to apply changes"
    else
        echo ""
        success "🎉 Synchronization completed successfully!"
        
        if [ -n "$modifications" ] && [ "$force" != true ]; then
            echo ""
            warn "Local modifications were preserved:"
            echo "$modifications" | sed 's/^/  - /'
        fi
        
        echo ""
        log "Next steps:"
        echo "  1. Test workflows: gh workflow run autonomous-agent-loop.yml"
        echo "  2. Verify installation: ./scripts/verify.sh"
        echo "  3. Check for issues: gh issue list"
    fi
}

main "$@"