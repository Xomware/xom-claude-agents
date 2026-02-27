# Agent Customization Guide

This guide covers how to customize existing agents and patterns for your specific needs.

## Customizing the Dispatcher

The dispatcher is designed to be minimal and fast. Customize it for your specific workflow.

### Change the Model

Want even faster responses? Switch to Haiku:

```yaml
model:
  name: "claude-3-5-haiku-latest"
  max_tokens: 300  # Even more concise

performance:
  latency_sla_ms: 500  # Tighter SLA
```

### Add Custom Tools

Extend the dispatcher with domain-specific tools:

```yaml
tools:
  - name: "spawn_subagent"
    enabled: true
  - name: "respond_immediate"
    enabled: true
  - name: "your_custom_tool"
    enabled: true
```

### Change Response Style

Customize personality:

```yaml
behavior:
  style: "concise"           # Keep it short
  tone: "friendly"           # Add personality
  max_reasoning_length: 50   # Minimal thinking
  emoji_optional: true       # Add emojis if needed
```

### Example: Slack Dispatcher

```yaml
metadata:
  name: "slack-dispatcher"
  description: "Fast dispatcher for Slack requests"

model:
  name: "claude-3-5-haiku-latest"
  max_tokens: 300
  temperature: 0.2

tools:
  - spawn_subagent
  - respond_immediate
  - query_memory
  - add_to_channel
  - set_reaction

behavior:
  style: "concise"
  tone: "friendly"
```

---

## Customizing Specialists

Specialists are more flexible. Adapt them to your domain.

### Template Customization

Start with the specialist template:

```bash
cp templates/specialist-agent.yaml my-specialist.yaml
```

Edit `my-specialist.yaml`:

```yaml
metadata:
  name: "my-specialist"
  description: "My domain expert"

expertise:
  domain: "Your Domain"
  specialties:
    - "Your specialty 1"
    - "Your specialty 2"

tools:
  - "your_tool_1"
  - "your_tool_2"
```

### Add Domain-Specific Tools

Create a `tools.yaml` for your specialist:

```yaml
tools:
  analyze_domain_data:
    description: "Analyze data in your domain"
    input_schema:
      type: "object"
      properties:
        data:
          type: "object"
    permissions:
      - "read_data"
  
  suggest_solutions:
    description: "Suggest solutions in your domain"
    permissions:
      - "knowledge_base_access"
```

### Adjust Model Size

Based on complexity:

```yaml
model:
  name: "claude-3-5-sonnet-latest"  # Balanced (recommended)
         "claude-3-5-haiku-latest"  # Simpler domains
         "claude-3-opus-latest"     # Complex reasoning
  
  temperature: 0.2  # More consistent
              0.5   # Balanced
              0.8   # More creative
```

### Add Quality Gates

Ensure output quality:

```yaml
quality_gates:
  - type: "domain_validation"
    enabled: true
    rules:
      - "output_uses_correct_terminology"
      - "suggestions_are_actionable"
  
  - type: "accuracy_check"
    enabled: true
    min_confidence: 0.8
```

### Example: Legal Research Agent

```yaml
metadata:
  name: "legal-research-agent"
  description: "Legal research and document specialist"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.2  # Consistent, accurate

expertise:
  domain: "Legal Research"
  specialties:
    - "Contract analysis"
    - "Case law research"
    - "Legal writing"
    - "Regulatory compliance"

tools:
  - query_legal_databases
  - search_case_law
  - analyze_contracts
  - check_compliance
  - generate_legal_memo

quality_gates:
  - type: "legal_accuracy"
    enabled: true
  - type: "citation_check"
    enabled: true
  - type: "compliance_check"
    enabled: true

behavior:
  style: "detailed"
  tone: "professional"
  cite_sources: true
  explain_reasoning: true
```

---

## Customizing the Orchestrator

The orchestrator manages complex workflows. Customize it for your specific processes.

### Define Workflow Templates

Add your workflows:

```yaml
workflow_patterns:
  - name: "your_workflow"
    steps: 5
    gates: ["step1", "step2"]
  
  - name: "another_workflow"
    steps: 8
    gates: ["quality", "approval"]
```

