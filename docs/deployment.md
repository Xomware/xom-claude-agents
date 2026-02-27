# Agent Deployment Guide

This guide covers deploying agents to production environments.

## Deployment Checklist

Before deploying any agent:

- [ ] System prompt reviewed and approved
- [ ] All tools tested and working
- [ ] Quality gates configured
- [ ] Rate limits set appropriately
- [ ] Monitoring configured
- [ ] Logs being collected
- [ ] Rollback plan documented
- [ ] Team trained
- [ ] Documentation updated

## Local Development

### 1. Set Up Your Environment

```bash
# Clone the repository
git clone https://github.com/Xomware/xom-claude-agents.git
cd xom-claude-agents

# Install dependencies (if using a wrapper)
pip install -r requirements.txt  # Python
npm install                       # Node.js
```

### 2. Create Your Agent

```bash
# Copy a template
cp templates/base-agent.yaml my-agent.yaml
mkdir my-agent-prompts
cp templates/prompts/system.md my-agent-prompts/

# Edit your agent config
nano my-agent.yaml
nano my-agent-prompts/system.md
```

### 3. Test Locally

```bash
# Test your agent
python test_agent.py my-agent.yaml

# Expected output:
# ✓ Config loaded
# ✓ System prompt valid
# ✓ Tools defined
# ✓ Quality gates configured
```

## Staging Deployment

### 1. Prepare for Staging

```bash
# Create staging config
cp my-agent.yaml my-agent.staging.yaml

# Update staging config
# - Point to staging endpoints
# - Use staging API keys
# - Enable debug logging
# - Lower rate limits for testing
```

### 2. Deploy to Staging

```bash
# Deploy
./scripts/deploy.sh my-agent.staging.yaml staging

# Verify
./scripts/verify.sh my-agent.staging.yaml staging
```

### 3. Test in Staging

```bash
# Run integration tests
python -m pytest tests/integration/staging/

# Expected:
# - All tests pass
# - Latency acceptable
# - No errors in logs
```

### 4. Load Test

```bash
# Run load test
./scripts/load-test.sh my-agent.staging.yaml --requests 100 --duration 5m

# Check:
# - Response times < SLA
# - Error rate < 1%
# - Resource usage acceptable
```

## Production Deployment

### 1. Pre-Production Review

```bash
# Final review checklist
./scripts/pre-deploy-check.sh my-agent.yaml

# Verification items:
✓ No hardcoded secrets
✓ Rate limits configured
✓ Monitoring enabled
✓ Rollback plan documented
✓ On-call rotation assigned
```

### 2. Approval Process

Get approval from:
- [ ] Engineering lead (code quality)
- [ ] Security team (safety/permissions)
- [ ] Operations (monitoring/runbooks)

### 3. Deploy to Production

```bash
# Deploy (canary: 5% traffic)
./scripts/deploy.sh my-agent.yaml production --canary 5

# Monitor
./scripts/monitor.sh my-agent.yaml

# If successful, increase to 50%
./scripts/deploy.sh my-agent.yaml production --canary 50

# If still successful, go to 100%
./scripts/deploy.sh my-agent.yaml production --canary 100
```

### 4. Post-Deployment Validation

```bash
# Run smoke tests
./scripts/smoke-test.sh my-agent.yaml production

# Monitor for 24 hours
# - Error rate
# - Latency
# - Resource usage
# - User feedback
```

## Configuration Management

### Environment-Specific Configs

Maintain separate configs for each environment:

```
my-agent.yaml              # Development
my-agent.staging.yaml      # Staging
my-agent.production.yaml   # Production
```

Key differences:

```yaml
# Development
model:
  temperature: 0.7
  max_tokens: 1000

# Production
model:
  temperature: 0.3
  max_tokens: 1000
```

### Secrets Management

Never hardcode secrets:

```bash
# Use environment variables
export CLAUDE_API_KEY="sk-..."
export DB_URL="postgres://..."

# Or use a secrets manager
# - AWS Secrets Manager
# - HashiCorp Vault
# - 1Password

# Reference in config
api_key: "${CLAUDE_API_KEY}"
```

## Monitoring & Observability

### Logging

Collect logs from all agents:

```bash
# Example: CloudWatch
aws logs create-log-group --log-group-name /agents/my-agent

# Log important events:
# - Agent initialization
# - Tool usage
# - Errors and failures
# - Performance metrics
```

### Metrics

Track key metrics:

```
- Request count (per minute)
- Response latency (p50, p95, p99)
- Error rate (5xx, 4xx errors)
- Token usage (per request, per day)
- Cost (per request, per day)
```

### Alerting

Set up alerts for:

```
- Error rate > 1%
- Latency p99 > SLA
- Disk/memory > 80%
- Agent response timeout
- Unexpected token usage
```

Example alert:

```yaml
alert: "HighErrorRate"
condition: error_rate > 0.01
for: 5 minutes
action: page_oncall
severity: critical
```

### Dashboards

Create dashboards for:

- Agent status (up/down)
- Request volume
- Latency distribution
- Error breakdown
- Resource usage
- Cost trends

## Scaling

### Horizontal Scaling

Run multiple instances:

```bash
# Deploy 3 instances
./scripts/deploy.sh my-agent.yaml production --replicas 3

# Load balancer distributes requests
# Instances can be independently updated
```

### Vertical Scaling

Increase per-instance resources:

```yaml
performance:
  max_concurrent_requests: 20  # Was 10
```

Then redeploy.

