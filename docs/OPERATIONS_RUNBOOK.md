# Autonomous Operations Runbook

This runbook provides detailed operational procedures for managing the Sovereign Autonomy Pack in production environments.

## 🎯 Quick Reference

### Emergency Contacts
- **System Owner**: President (Jonathan Mitchell Anderson)
- **Technical Lead**: Claude (AI oversight)
- **Escalation Path**: GitHub Issues → Discussions → Direct Contact

### Critical Commands
```bash
# Emergency stop
touch .agent-workspace/STOP

# System status
make autonomy.status

# Health check
./scripts/verify.sh

# Safe restart
make autonomy.run agent=codex max_issues=1
```

## 📋 Daily Operations

### Morning Startup Checklist

1. **System Health Check**
   ```bash
   # Verify installation integrity
   ./scripts/verify.sh
   
   # Check for overnight activity
   gh run list --workflow=autonomous-agent-loop.yml --limit=10
   
   # Review session summaries
   ls -la AUTONOMOUS_SESSION_*.md | tail -5
   ```

2. **Issue Queue Review**
   ```bash
   # Check eligible issues
   gh issue list --state=open --label="priority:" --limit=10
   
   # Verify acceptance criteria
   gh issue list --state=open --search="Acceptance Criteria" --limit=5
   
   # Review agent workload
   gh pr list --label="agent:handoff" --state=open
   ```

3. **Security Review**
   ```bash
   # Check for security alerts
   gh pr list --label="security:review-required" --state=open
   
   # Review recent commits
   git log --oneline --grep="agent" -10
   
   # Validate token permissions
   gh auth status
   ```

### Evening Shutdown Procedures

1. **Complete Current Work**
   ```bash
   # Check active sessions
   ls -la .agent-workspace/
   
   # Review pending PRs
   gh pr list --author="app/github-actions" --state=open
   
   # Emergency stop if needed
   touch .agent-workspace/STOP
   ```

2. **Daily Summary**
   ```bash
   # Generate activity report
   echo "## Daily Activity Report - $(date +%Y-%m-%d)" > daily_report.md
   echo "### Issues Processed" >> daily_report.md
   git log --oneline --grep="feat(agent)" --since="1 day ago" >> daily_report.md
   
   # Archive session files
   mkdir -p archives/$(date +%Y-%m-%d)
   mv AUTONOMOUS_SESSION_*.md archives/$(date +%Y-%m-%d)/ 2>/dev/null || true
   ```

## 🚨 Incident Response

### Severity Levels

#### SEV-1 (Critical)
- Autonomous agent causing security vulnerabilities
- Infinite loop or resource exhaustion
- Corrupted repository state

**Response Time**: Immediate (< 5 minutes)

**Actions**:
```bash
# 1. Immediate stop
touch .agent-workspace/STOP

# 2. Disable workflow
gh workflow disable autonomous-agent-loop.yml

# 3. Assess damage
git status
gh pr list --author="app/github-actions" --state=open

# 4. Escalate
# Create incident issue with SEV-1 label
gh issue create --title "SEV-1: Autonomous system incident" --body "Details..." --label="incident,sev-1"
```

#### SEV-2 (High)
- Agent creating incorrect implementations
- PR validation failures
- Token permission issues

**Response Time**: 15 minutes

**Actions**:
```bash
# 1. Pause new executions
touch .agent-workspace/STOP

# 2. Review recent activity
gh run list --workflow=autonomous-agent-loop.yml --limit=20

# 3. Check PR queue
gh pr list --label="agent:handoff" --state=open

# 4. Document and fix
./scripts/verify.sh --report-file incident_report.md
```

#### SEV-3 (Medium)
- Individual workflow failures
- Label or permission warnings
- Performance degradation

**Response Time**: 1 hour

**Actions**:
```bash
# 1. Investigate specific failure
gh run view [RUN_ID] --log

# 2. Check system health
./scripts/verify.sh

# 3. Apply fixes as needed
./scripts/sync.sh --dry-run
```

### Recovery Procedures

