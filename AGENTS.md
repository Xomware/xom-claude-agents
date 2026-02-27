# AGENTS.md — Complete Agent Reference

Reference guide for all agents in the xom-claude-agents framework.

## Core Agents

### 1. Dispatcher (Boris)

**Purpose**: Fast, minimal agent for immediate user responses  
**Model**: Claude 3.5 Haiku  
**Latency SLA**: <1 second  

**Responsibilities**:
- ✓ Immediate responses to user queries
- ✓ Triage requests to specialists
- ✓ Quick status updates
- ✓ Spawn sub-agents

**Tools**:
- `spawn_subagent` — Create Forge, Recon, Scribe, Deployer, or Orchestrator
- `respond_immediate` — Send response to user
- `query_memory` — Check context and history
- `log_interaction` — Record for audit

**Key Features**:
- Haiku model (fast, cheap)
- Max 500 tokens
- Response in <1 second
- Simple, direct communication

**When to Use**:
- Answering quick questions
- Routing complex requests
- Status checks
- Real-time iMessage responses

**Example**:
```
User: "Build me a new API"
Dispatcher: "Spawning Forge agent. I'll check in once it's done."
```

---

### 2. Orchestrator (Opus-level)

**Purpose**: Complex multi-step workflows with state management  
**Model**: Claude 3 Opus  
**Latency**: Minutes to hours (async)  

**Responsibilities**:
- ✓ Complex workflow coordination
- ✓ Specialist agent management
- ✓ State management & checkpoints
- ✓ Quality gate enforcement
- ✓ Escalation & approval handling

**Tools**:
- `spawn_subagent` — Create any specialist agent
- `wait_for_subagent` — Monitor agent completion
- `manage_workflow_state` — Get/set workflow state
- `execute_quality_gate` — Run validations
- `escalate_to_human` — Request approval
- `query_context` — Get project/user context
- `log_workflow` — Log progress

**Workflow Patterns**:
- Code Review Flow (5 steps)
- Deployment Flow (8 steps)
- Research Flow (6 steps)

**Key Features**:
- Full Opus reasoning
- Stateful workflows
- Multi-agent orchestration
- Quality gates at every step
- Approval workflows

**When to Use**:
- Multi-day projects
- Complex deployments
- Cross-functional workflows
- High-stakes decisions

**Example**:
```
Code Review Workflow:
1. Spawn Forge → Code analysis
2. Spawn Recon → Security review
3. Run quality gates
4. Escalate to approval
5. Merge if approved
```

---

## Specialist Agents

### 3. Forge (Code Agent)

**Purpose**: Code generation, refactoring, and review  
**Model**: Claude 3.5 Sonnet  
**Latency SLA**: <30 seconds  

**Expertise**:
- Python, JavaScript/TypeScript, Go, Rust, Java, C++, SQL, Bash

**Specialties**:
- Code generation
- Code review & feedback
- Refactoring
- Bug fixing
- Test writing
- Performance optimization

**Tools**:
- `write_code` — Generate code
- `review_code` — Provide detailed feedback
- `run_linter` — Check code quality
- `execute_tests` — Run test suite
- `analyze_performance` — Profile code
- `git_operations` — Manage version control
- `query_codebase` — Search codebase
- `suggest_improvements` — Find optimizations

**Quality Gates**:
- Code linting ✓
- Test coverage (min 70%)
- Security checks (fail on critical)
- Format validation

**When to Use**:
- Writing new code
- Code review
- Refactoring
- Bug fixes
- Performance optimization

**Example Code Review**:
```
## Issues Found
1. **Hardcoded Secret** (CRITICAL)
   Fix: Use environment variable
   
2. **Missing Rate Limiting** (HIGH)
   Fix: Add rate limiter middleware

Rating: Needs Work — Fix before merging
```

---

### 4. Recon (Research Agent)

**Purpose**: Literature research and data synthesis  
**Model**: Claude 3.5 Sonnet  
**Latency**: <30 seconds per query  

**Specialties**:
- Literature research
- Data analysis
- Competitive analysis
- Market research
- Security analysis
- Trend identification
- Fact-checking

**Tools**:
- `search_sources` — Find relevant sources
- `fetch_content` — Get article content
- `analyze_data` — Statistical analysis
- `compare_options` — Side-by-side comparison
- `create_summary` — Distill findings
- `visualize_data` — Create charts
- `fact_check` — Verify claims

**Quality Gates**:
- Source quality assessment
- Fact verification
- Bias detection
- Accuracy checking

**Research Process**:
1. Source collection
2. Content analysis
3. Data synthesis
4. Fact verification
5. Report generation

**When to Use**:
- Researching technologies
- Competitive analysis
- Market assessment
- Fact-checking
- Synthesis of information

**Example Research Output**:
```
## Finding: TypeScript adoption accelerating
- 2021: 22% of JS projects
- 2023: 38% of JS projects
- Growth: ~8% year-over-year

## Drivers
1. Type safety for large codebases
2. Better IDE support
3. Ecosystem maturity

## Barriers
1. Learning curve
2. Build complexity
3. Smaller library ecosystem
```

---

### 5. Scribe (Documentation Agent)

**Purpose**: Technical writing and documentation  
**Model**: Claude 3.5 Sonnet  
**Latency**: <30 seconds  

**Specialties**:
- API documentation
- User guides
- How-to guides
- Architecture docs
- Troubleshooting guides
- README files

**Output Formats**:
- Markdown
- AsciiDoc
- HTML
- PDF

**Tools**:
- `write_documentation` — Create docs
- `review_documentation` — Provide feedback
- `create_visuals` — Generate diagrams
- `generate_examples` — Code examples
- `check_style` — Grammar/style check
- `update_docs` — Keep current