### Autoscaling

Automatically scale based on load:

```yaml
autoscaling:
  enabled: true
  min_replicas: 2
  max_replicas: 10
  target_cpu: 70%
  scale_up_threshold: 80%
  scale_down_threshold: 30%
```

## Updates & Rollouts

### Zero-Downtime Updates

Use rolling deployment:

```bash
# Update 1 instance at a time
./scripts/deploy.sh my-agent.yaml production --strategy rolling

# 1. Update instance 1 (instances 2-3 handle traffic)
# 2. Verify instance 1 healthy
# 3. Update instance 2 (instances 1,3 handle traffic)
# 4. Verify instance 2 healthy
# 5. Update instance 3
```

### Gradual Rollout

Use canary deployment:

```bash
# Send 5% of traffic to new version
./scripts/deploy.sh my-agent.yaml production --canary 5

# Monitor for issues
# If successful:
./scripts/deploy.sh my-agent.yaml production --canary 50
./scripts/deploy.sh my-agent.yaml production --canary 100
```

### Versioning

Tag releases:

```bash
# Semantic versioning
git tag v1.0.0
git tag v1.1.0  # Minor update
git tag v2.0.0  # Major update

# Keep old versions available for rollback
```

## Rollback Procedures

### Automatic Rollback

Rollback if metrics exceed thresholds:

```yaml
rollback_triggers:
  - error_rate > 5%
  - latency_p99 > 5000ms
  - deployment_failed: true
```

### Manual Rollback

```bash
# Rollback to previous version
./scripts/rollback.sh my-agent.yaml production

# Or to specific version
./scripts/rollback.sh my-agent.yaml production --version v1.0.0

# Verify
./scripts/verify.sh my-agent.yaml production
```

### Rollback Testing

Test rollbacks regularly:

```bash
# Do a practice rollback
./scripts/deploy.sh my-agent.yaml staging --version new
# ... test ...
./scripts/rollback.sh my-agent.yaml staging
# Verify rollback worked
```

## Disaster Recovery

### Backup Strategy

Back up agent configs:

```bash
# Backup to S3
aws s3 cp my-agent.yaml s3://my-bucket/agents/my-agent.yaml
aws s3 cp my-agent-prompts/ s3://my-bucket/agents/my-agent-prompts/ --recursive
```

### Recovery Procedure

```bash
# Restore from backup
aws s3 cp s3://my-bucket/agents/my-agent.yaml my-agent.yaml
aws s3 cp s3://my-bucket/agents/my-agent-prompts/ my-agent-prompts/ --recursive

# Redeploy
./scripts/deploy.sh my-agent.yaml production
```

## Compliance & Auditing

### Audit Logging

Log all deployments:

```yaml
audit_log:
  - timestamp: 2024-02-27T10:30:00Z
    action: "deploy"
    agent: "my-agent"
    version: "1.2.3"
    environment: "production"
    deployed_by: "engineer@company.com"
    approved_by: "lead@company.com"
    status: "success"
```

### Compliance Checks

Before deployment:

```bash
# Security scan
./scripts/security-scan.sh my-agent.yaml

# Privacy check (no PII in logs?)
./scripts/privacy-check.sh my-agent.yaml

# Performance baseline
./scripts/performance-baseline.sh my-agent.yaml
```

## Troubleshooting

### Agent Crashes

```bash
# Check logs
docker logs agent-container

# Common causes:
# - Out of memory → Increase memory
# - API key expired → Rotate keys
# - Config invalid → Validate config
# - Tool unavailable → Check dependencies
```

### High Latency

```bash
# Check metrics
./scripts/check-latency.sh my-agent.yaml

# Possible causes:
# - High load → Scale up
# - Slow tool → Optimize tool
# - Model slow → Check API status
# - Network issue → Check connectivity
```

### High Costs

```bash
# Check token usage
./scripts/check-costs.sh my-agent.yaml

# Reduce token usage:
# - Shorter prompts
# - Smaller max_tokens
# - Cache responses
# - Use Haiku instead of Sonnet
```

## Best Practices

1. **Test in Staging First** — Never deploy untested to production
2. **Canary Deployments** — Roll out gradually, catch issues early
3. **Automated Rollbacks** — Trigger rollback automatically if metrics bad
4. **Monitor Everything** — Can't manage what you can't see
5. **Document Runbooks** — Know how to respond to incidents
6. **Practice Disasters** — Test rollbacks and recovery procedures
7. **Keep Versions** — Keep old versions for quick rollbacks
8. **Communicate** — Notify teams of deployments
9. **Automate** — Automate everything, including rollbacks
10. **Review Changes** — Have someone review every deployment

## Deployment Checklist

```yaml
Pre-Deployment:
  ✓ Code reviewed
  ✓ Tests passing
  ✓ Staging verified
  ✓ Security scanned
  ✓ Monitoring configured
  ✓ On-call assigned
  ✓ Runbooks documented
  ✓ Rollback plan ready

Deployment:
  ✓ Canary started (5%)
  ✓ Monitoring active
  ✓ No errors detected
  ✓ Canary increased (50%)
  ✓ Still no errors
  ✓ Canary to 100%
  ✓ Final verification
  ✓ Announce deployment

Post-Deployment:
  ✓ Monitor for 24 hours
  ✓ Collect feedback
  ✓ Update status page
  ✓ Close related issues
  ✓ Log lessons learned
```

---

**Deploy with confidence. Monitor with vigilance. Rollback with speed.**
