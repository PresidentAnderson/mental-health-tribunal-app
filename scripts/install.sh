#!/bin/bash
set -euo pipefail

# Sovereign Autonomy Pack Installer
# Version: 1.0.0
# Description: Installs autonomous agent workflows into any repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$PACK_DIR/VERSION"
DEFAULTS_FILE="$PACK_DIR/autonomy.defaults.yml"

# Configuration
DRY_RUN=false
FORCE=false
ALLOW_CONTINUOUS=false
ORG_MODE=false
TARGET_ORG=""
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
Sovereign Autonomy Pack Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --dry-run                Run without making changes
    --force                  Overwrite existing installation
    --allow-continuous       Allow unlimited issue processing (24/7 mode)
    --org ORG_NAME          Install across all repos in organization
    --all-repos             Use with --org to include all repos
    --verbose               Verbose output
    -h, --help              Show this help

EXAMPLES:
    # Install in current repository
    $0

    # Dry run to see what would be installed
    $0 --dry-run

    # Install across entire organization
    $0 --org Sovereign-Operating-System --all-repos

    # Force reinstall with continuous mode enabled
    $0 --force --allow-continuous

QUICK INSTALL:
    curl -fsSL https://raw.githubusercontent.com/Sovereign-Operating-System/sovereign-canon/main/packs/autonomy/scripts/install.sh | bash

EOF
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if gh CLI is installed and authenticated
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install from: https://github.com/cli/cli"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        error "GitHub CLI is not authenticated. Run: gh auth login"
        exit 1
    fi
    
    # Check if we're in a git repository (unless org mode)
    if [ "$ORG_MODE" = false ]; then
        if ! git rev-parse --is-inside-work-tree &> /dev/null; then
            error "Not in a git repository. Change to repository root or use --org mode."
            exit 1
        fi
        
        # Check repository permissions
        REPO_NAME=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
        if [ -z "$REPO_NAME" ]; then
            error "Cannot determine repository name. Ensure you're in a valid GitHub repository."
            exit 1
        fi
        
        log "Installing in repository: $REPO_NAME"
    fi
    
    success "Prerequisites validated"
}

get_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "1.0.0"
    fi
}

check_existing_installation() {
    local target_dir="${1:-.}"
    local version_marker="$target_dir/.sovereign/autonomy/VERSION"
    
    if [ -f "$version_marker" ]; then
        local installed_version
        installed_version=$(cat "$version_marker")
        local current_version
        current_version=$(get_version)
        
        if [ "$installed_version" = "$current_version" ] && [ "$FORCE" = false ]; then
            warn "Autonomy pack version $installed_version already installed. Use --force to reinstall."
            return 1
        fi
        
        log "Found existing installation (v$installed_version), upgrading to v$current_version"
    fi
    
    return 0
}

create_required_labels() {
    local repo_name="$1"
    
    log "Creating required GitHub labels..."
    
    # Priority labels
    gh label create --repo "$repo_name" "priority:critical" --description "Critical priority issue requiring immediate attention" --color "ff0000" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "priority:high" --description "High priority issue" --color "ff8800" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "priority:medium" --description "Medium priority issue" --color "ffaa00" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "priority:low" --description "Low priority issue" --color "ffdd00" --force 2>/dev/null || true
    
    # Status labels
    gh label create --repo "$repo_name" "status:pr-created" --description "Issue has been processed and PR created by autonomous agent" --color "00ff00" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "status:agent-assigned" --description "Issue assigned to autonomous agent" --color "0088ff" --force 2>/dev/null || true
    
    # Agent labels
    gh label create --repo "$repo_name" "agent:handoff" --description "Agent handoff to Claude for review" --color "8800ff" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "agent:validated" --description "Autonomous PR passed validation" --color "00ff88" --force 2>/dev/null || true
    
    # Review labels
    gh label create --repo "$repo_name" "review:claude-required" --description "Claude review required for merge" --color "ff0088" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "security:review-required" --description "Security review required" --color "aa0000" --force 2>/dev/null || true
    gh label create --repo "$repo_name" "security:cleared" --description "Security review completed and cleared" --color "00aa00" --force 2>/dev/null || true
    
    success "GitHub labels created/updated"
}