#### Complete System Recovery
```bash
# 1. Stop all autonomous activity
touch .agent-workspace/STOP
gh workflow disable autonomous-agent-loop.yml

# 2. Backup current state
cp -r .sovereign/autonomy recovery_backup_$(date +%s)
git stash push -m "Recovery backup $(date)"

# 3. Reinstall clean system
./scripts/uninstall.sh --confirm
./scripts/install.sh --force

# 4. Verify installation
./scripts/verify.sh

# 5. Gradual restart
make autonomy.run agent=codex max_issues=1
```

#### Partial Recovery (Workflow Issues)
```bash
# 1. Update workflows only
./scripts/sync.sh --force --backup

# 2. Verify syntax
./scripts/verify.sh --quick

# 3. Test with single issue
gh workflow run autonomous-agent-loop.yml -f agent_name=codex -f max_issues=1
```

## 🔍 Monitoring & Alerting

### Key Metrics to Track

1. **Processing Metrics**
   - Issues processed per day
   - Agent success rates
   - Time per issue
   - PR merge rates

2. **Quality Metrics**
   - Security scan failures
   - PR rejection rates
   - Manual intervention frequency
   - Code quality scores

3. **System Health**
   - Workflow failure rates
   - Token expiration alerts
   - Repository access issues
   - Label management status

### Setting Up Alerts

#### GitHub Notifications
```bash
# Enable workflow failure notifications
gh api user/emails --method POST --field email=alerts@yourdomain.com

# Set up issue notifications
gh api repos/{owner}/{repo}/subscription --method PUT --field subscribed=true
```

#### Custom Monitoring Script
```bash
#!/bin/bash
# monitor_autonomy.sh - Run hourly via cron

FAILURES=$(gh run list --workflow=autonomous-agent-loop.yml --status=failure --limit=1 --json conclusion | jq length)
if [ "$FAILURES" -gt 0 ]; then
    echo "Alert: Autonomy workflow failure detected"
    gh issue create --title "Monitoring Alert: Workflow Failure" --body "Automated monitoring detected workflow failures" --label="alert,operations"
fi
```

## 🔧 Maintenance Procedures

### Weekly Maintenance

1. **Update Sync**
   ```bash
   # Check for pack updates
   ./scripts/sync.sh --dry-run
   
   # Apply if needed
   ./scripts/sync.sh --backup
   ```

2. **Label Audit**
   ```bash
   # Check required labels
   gh label list | grep -E "(priority:|status:|agent:|review:|security:)"
   
   # Recreate if missing
   ./scripts/install.sh --force
   ```

3. **Performance Review**
   ```bash
   # Check workflow run times
   gh run list --workflow=autonomous-agent-loop.yml --limit=50 --json durationMs
   
   # Review error patterns
   grep -r "error\|fail" archives/*/AUTONOMOUS_SESSION_*.md || true
   ```

### Monthly Maintenance

1. **Security Audit**
   - Review all autonomous PRs from past month
   - Check for credential exposure
   - Update token permissions if needed
   - Review security scan effectiveness

2. **Capacity Planning**
   - Analyze issue processing volume
   - Review agent performance
   - Plan scaling if needed
   - Update default limits if appropriate

3. **Documentation Updates**
   - Update runbook based on incidents
   - Review agent instructions
   - Update troubleshooting guides
   - Archive old session data

### Quarterly Maintenance

1. **System Refresh**
   ```bash
   # Full system verification
   ./scripts/verify.sh --report-file quarterly_health.md
   
   # Update to latest version
   ./scripts/sync.sh --force --backup
   
   # Performance optimization
   git gc --aggressive
   ```

2. **Policy Review**
   - Review max issue limits
   - Update security policies
   - Assess agent effectiveness
   - Plan capability improvements

## 📊 Performance Optimization

### Workflow Performance

#### Common Issues
1. **Slow Issue Discovery**
   - Optimize label queries
   - Reduce API calls
   - Cache issue lists

2. **Large Repository Problems**
   - Use shallow clones
   - Implement incremental processing
   - Optimize dependency installation

3. **Token Rate Limiting**
   - Implement exponential backoff
   - Use multiple tokens if allowed
   - Optimize API usage patterns

