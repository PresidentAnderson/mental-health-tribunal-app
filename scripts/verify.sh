#!/bin/bash
set -euo pipefail

# Sovereign Autonomy Pack Verifier
# Version: 1.0.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[VERIFY]${NC} $1"
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

check_prerequisites() {
    local errors=0
    
    log "Checking prerequisites..."
    
    # Check GitHub CLI
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) not found"
        ((errors++))
    else
        success "GitHub CLI found"
        
        # Check authentication
        if ! gh auth status &> /dev/null; then
            error "GitHub CLI not authenticated"
            ((errors++))
        else
            success "GitHub CLI authenticated"
        fi
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        error "Git not found"
        ((errors++))
    else
        success "Git found"
        
        # Check if in git repo
        if ! git rev-parse --is-inside-work-tree &> /dev/null; then
            error "Not in a Git repository"
            ((errors++))
        else
            success "In Git repository"
        fi
    fi
    
    # Check Node.js (optional but recommended)
    if command -v node &> /dev/null; then
        local node_version
        node_version=$(node --version)
        success "Node.js found: $node_version"
    else
        warn "Node.js not found (optional but recommended for some workflows)"
    fi
    
    return $errors
}

check_installation() {
    local errors=0
    
    log "Checking installation..."
    
    # Check version marker
    if [ -f ".sovereign/autonomy/VERSION" ]; then
        local version
        version=$(cat ".sovereign/autonomy/VERSION")
        success "Installation found: v$version"
    else
        error "Installation marker not found: .sovereign/autonomy/VERSION"
        ((errors++))
        return $errors
    fi
    
    # Check workflows
    local workflows_dir=".github/workflows"
    if [ -f "$workflows_dir/autonomous-agent-loop.yml" ]; then
        success "Main workflow found: autonomous-agent-loop.yml"
    else
        error "Main workflow missing: $workflows_dir/autonomous-agent-loop.yml"
        ((errors++))
    fi
    
    if [ -f "$workflows_dir/autonomy-pr-review-gate.yml" ]; then
        success "Review gate found: autonomy-pr-review-gate.yml"
    else
        error "Review gate missing: $workflows_dir/autonomy-pr-review-gate.yml"
        ((errors++))
    fi
    
    # Check agent instructions
    if [ -d "AGENTS" ]; then
        success "AGENTS directory found"
        
        local agents_found=0
        for agent in CODEX CLAUDE COPILOT SPARKS; do
            if [ -f "AGENTS/${agent}_AUTONOMOUS_INSTRUCTIONS.md" ]; then
                success "Agent instructions found: ${agent}"
                ((agents_found++))
            else
                warn "Agent instructions missing: ${agent}_AUTONOMOUS_INSTRUCTIONS.md"
            fi
        done
        
        if [ $agents_found -eq 0 ]; then
            error "No agent instruction files found"
            ((errors++))
        fi
    else
        error "AGENTS directory missing"
        ((errors++))
    fi
    
    # Check Makefile integration
    if [ -f "Makefile.autonomy" ]; then
        success "Makefile integration found"
    else
        warn "Makefile.autonomy not found (may be installed manually)"
    fi
    
    return $errors
}