**Quality Gates**:
- Clarity check
- Completeness check
- Style consistency
- Accuracy verification

**Writing Principles**:
1. Clarity over completeness
2. Show before telling
3. Progressive disclosure
4. Scannable structure
5. Active voice

**When to Use**:
- API documentation
- User guides
- Internal documentation
- Tutorial creation
- Documentation review

**Example Documentation**:
```markdown
## How to Deploy Your App

### Prerequisites
- Node.js 18+
- 5 minutes

### Steps
1. Create app directory
2. Install dependencies
3. Deploy to platform

### Verification
Visit your app URL
```

---

### 6. Deployer (DevOps Agent)

**Purpose**: Infrastructure and deployment  
**Model**: Claude 3.5 Sonnet  
**Latency**: <30 seconds for planning, varies for execution  

**Expertise**:
- AWS, GCP, Azure, DigitalOcean
- Terraform, CloudFormation, Helm
- Kubernetes, Docker
- GitHub Actions, GitLab CI, Jenkins
- Prometheus, Grafana, CloudWatch

**Specialties**:
- Infrastructure provisioning
- Application deployment
- CI/CD pipeline management
- Monitoring configuration
- Scaling management
- Incident response

**Tools**:
- `provision_infrastructure` — Create resources
- `deploy_application` — Update code
- `manage_ci_cd` — Pipeline configuration
- `configure_monitoring` — Setup monitoring
- `run_health_checks` — Verify health
- `manage_secrets` — Handle credentials
- `execute_rollback` — Revert deployment
- `scale_resources` — Adjust capacity

**Quality Gates**:
- Infrastructure validation
- Security scanning (fail on critical)
- Cost estimation
- Approval gates

**Deployment Strategies**:
- Blue-Green (zero downtime, instant rollback)
- Canary (5% → 50% → 100%)
- Rolling (one server at a time)

**When to Use**:
- Provisioning infrastructure
- Deploying applications
- CI/CD setup
- Monitoring configuration
- Scaling decisions
- Incident response

**Example Deployment**:
```
Deployment: v1.2.3 → v1.2.4

Strategy: Blue-Green
- Update Green environment
- Test thoroughly
- Switch traffic
- Keep Blue for rollback

Rollback: Instant to v1.2.3
```

---

## Templates

### Base Agent Template

Foundation for custom agents:

```yaml
metadata:
  name: "agent-name"
  description: "What your agent does"
  version: "1.0.0"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.3
  max_tokens: 1000

tools:
  - name: "tool_1"
  - name: "tool_2"
```

### Specialist Template

Template for domain-specific agents:

```yaml
metadata:
  name: "specialist"
  description: "Domain expert agent"

model:
  name: "claude-3-5-sonnet-latest"

expertise:
  domain: "Your Domain"
  specialties: [...]

tools: [...]

quality_gates: [...]
```

---

## Examples

### Code Review Agent

Automated PR feedback with detailed analysis:
- Code quality checks
- Security scanning
- Performance analysis
- Test coverage verification

### Incident Response Agent

On-call incident triage and response:
- Alert triage
- Root cause analysis
- Remediation execution
- Status updates

### Research Agent

Literature research and data synthesis:
- Source collection
- Content analysis
- Fact verification
- Report generation

---

## Choosing the Right Agent

| Need | Agent | Why |
|------|-------|-----|
| Fast response | Dispatcher | Haiku model, <1s |
| Code work | Forge | Expert in languages |
| Research | Recon | Synthesis specialist |
| Documentation | Scribe | Writing expert |
| Infrastructure | Deployer | DevOps specialist |
| Complex workflow | Orchestrator | Multi-step coordination |
| Custom domain | Custom Specialist | Build your own |

---

## Agent Comparison

| Feature | Dispatcher | Specialists | Orchestrator |
|---------|-----------|-------------|--------------|
| Model | Haiku | Sonnet | Opus |
| Speed | <1s | <30s | Minutes |
| Complexity | Simple | Medium | Complex |
| Tools | Minimal | Medium | Full |
| State | No | Minimal | Rich |
| Cost | Low | Medium | High |
| Use Case | Triage | Execution | Coordination |

---

## Configuration Quick Reference

### Model Selection
```yaml
model:
  name: "claude-3-5-haiku-latest"    # Fast, cheap
         "claude-3-5-sonnet-latest"   # Balanced
         "claude-3-opus-latest"       # Powerful
```

### Performance
```yaml
performance:
  latency_sla_ms: 1000              # Target time
  timeout_ms: 10000                 # Hard deadline
  max_concurrent_requests: 10       # Concurrency
```

### Constraints
```yaml
constraints:
  max_response_length: 2000
  max_tokens_per_request: 1000
  rate_limit:
    requests_per_minute: 30
```

### Quality Gates
```yaml
quality_gates:
  - type: "safety_check"
    enabled: true
  - type: "accuracy_check"
    enabled: true
```

---

## Deployment Paths

### Option 1: Local Development
- Run agents locally
- Perfect for testing
- No infrastructure needed

### Option 2: Container (Docker)
- Deploy as Docker containers
- Easy scaling
- Cloud-ready

### Option 3: Serverless (Lambda, Cloud Functions)
- Pay per invocation
- Auto-scaling
- Cost-effective for bursty workloads

### Option 4: Kubernetes
- Advanced orchestration
- Auto-healing
- Complex deployments

---

## Support & Resources

- **Docs**: `docs/agent-development.md`
- **Examples**: `examples/`
- **Templates**: `templates/`
- **Customization**: `docs/customization-guide.md`
- **Deployment**: `docs/deployment.md`

---

**Each agent is a specialist. Use them together for maximum power.**