#### Optimization Techniques
```bash
# Profile workflow performance
gh run list --workflow=autonomous-agent-loop.yml --json durationMs,conclusion | jq '.[] | select(.conclusion=="success") | .durationMs' | awk '{sum+=$1; count++} END {print "Average:", sum/count, "ms"}'

# Identify bottlenecks
gh run view [RUN_ID] --log | grep "seconds\|minutes"

# Test optimizations
gh workflow run autonomous-agent-loop.yml -f agent_name=codex -f max_issues=1
```

### Resource Management

#### Disk Space
```bash
# Clean up old sessions
find . -name "AUTONOMOUS_SESSION_*.md" -mtime +30 -delete

# Archive large files
tar czf archives/sessions_$(date +%Y%m).tar.gz AUTONOMOUS_SESSION_*.md
rm AUTONOMOUS_SESSION_*.md

# Clean git repository
git reflog expire --all --expire=now
git gc --prune=now --aggressive
```

#### Memory Usage
- Monitor workflow memory consumption
- Optimize agent instruction processing
- Implement session data cleanup
- Use streaming for large operations

## 🔐 Security Operations

### Daily Security Checks

```bash
# Check for exposed secrets
git log --grep="token\|key\|password" --oneline -10

# Review security scan results
gh pr list --label="security:review-required" --state=all --limit=10

# Validate token permissions
gh api user | jq '.permissions'
```

### Token Management

#### Rotation Schedule
- **Personal Access Tokens**: Every 90 days
- **GitHub Apps**: Annual review
- **Secret Updates**: Immediate after rotation

#### Rotation Process
```bash
# 1. Generate new token
echo "Generate new token with required permissions:"
echo "- Contents: write"
echo "- Issues: write"  
echo "- Pull requests: write"

# 2. Test new token
GITHUB_TOKEN=new_token gh auth status

# 3. Update repository secrets
gh secret set GITHUB_TOKEN --body "new_token"

# 4. Verify functionality
./scripts/verify.sh

# 5. Revoke old token
echo "Revoke old token from GitHub settings"
```

### Incident Documentation

#### Required Information
- Timestamp and duration
- Affected repositories/workflows
- Impact assessment
- Root cause analysis
- Remediation actions
- Prevention measures

#### Template
```markdown
# Incident Report: [ID] - [Title]

## Summary
Brief description of the incident

## Timeline
- HH:MM - Detection
- HH:MM - Initial response
- HH:MM - Resolution

## Impact
- Affected systems
- User impact
- Data integrity

## Root Cause
Technical details of the failure

## Resolution
Steps taken to resolve

## Prevention
Measures to prevent recurrence
```

## 🔄 Scaling Operations

### Single Repository → Multiple Repositories

1. **Preparation**
   ```bash
   # Test installation on staging repository
   ./scripts/install.sh --dry-run
   
   # Verify organization permissions
   gh org view Sovereign-Operating-System
   ```

2. **Deployment**
   ```bash
   # Deploy across organization
   ./scripts/install.sh --org Sovereign-Operating-System --all-repos
   
   # Monitor deployment
   # Review logs from each repository
   ```

3. **Validation**
   ```bash
   # Check all installations
   for repo in $(gh repo list Sovereign-Operating-System --json nameWithOwner --jq '.[].nameWithOwner'); do
       echo "Checking $repo..."
       gh workflow list --repo "$repo" | grep "Autonomous Agent"
   done
   ```

### Multiple Repositories → Enterprise Scale

1. **Centralized Monitoring**
   - Implement organization-wide dashboards
   - Aggregate metrics across repositories
   - Create centralized alerting

2. **Policy Enforcement**
   - Standardize configurations
   - Enforce security policies
   - Manage token distribution

3. **Coordination**
   - Prevent resource conflicts
   - Coordinate major updates
   - Manage emergency procedures

---

**Remember**: This runbook is a living document. Update it based on operational experience and incidents encountered in production.

🤖 **Sovereign Autonomy Operations** - Ensuring reliable, secure, and efficient autonomous development at scale.