# Sovereign Autonomy Pack

The Sovereign Autonomy Pack transforms any GitHub repository into an autonomous development environment where AI agents can discover, process, and implement solutions for prioritized issues with full oversight and quality controls.

## 🚀 Overview

This pack provides a complete autonomous development workflow that:

- **Discovers eligible issues** based on priority labels and acceptance criteria
- **Executes implementations** through specialized AI agents (Codex, Claude, Copilot, Sparks)
- **Creates pull requests** with proper documentation and handoff protocols
- **Enforces quality gates** through automated validation and security scanning
- **Requires human oversight** via Claude review before any merge

## 📦 What's Included

### Core Workflows
- **`autonomous-agent-loop.yml`** - Main autonomous execution workflow
- **`autonomy-pr-review-gate.yml`** - PR validation and security scanning

### Management Scripts
- **`install.sh`** - One-command installation for any repository
- **`uninstall.sh`** - Clean removal with preservation options
- **`verify.sh`** - Installation verification and health checks
- **`sync.sh`** - Update existing installations to latest version

### Agent Instructions
- Complete autonomous instructions for all supported agents
- Sovereign canon compliance guidelines
- Quality standards and emergency procedures

### Integration Tools
- Makefile integration for easy operation
- GitHub label creation and management
- Version tracking and installation markers

## 🔧 Installation

### Single Repository

```bash
# Quick install (recommended)
bash <(curl -fsSL https://raw.githubusercontent.com/Sovereign-Operating-System/sovereign-canon/main/packs/autonomy/scripts/install.sh)

# Or clone and install
git clone https://github.com/Sovereign-Operating-System/sovereign-canon.git
cd sovereign-canon/packs/autonomy/scripts
./install.sh
```

### Organization-Wide Deployment

```bash
# Install across all repositories in an organization
./install.sh --org Sovereign-Operating-System --all-repos
```

### Installation Options

```bash
./install.sh --help                    # Show all options
./install.sh --dry-run                 # Preview installation
./install.sh --force                   # Force reinstall
./install.sh --allow-continuous        # Enable 24/7 mode
```

## 🎯 Operation

### Quick Start Commands

```bash
# Using Makefile integration (if installed)
make autonomy.run agent=codex          # Process 1 issue with Codex
make autonomy.run agent=claude max_issues=3  # Process 3 issues with Claude
make autonomy.status                   # Check agent status
make autonomy.stop                     # Emergency stop

# Using GitHub CLI directly
gh workflow run autonomous-agent-loop.yml -f agent_name=codex -f max_issues=1
gh workflow run autonomous-agent-loop.yml -f agent_name=sparks -f max_issues=5
```

### Supported Agents

| Agent | Strengths | Best For |
|-------|-----------|----------|
| **Codex** | General purpose, reliable | Feature implementations, bug fixes |
| **Claude** | Strategic thinking, documentation | Architecture decisions, complex problems |
| **Copilot** | Code-focused, patterns | Code refactoring, optimizations |
| **Sparks** | Innovation, experimentation | New features, creative solutions |

## 📋 Prerequisites

### Issue Eligibility Requirements

For an issue to be processed by autonomous agents, it must:

1. **Be open** (not closed or draft)
2. **Have a priority label** (`priority:critical`, `priority:high`, `priority:medium`, or `priority:low`)
3. **Include acceptance criteria** (section with `## Acceptance Criteria`)
4. **Be accessible** to the GitHub token used by the workflow

### Repository Requirements

- GitHub repository with Actions enabled
- GitHub CLI authenticated with appropriate permissions
- Required labels created (automatic during installation)
- Agent instruction files in `AGENTS/` directory

### Security Requirements

- Fine-grained personal access token or GitHub App with:
  - Contents: write
  - Issues: write
  - Pull requests: write
- No hardcoded secrets in autonomous workflows
- Security scanning enabled for all agent PRs

## 🛡️ Security Model

### Safety Controls

1. **Max Issue Limits**: Default maximum of 1 issue processed per run
2. **Continuous Mode Protection**: Requires explicit `--allow-continuous` flag for unlimited processing
3. **Eligibility Filtering**: Only processes issues with proper priority labels and acceptance criteria
4. **Emergency Stop**: Touch `.agent-workspace/STOP` to halt autonomous execution
5. **Human Oversight**: All PRs require Claude review before merge

### Security Scanning