check_github_labels() {
    local errors=0
    
    log "Checking GitHub labels..."
    
    local repo_name
    repo_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
    
    if [ -z "$repo_name" ]; then
        error "Cannot determine repository name"
        return 1
    fi
    
    local required_labels=(
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
    
    local existing_labels
    existing_labels=$(gh label list --repo "$repo_name" --json name --jq '.[].name' 2>/dev/null || echo "")
    
    for label in "${required_labels[@]}"; do
        if echo "$existing_labels" | grep -q "^$label$"; then
            success "Label found: $label"
        else
            error "Label missing: $label"
            ((errors++))
        fi
    done
    
    return $errors
}

check_permissions() {
    local errors=0
    
    log "Checking repository permissions..."
    
    local repo_name
    repo_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
    
    if [ -z "$repo_name" ]; then
        error "Cannot determine repository name"
        return 1
    fi
    
    # Check if we can create issues
    local test_issue_title="[TEST] Autonomy verification - $(date +%s)"
    if issue_url=$(gh issue create --title "$test_issue_title" --body "Test issue for autonomy verification. Will be closed immediately." --label "priority:low" 2>/dev/null); then
        success "Can create issues"
        
        # Close the test issue
        local issue_num
        issue_num=$(echo "$issue_url" | grep -o '/[0-9]\+$' | cut -d'/' -f2)
        gh issue close "$issue_num" --reason "not planned" &> /dev/null || true
        gh issue delete "$issue_num" --confirm &> /dev/null || true
    else
        error "Cannot create issues (required for autonomy)"
        ((errors++))
    fi
    
    # Check if we can trigger workflows
    if gh workflow list --repo "$repo_name" | grep -q "Autonomous Agent Execution Loop"; then
        success "Autonomous workflow is visible"
    else
        error "Autonomous workflow not found or not accessible"
        ((errors++))
    fi
    
    return $errors
}

check_workflow_syntax() {
    local errors=0
    
    log "Checking workflow syntax..."
    
    # Check main workflow syntax
    if [ -f ".github/workflows/autonomous-agent-loop.yml" ]; then
        if yamllint ".github/workflows/autonomous-agent-loop.yml" &> /dev/null || python3 -c "import yaml; yaml.safe_load(open('.github/workflows/autonomous-agent-loop.yml'))" &> /dev/null; then
            success "Main workflow syntax is valid"
        else
            error "Main workflow has syntax errors"
            ((errors++))
        fi
    fi
    
    # Check review gate syntax
    if [ -f ".github/workflows/autonomy-pr-review-gate.yml" ]; then
        if yamllint ".github/workflows/autonomy-pr-review-gate.yml" &> /dev/null || python3 -c "import yaml; yaml.safe_load(open('.github/workflows/autonomy-pr-review-gate.yml'))" &> /dev/null; then
            success "Review gate workflow syntax is valid"
        else
            error "Review gate workflow has syntax errors"
            ((errors++))
        fi
    fi
    
    return $errors
}

test_issue_discovery() {
    local errors=0
    
    log "Testing issue discovery..."
    
    # Check for eligible issues
    local eligible_issues
    eligible_issues=$(gh issue list --state open --label "priority:" --limit 5 --json number,title,body 2>/dev/null || echo "[]")
    
    local eligible_count
    eligible_count=$(echo "$eligible_issues" | jq '. | length' 2>/dev/null || echo "0")
    
    if [ "$eligible_count" -gt 0 ]; then
        success "Found $eligible_count issues with priority labels"
        
        # Check for acceptance criteria
        local issues_with_criteria=0
        for i in $(seq 0 $((eligible_count - 1))); do
            local issue_body
            issue_body=$(echo "$eligible_issues" | jq -r ".[$i].body" 2>/dev/null || echo "")
            if echo "$issue_body" | grep -q "## Acceptance Criteria"; then
                ((issues_with_criteria++))
            fi
        done
        
        if [ $issues_with_criteria -gt 0 ]; then
            success "Found $issues_with_criteria issues with acceptance criteria"
        else
            warn "No issues with acceptance criteria found"
            warn "Issues should include '## Acceptance Criteria' section for autonomous processing"
        fi
    else
        warn "No issues with priority labels found"
        warn "Create issues with priority:critical, priority:high, priority:medium, or priority:low labels"
    fi
    
    return $errors
}

generate_report() {
    local total_errors="$1"
    
    echo ""
    echo "================================"
    echo "🔍 VERIFICATION REPORT"
    echo "================================"
    
    if [ "$total_errors" -eq 0 ]; then
        success "✅ All checks passed!"
        echo ""
        log "Your Sovereign Autonomy Pack is properly installed and ready to use."
        echo ""
        echo "Next steps:"
        echo "  1. Create issues with priority labels and acceptance criteria"
        echo "  2. Run: make autonomy.run agent=codex"
        echo "  3. Or: gh workflow run autonomous-agent-loop.yml"
        echo ""
    else
        error "❌ Verification failed with $total_errors error(s)"
        echo ""
        log "Please fix the errors above before using autonomy features."
        echo ""
        echo "Common fixes:"
        echo "  • Run the installer: bash <(curl -fsSL URL)"
        echo "  • Check GitHub CLI authentication: gh auth login"
        echo "  • Create required labels: gh label create ..."
        echo "  • Add acceptance criteria to issues"
        echo ""
    fi
}

usage() {
    cat << EOF
Sovereign Autonomy Pack Verifier

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --quick                 Skip permission checks (faster)
    --report-file FILE      Save report to file
    -h, --help              Show this help

EXAMPLES:
    $0                      Full verification
    $0 --quick              Quick verification (skip permissions)
    $0 --report-file report.md

EOF
}

main() {
    local quick=false
    local report_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                quick=true
                shift
                ;;
            --report-file)
                report_file="$2"
                shift 2
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
    
    echo "🔍 Sovereign Autonomy Pack Verifier"
    echo ""
    
    local total_errors=0
    
    # Run checks
    check_prerequisites || total_errors=$((total_errors + $?))
    check_installation || total_errors=$((total_errors + $?))
    check_github_labels || total_errors=$((total_errors + $?))
    
    if [ "$quick" != true ]; then
        check_permissions || total_errors=$((total_errors + $?))
    fi
    
    check_workflow_syntax || total_errors=$((total_errors + $?))
    test_issue_discovery || total_errors=$((total_errors + $?))
    
    # Generate report
    if [ -n "$report_file" ]; then
        generate_report "$total_errors" | tee "$report_file"
        log "Report saved to: $report_file"
    else
        generate_report "$total_errors"
    fi
    
    exit $total_errors
}

main "$@"