### Add State Management

Configure persistence:

```yaml
state_management:
  enabled: true
  backend: "in_memory"  # or redis, postgres
  retention_days: 30
  auto_checkpoint: true
```

### Define Quality Gates

Enforce standards:

```yaml
quality_gates:
  - type: "custom_validation"
    enabled: true
    criteria:
      - "your_criterion_1"
      - "your_criterion_2"
  
  - type: "approval_gate"
    enabled: true
    required_for: ["production"]
    approvers: ["your_team"]
```

### Example: Feature Release Workflow

```yaml
metadata:
  name: "feature-release-orchestrator"

workflow_patterns:
  - name: "feature_release"
    steps: 8
    gates: ["code_review", "testing", "approval", "deployment"]

quality_gates:
  - type: "code_quality"
    criteria: ["lint", "tests", "coverage>80%"]
  
  - type: "security_scan"
    fail_on: ["critical", "high"]
  
  - type: "approval_gate"
    required_for: ["production_deploy"]
    approvers: ["lead", "security"]
  
  - type: "monitoring"
    required_for: ["production_deploy"]
    metrics: ["error_rate", "latency", "cpu"]

behavior:
  provide_rollback_plan: true
  estimate_downtime: true
  require_confirmation: true
```

---

## Customizing Tools

Tools are how agents interact with systems. Adapt them to your infrastructure.

### Add a New Tool

Define in `tools.yaml`:

```yaml
your_tool_name:
  description: "What your tool does"
  category: "action"
  
  input_schema:
    type: "object"
    properties:
      param1:
        type: "string"
        description: "Parameter 1"
    required: ["param1"]
  
  output_schema:
    type: "object"
    properties:
      success:
        type: "boolean"
      result:
        type: "string"
  
  permissions:
    - "your_permission"
  
  rate_limit: "10/minute"
  timeout_ms: 5000
```

Then reference in agent config:

```yaml
tools:
  - name: "your_tool_name"
    enabled: true
```

### Tool Groups

Organize related tools:

```yaml
tool_groups:
  basic:
    description: "Essential tools"
    tools:
      - tool1
      - tool2
  
  advanced:
    description: "Advanced features"
    tools:
      - tool3
      - tool4
```

Enable specific groups:

```yaml
# Enable basic tools only
tool_group: "basic"

# Or enable specific tools
tools:
  - tool1
  - tool2
```

### Example: AWS Integration Tools

```yaml
tools:
  launch_ec2_instance:
    description: "Launch an EC2 instance"
    input_schema:
      type: "object"
      properties:
        instance_type:
          type: "string"
          enum: ["t3.micro", "t3.small", "t3.medium"]
        instance_count:
          type: "integer"
          minimum: 1
          maximum: 10
    permissions:
      - "ec2:RunInstances"
    cost:
      dollars: "0.01 per instance per hour"
    timeout_ms: 30000
  
  scale_auto_group:
    description: "Scale an Auto Scaling Group"
    input_schema:
      type: "object"
      properties:
        asg_name:
          type: "string"
        desired_capacity:
          type: "integer"
          minimum: 1
          maximum: 100
    permissions:
      - "autoscaling:SetDesiredCapacity"
    timeout_ms: 10000
```

---

## Behavior Customization

Fine-tune agent personality and responses.

### Style

- **concise** — Brief, to the point
- **detailed** — Thorough, comprehensive
- **balanced** — Somewhere in between

```yaml
behavior:
  style: "detailed"  # More explanation
```

### Tone

- **professional** — Business-like
- **friendly** — Warm, approachable
- **technical** — Details and jargon

```yaml
behavior:
  tone: "friendly"  # More personable
```

### Reasoning

Control how much Claude thinks:

```yaml
behavior:
  explain_reasoning: true    # Always explain
  max_reasoning_length: 500  # Limit thinking
```

### Alternatives

Show multiple solutions:

```yaml
behavior:
  provide_alternatives: true
  max_alternatives: 3
```

---

## Performance Tuning