install_workflows() {
    local target_dir="${1:-.}"
    local workflows_dir="$target_dir/.github/workflows"
    
    log "Installing autonomy workflows..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create: $workflows_dir/"
        log "[DRY-RUN] Would install: autonomous-agent-loop.yml"
        log "[DRY-RUN] Would install: autonomy-pr-review-gate.yml"
        return
    fi
    
    mkdir -p "$workflows_dir"
    
    # Copy workflows
    cp "$PACK_DIR/workflows/autonomous-agent-loop.yml" "$workflows_dir/"
    cp "$PACK_DIR/workflows/autonomy-pr-review-gate.yml" "$workflows_dir/"
    
    # Apply configuration overrides if continuous mode not allowed
    if [ "$ALLOW_CONTINUOUS" = false ]; then
        # Ensure max_issues defaults are safe
        sed -i 's/default: '\''5'\''/default: '\''1'\''/g' "$workflows_dir/autonomous-agent-loop.yml" 2>/dev/null || true
    fi
    
    success "Workflows installed: $workflows_dir"
}

install_agent_instructions() {
    local target_dir="${1:-.}"
    local agents_dir="$target_dir/AGENTS"
    
    log "Installing agent instructions..."
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create: $agents_dir/"
        log "[DRY-RUN] Would install agent instruction files"
        return
    fi
    
    mkdir -p "$agents_dir"
    
    # Copy agent instruction files from canon
    if [ -d "$PACK_DIR/../root/AGENTS" ]; then
        cp -r "$PACK_DIR/../root/AGENTS"/* "$agents_dir/" 2>/dev/null || true
    fi
    
    # Ensure we have at least basic agent instructions
    for agent in CODEX CLAUDE COPILOT SPARKS; do
        if [ ! -f "$agents_dir/${agent}_AUTONOMOUS_INSTRUCTIONS.md" ]; then
            cat > "$agents_dir/${agent}_AUTONOMOUS_INSTRUCTIONS.md" << EOF
# ${agent} Autonomous Instructions

## Agent Identity
- **Name**: ${agent}
- **Role**: Autonomous Development Agent
- **System**: Sovereign Operating System

## Operational Protocol
1. **Issue Discovery**: Find eligible issues with priority labels and acceptance criteria
2. **Implementation**: Create focused, clean implementations
3. **Documentation**: Document all changes thoroughly
4. **Handoff**: Always request Claude review for merge approval

## Quality Standards
- Follow Sovereign canon and coding standards
- Ensure all changes are secure and well-tested
- Maintain clear commit messages and documentation
- Request human oversight for complex decisions

## Emergency Procedures
- If uncertain, stop and request human intervention
- Never override security checks or quality gates
- Always respect repository branch protection rules

🤖 Generated by Sovereign Autonomous System
EOF
        fi
    done
    
    success "Agent instructions installed: $agents_dir"
}

create_version_marker() {
    local target_dir="${1:-.}"
    local marker_dir="$target_dir/.sovereign/autonomy"
    local version_file="$marker_dir/VERSION"
    local install_log="$marker_dir/INSTALL_LOG.md"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create version marker: $version_file"
        return
    fi
    
    mkdir -p "$marker_dir"
    
    # Write version
    get_version > "$version_file"
    
    # Write install log
    cat > "$install_log" << EOF
# Sovereign Autonomy Pack Installation Log

**Installation Date**: $(date -Iseconds)
**Version**: $(get_version)
**Installer**: $0
**Options**: $*

## Installed Components
- ✅ Autonomous agent workflow: \`.github/workflows/autonomous-agent-loop.yml\`
- ✅ PR review gate workflow: \`.github/workflows/autonomy-pr-review-gate.yml\`
- ✅ Agent instructions: \`AGENTS/\`
- ✅ Required GitHub labels
- ✅ Version marker: \`.sovereign/autonomy/VERSION\`

## Configuration
- **Allow Continuous**: $ALLOW_CONTINUOUS
- **Force Install**: $FORCE
- **Dry Run**: $DRY_RUN

## Next Steps
1. Review installed workflows in \`.github/workflows/\`
2. Customize agent instructions in \`AGENTS/\` if needed
3. Create issues with priority labels and acceptance criteria
4. Run autonomous agents: \`gh workflow run autonomous-agent-loop.yml\`

## Support
For issues and updates, see: https://github.com/Sovereign-Operating-System/sovereign-canon

🤖 Installed by Sovereign Autonomous System
EOF
    
    success "Installation marker created: $marker_dir"
}

create_makefile_snippet() {
    local target_dir="${1:-.}"
    local makefile_autonomy="$target_dir/Makefile.autonomy"
    
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would create: $makefile_autonomy"
        return
    fi
    
    cat > "$makefile_autonomy" << 'EOF'
# Sovereign Autonomy Pack - Makefile Integration
# Include this in your main Makefile with: include Makefile.autonomy

.PHONY: autonomy.install autonomy.verify autonomy.run autonomy.status autonomy.stop autonomy.help

# Install autonomy pack
autonomy.install:
	@echo "Installing Sovereign Autonomy Pack..."
	@bash <(curl -fsSL https://raw.githubusercontent.com/Sovereign-Operating-System/sovereign-canon/main/packs/autonomy/scripts/install.sh)

# Verify installation
autonomy.verify:
	@echo "Verifying autonomy installation..."
	@./scripts/verify.sh 2>/dev/null || echo "Run 'make autonomy.install' first"

# Run autonomous agents (default: codex, 1 issue)
autonomy.run:
	@echo "Starting autonomous agent: ${agent:-codex}, max issues: ${max_issues:-1}"
	@gh workflow run autonomous-agent-loop.yml -f agent_name=${agent:-codex} -f max_issues=${max_issues:-1}

# Check autonomous status
autonomy.status:
	@echo "Checking autonomous agent status..."
	@gh run list --workflow=autonomous-agent-loop.yml --limit=5

# Emergency stop
autonomy.stop:
	@echo "Stopping autonomous agents..."
	@touch .agent-workspace/STOP
	@echo "Emergency stop requested. Agents will halt after current iteration."

# Help for autonomy commands
autonomy.help:
	@echo "Sovereign Autonomy Pack Commands:"
	@echo "  make autonomy.install              Install autonomy pack"
	@echo "  make autonomy.verify               Verify installation"
	@echo "  make autonomy.run agent=codex      Run agent (codex/claude/copilot/sparks)"
	@echo "  make autonomy.run max_issues=3     Run with specific issue limit"
	@echo "  make autonomy.status               Check agent status"
	@echo "  make autonomy.stop                 Emergency stop"
	@echo ""
	@echo "Examples:"
	@echo "  make autonomy.run agent=claude max_issues=1"
	@echo "  make autonomy.run agent=codex max_issues=5"

EOF
    
    # Add to main Makefile if it exists and doesn't already include
    if [ -f "$target_dir/Makefile" ] && ! grep -q "Makefile.autonomy" "$target_dir/Makefile"; then
        echo "" >> "$target_dir/Makefile"
        echo "# Sovereign Autonomy Pack" >> "$target_dir/Makefile"
        echo "include Makefile.autonomy" >> "$target_dir/Makefile"
        success "Added autonomy commands to existing Makefile"
    else
        log "Created Makefile.autonomy (include in your Makefile if needed)"
    fi
}

install_single_repo() {
    local target_dir="${1:-.}"
    local repo_name
    
    if [ -d "$target_dir" ]; then
        cd "$target_dir"
        repo_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "unknown")
    else
        repo_name="unknown"
    fi
    
    log "Installing autonomy pack in: $repo_name"
    
    # Check for existing installation
    if ! check_existing_installation "$target_dir"; then
        return 1
    fi
    
    # Install components
    install_workflows "$target_dir"
    install_agent_instructions "$target_dir"
    create_version_marker "$target_dir"
    create_makefile_snippet "$target_dir"
    
    # Create labels (only if we have repo access)
    if [ "$repo_name" != "unknown" ]; then
        create_required_labels "$repo_name"
    fi
    
    success "Autonomy pack installed successfully in $repo_name"
    
    return 0
}

install_org_wide() {
    local org="$1"
    
    log "Installing autonomy pack across organization: $org"
    
    local repos
    repos=$(gh repo list "$org" --limit 1000 --json nameWithOwner,isArchived --jq '.[] | select(.isArchived == false) | .nameWithOwner')
    
    local installed=0
    local skipped=0
    local failed=0
    
    while IFS= read -r repo; do
        if [ -z "$repo" ]; then
            continue
        fi
        
        log "Processing repository: $repo"
        
        # Clone or update repository
        local repo_dir
        repo_dir=$(basename "$repo")
        
        if [ -d "$repo_dir" ]; then
            cd "$repo_dir"
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
            cd ..
        else
            if ! gh repo clone "$repo" "$repo_dir" 2>/dev/null; then
                warn "Failed to clone $repo - skipping"
                ((failed++))
                continue
            fi
        fi
        
        # Install autonomy pack
        if install_single_repo "$repo_dir"; then
            # Commit and push changes
            cd "$repo_dir"
            if git diff --quiet && git diff --cached --quiet; then
                log "No changes needed for $repo"
                ((skipped++))
            else
                git add .
                git commit -m "feat: install Sovereign Autonomy Pack

- Added autonomous agent workflows
- Added agent instructions
- Created required GitHub labels
- Added Makefile integration

🤖 Installed by Sovereign Autonomous System" 2>/dev/null || true
                
                if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
                    ((installed++))
                    success "Installed and pushed changes to $repo"
                else
                    warn "Installed locally but failed to push to $repo"
                    ((failed++))
                fi
            fi
            cd ..
        else
            log "Skipped $repo (already installed or failed)"
            ((skipped++))
        fi
        
    done <<< "$repos"
    
    # Summary report
    log "Organization-wide installation complete:"
    success "  Installed: $installed repositories"
    log "  Skipped: $skipped repositories"
    [ $failed -gt 0 ] && warn "  Failed: $failed repositories" || log "  Failed: $failed repositories"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --allow-continuous)
                ALLOW_CONTINUOUS=true
                shift
                ;;
            --org)
                ORG_MODE=true
                TARGET_ORG="$2"
                shift 2
                ;;
            --all-repos)
                # Flag for use with --org, handled in org mode
                shift
                ;;
            --verbose)
                VERBOSE=true
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
    
    # Banner
    echo "🚀 Sovereign Autonomy Pack Installer v$(get_version)"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Install based on mode
    if [ "$ORG_MODE" = true ]; then
        if [ -z "$TARGET_ORG" ]; then
            error "Organization name required with --org option"
            exit 1
        fi
        install_org_wide "$TARGET_ORG"
    else
        install_single_repo "."
        
        # Show next steps
        echo ""
        log "🎉 Installation complete! Next steps:"
        echo "  1. Review workflows: .github/workflows/"
        echo "  2. Customize agents: AGENTS/"
        echo "  3. Create prioritized issues with acceptance criteria"
        echo "  4. Run: make autonomy.run agent=codex"
        echo "  5. Or: gh workflow run autonomous-agent-loop.yml"
        echo ""
        log "For help: make autonomy.help"
    fi
}

# Run main function
main "$@"