Every autonomous PR undergoes:
- Hardcoded credential detection
- Dangerous command scanning
- External network call validation
- Manual security review flagging when needed

### Access Controls

- Autonomous workflows run with minimal required permissions
- No direct write access to main branch (PRs only)
- All changes subject to branch protection rules
- Audit trail maintained in `.sovereign/autonomy/` directory

## 🔄 Workflow Process

### 1. Issue Discovery
```
Priority: Critical → High → Medium → Low
Filter: Open + Priority Label + Acceptance Criteria
Result: Single eligible issue selected for processing
```

### 2. Agent Processing
```
Branch Creation: agent/{agent_name}/{issue_number}-{slug}
Implementation: Following agent-specific instructions
Documentation: Comprehensive implementation notes
Commit: Signed with agent attribution
```

### 3. PR Creation
```
Title: feat(agent): implement issue #{number}
Body: Summary + Changes + Agent Handoff Protocol
Labels: agent:handoff, review:claude-required
Validation: Automated PR gate checks
```

### 4. Review & Merge
```
Security Scan: Automated vulnerability detection
Claude Review: Human oversight and approval
Merge: Squash commit with proper attribution
Cleanup: Issue closure and label updates
```

## 🔍 Monitoring & Operations

### Health Checks

```bash
# Verify installation
./scripts/verify.sh

# Check recent activity
gh run list --workflow=autonomous-agent-loop.yml --limit=10

# Monitor active sessions
ls -la .agent-workspace/

# Review session summaries
ls -la AUTONOMOUS_SESSION_*.md
```

### Troubleshooting

#### No Issues Being Processed
- Ensure issues have priority labels
- Verify acceptance criteria sections exist
- Check GitHub CLI authentication
- Review agent instruction files

#### Workflow Failures
- Check GitHub token permissions
- Verify repository access rights
- Review workflow syntax with `./scripts/verify.sh`
- Check for missing required labels

#### Security Alerts
- Review flagged PRs manually
- Check for hardcoded secrets
- Validate external network calls
- Update security scanning rules if needed

## 📊 Metrics & Reporting

### Session Tracking
- Issues processed per session
- Agent performance metrics
- Error rates and failure modes
- Processing time and efficiency

### Quality Metrics
- PR approval rates
- Security scan results
- Human intervention frequency
- Code quality scores

## 🔄 Updates & Maintenance

### Keeping Current

```bash
# Check for updates
./scripts/sync.sh --dry-run

# Apply updates (preserves config)
./scripts/sync.sh

# Force update (overwrites config)
./scripts/sync.sh --force --backup
```

### Configuration Management

- Local customizations preserved during updates
- Agent instructions can be modified per repository
- Workflow parameters adjustable via defaults file
- Emergency procedures available in all configurations

## 🚨 Emergency Procedures

### Immediate Stop
```bash
# Stop all autonomous processing
touch .agent-workspace/STOP

# Or use Makefile
make autonomy.stop
```

### Full Removal
```bash
# Complete uninstallation
./scripts/uninstall.sh --confirm

# With preservation of some components
./scripts/uninstall.sh --confirm --preserve-labels --preserve-agents
```

## 📚 Advanced Configuration

### Custom Agent Instructions

Modify files in `AGENTS/` directory to customize agent behavior:
- `CODEX_AUTONOMOUS_INSTRUCTIONS.md`
- `CLAUDE_AUTONOMOUS_INSTRUCTIONS.md`
- `COPILOT_AUTONOMOUS_INSTRUCTIONS.md`
- `SPARKS_AUTONOMOUS_INSTRUCTIONS.md`

### Workflow Customization

Edit `.github/workflows/autonomous-agent-loop.yml` to adjust:
- Default issue limits
- Agent selection logic
- Processing timeouts
- Notification preferences

### Organization Policies

Create `autonomy.defaults.yml` to set organization-wide defaults:
```yaml
max_issues_default: 1
allow_continuous: false
required_labels: ["priority:"]
security_scanning: true
claude_review_required: true
```

## 📞 Support

For issues, updates, and contributions:

- **Repository**: https://github.com/Sovereign-Operating-System/sovereign-canon
- **Issues**: Create issues with `autonomy-pack` label
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Report security issues privately

---

🤖 **Sovereign Autonomy Pack** - Transforming repositories into autonomous development environments while maintaining human oversight and quality standards.