### Latency SLA

Target response time:

```yaml
performance:
  latency_sla_ms: 1000      # For fast responses
  latency_sla_ms: 30000     # For normal responses
  latency_sla_ms: null      # For async tasks
```

### Concurrency

Limit concurrent requests:

```yaml
performance:
  max_concurrent_requests: 10  # Adjust based on capacity
```

### Timeouts

Hard deadline for execution:

```yaml
performance:
  timeout_ms: 5000           # Fast timeout
  timeout_ms: 60000          # Normal timeout
  timeout_ms: 600000         # Long timeout (10 min)
```

### Cost Control

Limit token usage:

```yaml
constraints:
  max_tokens_per_request: 1000
  
  rate_limit:
    requests_per_minute: 30
    requests_per_hour: 500
    requests_per_day: 5000
```

---

## Safety Customization

### Content Filters

Block certain types of content:

```yaml
constraints:
  content_filters:
    - "pii"              # Personal identifiable information
    - "hardcoded_secrets"
    - "malicious_code"
    - "sensitive_data"
```

### Approval Gates

Require approval for critical actions:

```yaml
constraints:
  requires_approval_for:
    - "production_changes"
    - "database_modifications"
    - "access_grant"
```

### Permission Checks

Verify permissions before allowing actions:

```yaml
quality_gates:
  - type: "permission_check"
    enabled: true
    required_for: ["sensitive_operations"]
```

---

## Monitoring & Logging

### Add Instrumentation

Log key events:

```yaml
tools:
  - name: "log_agent_action"
    enabled: true

behavior:
  enable_step_logging: true
  enable_state_visualization: true
```

### Metrics to Track

```yaml
monitoring:
  metrics:
    - "response_latency"
    - "error_rate"
    - "token_usage"
    - "cost_per_request"
```

---

## Version Management

Update your agent safely:

### Versioning Strategy

```yaml
metadata:
  version: "1.0.0"      # Initial release
  version: "1.1.0"      # Added feature
  version: "2.0.0"      # Breaking change
```

### Migration Guide

When updating agents:

1. **Create new version** — Don't modify existing
2. **Test thoroughly** — Verify behavior
3. **Document changes** — What's different?
4. **Deploy gradually** — Test with subset first
5. **Rollback plan** — Know how to revert

---

## Testing Customizations

### Unit Tests

```python
def test_custom_tool():
    agent = MyAgent()
    result = agent.use_custom_tool(data)
    assert result.success
    assert len(result.duration_ms) < 1000
```

### Integration Tests

```python
def test_workflow():
    agent = CustomOrchestrator()
    workflow = agent.start_workflow("your_workflow")
    assert workflow.status == "success"
    assert workflow.completed_steps == 5
```

### Prompt Tests

```python
def test_custom_behavior():
    agent = CustomAgent()
    response = agent.handle("test query")
    assert "detailed" in response or "long" in response
    assert response.count("\n") > 5  # Multiple lines
```

---

## Examples

### Healthcare Intake Agent

```yaml
metadata:
  name: "healthcare-intake"
  description: "Patient intake and triage"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.1  # Consistent, accurate

expertise:
  specialties:
    - "Patient intake"
    - "Symptom assessment"
    - "Triage prioritization"

tools:
  - check_medical_history
  - assess_symptoms
  - schedule_appointment
  - escalate_to_physician

quality_gates:
  - type: "hipaa_compliance"
    enabled: true
  - type: "accuracy_check"
    enabled: true

constraints:
  content_filters:
    - "pii"
```

### E-commerce Recommendation Agent

```yaml
metadata:
  name: "recommendation-engine"
  description: "Product recommendations"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.3  # Some variation

expertise:
  specialties:
    - "Product analysis"
    - "Customer preferences"
    - "Personalized recommendations"

tools:
  - query_product_catalog
  - get_user_history
  - analyze_preferences
  - generate_recommendations

quality_gates:
  - type: "recommendation_quality"
    enabled: true
    criteria: ["diversity", "relevance", "personalization"]
```

---

**Customization is iterative. Start simple, measure results, improve.**
