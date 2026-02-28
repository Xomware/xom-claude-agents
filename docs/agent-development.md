# Agent Development Guide

This guide walks you through building your own Claude-based agent using the xom-claude-agents framework.

## Quick Start

### 1. Choose Your Agent Type

- **Dispatcher** — Fast, low-latency responses (Haiku model)
- **Specialist** — Expert in a domain (Sonnet model)
- **Orchestrator** — Complex workflows (Opus model)

For most custom work, you'll create a **Specialist Agent**.

### 2. Copy the Template

```bash
cp templates/base-agent.yaml my-agent.yaml
cp -r templates/prompts my-agent-prompts/
```

### 3. Customize Your Agent

Edit `my-agent.yaml`:

```yaml
metadata:
  name: "my-agent"
  description: "What your agent does"
  version: "1.0.0"

model:
  name: "claude-sonnet-4-5"  # Choose Haiku/Sonnet/Opus
  temperature: 0.3
  max_tokens: 2000

expertise:
  specialties:
    - "Your expertise area"
    - "Another area"
```

### 4. Write Your System Prompt

Create `my-agent-prompts/system.md`:

```markdown
# My Agent System Prompt

You are [description of who you are].

## Core Principles
1. [Principle 1]
2. [Principle 2]

## Responsibilities
✓ [What you do]
✓ [What you do]

## Examples
[Show how you work]
```

### 5. Define Your Tools

Create `my-agent.yaml` tool section:

```yaml
tools:
  - name: "my_custom_tool"
    enabled: true
  - name: "another_tool"
    enabled: true
```

### 6. Test Your Agent

Run your agent and verify it works as expected.

---

## Agent Configuration Deep Dive

### Metadata

Every agent needs metadata:

```yaml
metadata:
  name: "agent-name"              # Unique identifier
  description: "What it does"     # One sentence
  version: "1.0.0"                # Semantic versioning
  author: "Your Name"             # Who maintains it
  tags: ["tag1", "tag2"]          # Categorization
```

### Model Selection

Choose based on your needs:

```yaml
model:
  provider: "anthropic"
  name: "claude-haiku-4-5"    # Fast, cheap
         "claude-sonnet-4-5"   # Balanced (recommended)
         "claude-opus-4-5"       # Powerful, slow
  
  temperature: 0.0                # Deterministic (0.0)
              0.5                 # Balanced (0.5)
              1.0                 # Creative (1.0)
  
  max_tokens: 1000                # Adjust per agent
```

### Performance Settings

Define SLAs:

```yaml
performance:
  latency_sla_ms: 5000            # Target response time
  timeout_ms: 10000               # Hard deadline
  max_concurrent_requests: 10     # Concurrency limit
```

### Expertise Definition

Tell Claude what you're good at:

```yaml
expertise:
  domain: "Your Domain"
  specialties:
    - "Specialty 1"
    - "Specialty 2"
  certifications:
    - "Relevant knowledge"
```

This helps Claude understand its role and respond appropriately.

### Constraints & Safety

Define boundaries:

```yaml
constraints:
  max_response_length: 2000
  max_tokens_per_request: 1000
  
  rate_limit:
    requests_per_minute: 30
  
  content_filters:
    - "pii"                 # Block personal info
    - "malicious_code"
    - "sensitive_data"
  
  requires_approval_for:
    - "critical_operations"
```

### Tools Definition

List available tools:

```yaml
tools:
  - name: "tool_name"
    enabled: true
    description: "What it does"
  
  - name: "another_tool"
    enabled: false          # Disabled by default
```

Define detailed tool specs in `tools.yaml`:

```yaml
tools:
  query_database:
    description: "Query the database"
    input_schema:
      type: "object"
      properties:
        query:
          type: "string"
          description: "SQL query"
      required: ["query"]
    cost:
      tokens: "100-500"
      api_calls: 1
    permissions:
      - "read_db"
    rate_limit: "10/minute"
```

### Quality Gates

Define validation checkpoints:

```yaml
quality_gates:
  - type: "safety_check"
    enabled: true
  
  - type: "accuracy_check"
    enabled: true
    criteria:
      - "spelling_correct"
      - "factually_accurate"
  
  - type: "code_lint"
    enabled: true
```

### Behavior Tuning

Adjust agent personality:

```yaml
behavior:
  style: "concise"        # concise, detailed, balanced
  tone: "professional"    # professional, friendly, technical
  explain_reasoning: true
  provide_alternatives: false
```

---

## System Prompt Best Practices

Your system prompt is the most important file. It defines the agent's personality and approach.

### Structure

```markdown
# Agent Name

One-sentence description.

## Core Principles
1. Principle 1 — Explanation
2. Principle 2 — Explanation
3. Principle 3 — Explanation

## Your Responsibilities
✓ What you do
✓ What you do
✓ What you do

## How You Work
[Detailed explanation of your approach]

## Examples
[Show specific examples of good behavior]

## Constraints & Safety
[What you won't do]

## Decision Tree / Process
[How you make decisions]

---

[Inspirational closing]
```

### Writing Effective System Prompts

**DO:**
- ✓ Be specific about expertise
- ✓ Give examples of good behavior
- ✓ Explain your reasoning
- ✓ Define clear boundaries
- ✓ Show decision processes

**DON'T:**
- ✗ Be vague about capabilities
- ✗ Forget examples
- ✗ Make it overly long
- ✗ Include contradictory instructions
- ✗ Assume knowledge not stated

### Example: Math Tutor Agent

```markdown
# Math Tutor Agent

You are a patient math tutor who helps students understand concepts.

## Core Principles
1. **Clarity Over Speed** — Explain thoroughly, not quickly
2. **Scaffolding** — Build from basics to complex
3. **Curiosity** — Ask questions to deepen understanding
4. **Encouragement** — Celebrate progress, not perfection

## Your Approach
1. Understand the student's current knowledge
2. Identify the gap they need to bridge
3. Teach using examples and visualization
4. Check understanding with questions
5. Build confidence through practice

## Example: Helping with Fractions
Student: "I don't understand why 1/2 + 1/3 = 5/6"

You: "Great question! Let's visualize this.
Imagine two pizzas:
- First pizza: divide into 2 pieces, take 1 (that's 1/2)
- Second pizza: divide into 3 pieces, take 1 (that's 1/3)

To add them, we need same-sized pieces (common denominator = 6):
- 1/2 = 3/6 (three sixths)
- 1/3 = 2/6 (two sixths)
- 3/6 + 2/6 = 5/6

Does that help? Can you try one yourself?"

## Boundaries
❌ Never give answers directly
❌ Never shame for wrong answers
❌ Never skip steps
✓ Always encourage growth mindset
```

---

## Tools Definition

Tools are how your agent interacts with the world.

### Tool Schema

Every tool needs a schema:

```yaml
tool_name:
  description: "Human-friendly description"
  category: "orchestration|context|communication|action"
  input_schema:
    type: "object"
    properties:
      param1:
        type: "string"
        description: "What this parameter is"
      param2:
        type: "integer"
        description: "Another parameter"
    required: ["param1"]
  
  output_schema:
    type: "object"
    properties:
      result:
        type: "string"
  
  cost:
    tokens: "100-500"
    api_calls: 1
    dollars: "0.01"
  
  permissions:
    - "read_database"
    - "write_logs"
  
  rate_limit: "10/minute"
  timeout_ms: 5000
```

### Common Tool Categories

- **orchestration** — Spawn agents, manage workflows
- **context** — Query memory, user data, project info
- **communication** — Send messages, notifications
- **action** — Execute commands, modify systems
- **analysis** — Analyze data, run checks
- **logging** — Record events for audit

### Tool Best Practices

1. **Keep tools focused** — One thing per tool
2. **Document thoroughly** — Clear descriptions and examples
3. **Validate inputs** — Check parameters before using
4. **Handle errors gracefully** — Meaningful error messages
5. **Log everything** — Track tool usage for audit

---

## Testing Your Agent

### Unit Tests

Test your agent's behavior:

```python
def test_agent_responds_to_simple_query():
    agent = MyAgent()
    response = agent.handle("What is 2+2?")
    assert "4" in response
    assert len(response) < 200  # Brief response

def test_agent_escalates_complex_tasks():
    agent = MyAgent()
    response = agent.handle("Build me a web app")
    assert "spawn" in response.lower()
    assert "agent" in response.lower()
```

### Integration Tests

Test agent workflows:

```python
def test_code_review_workflow():
    agent = CodeReviewAgent()
    pr_data = {
        "code": "...",
        "tests": "...",
    }
    review = agent.review(pr_data)
    assert "security" in review
    assert "performance" in review
    assert review.rating in ["approved", "needs_work"]
```

### Prompt Testing

Test your system prompt:

```python
def test_agent_follows_principles():
    # Test #1: Agent respects expertise boundaries
    assert agent.won't_code_if_not_coder()
    
    # Test #2: Agent explains reasoning
    response = agent.handle("Why did you choose X?")
    assert len(response) > 50  # Substantial explanation
    
    # Test #3: Agent escalates appropriately
    assert agent.escalates_complex_work()
```

---

## Common Patterns

### Dispatcher Pattern

Fast, routes to specialists:

```yaml
model:
  name: "claude-haiku-4-5"
  max_tokens: 500

performance:
  latency_sla_ms: 1000

tools:
  - spawn_subagent
  - respond_immediate
  - query_memory
```

### Specialist Pattern

Expert in domain:

```yaml
model:
  name: "claude-sonnet-4-5"
  max_tokens: 2000

performance:
  latency_sla_ms: 30000

tools:
  - domain_specific_tools
  - analysis_tools
  - validation_tools
```

### Orchestrator Pattern

Complex workflows, Opus reasoning:

```yaml
model:
  name: "claude-opus-4-5"
  max_tokens: 4000

state_management:
  enabled: true

tools:
  - spawn_subagent
  - wait_for_subagent
  - manage_workflow_state
  - execute_quality_gate
```

---

---

## Hooks Framework

Hooks are **deterministic code** that runs before and after every LLM invocation. They are the most cost-effective quality mechanism in the stack — zero LLM tokens, near-zero latency.

### Pre-Invoke Hooks

Run before the LLM is called:

```yaml
hooks:
  pre_invoke:
    - name: "route_model"
      description: "Classify task → assign Haiku/Sonnet/Opus based on complexity"
      enabled: true
      routing_rules:
        simple_lookup: "claude-haiku-4-5"
        code_or_analysis: "claude-sonnet-4-5"
        complex_planning: "claude-opus-4-5"
    - name: "validate_input"
      description: "Schema validation — fail fast, don't spend tokens on bad input"
      enabled: true
    - name: "check_permissions"
      description: "ACL enforcement before any LLM cost is incurred"
      enabled: true
    - name: "rate_limit_check"
      description: "Enforce per-agent rate limits deterministically"
      enabled: true
    - name: "mcp_scope_check"
      description: "Verify active MCP count ≤10 before invocation"
      enabled: true
```

### Post-Invoke Hooks

Run after the LLM responds:

```yaml
hooks:
  post_invoke:
    - name: "output_schema_check"
      description: "Validate output shape and required fields"
      enabled: true
    - name: "cost_tracker"
      description: "Log token usage, flag over-budget runs"
      enabled: true
    - name: "quality_gate_runner"
      description: "Run pre-merge gates (compile, coverage, lint, security)"
      enabled: true
```

### Why Hooks Matter

| Problem | Without Hooks | With Hooks |
|---------|--------------|-----------|
| Wrong model chosen | Pays Opus price for Haiku task | Routes automatically, saves ~90% |
| Bad input | LLM returns confusing error | Fails in <1ms, no token cost |
| Coverage <80% | Merges bad code | Blocks merge deterministically |
| >10 MCPs active | Confused model, slow responses | Blocked before invocation |

---

## MCP Tool Discipline

**Rule: Maximum 10 MCP tools active at any time.**

Context windows fill up. Excess tools confuse models, increase hallucination risk, and inflate latency. Every agent must declare its MCP whitelist.

### Configuration

```yaml
mcp_tools:
  max_active: 10                  # Hard ceiling — never exceed
  whitelist:                      # Default active tools for this agent
    - "github"                    # Always-on for code agents
    - "supabase"                  # Always-on for data agents
    - "slack"                     # Always-on for notification agents
  temp_tool_allowed: true         # Can request 1 additional temp tool
  temp_tool_auto_remove: true     # Auto-removed when task completes
```

### Standard MCP Whitelist by Agent Type

| Agent | Default MCPs | Max Total |
|-------|-------------|-----------|
| Dispatcher (Boris) | github, slack | ≤10 |
| Forge (Code) | github, supabase | ≤10 |
| Recon (Research) | github, slack | ≤10 |
| Scribe (Docs) | github, slack | ≤10 |
| Deployer (DevOps) | github, aws, slack | ≤10 |
| Orchestrator | github, slack, aws, supabase | ≤10 |

### Requesting a Temp Tool

```yaml
# In task spec, agent may request 1 temp tool:
temp_tool_request:
  tool: "stripe"
  reason: "Processing refund for this task"
  # auto_remove: true (default)
```

---

## Model Routing Decision Tree

Use this to decide which model tier to assign. The `route_model` pre-invoke hook enforces this automatically when configured.

```
Task received
    ├─ Simple: lookup, formatting, short Q&A, status check?
    │  └─ claude-haiku-4-5   (~$0.01/task, <2 min)
    │
    ├─ Medium: code gen, refactoring, analysis, research?
    │  └─ claude-sonnet-4-5  (~$0.05/task, <5 min)
    │
    └─ Complex: architecture, multi-step planning, long reasoning?
       └─ claude-opus-4-5    (~$0.15/task, <10 min)

Target distribution: ~60% Haiku · ~30% Sonnet · ~10% Opus
Expected savings vs. all-Sonnet baseline: ~50%
```

### Cost Example (100 tasks/day)

| Approach | Breakdown | Daily Cost |
|----------|-----------|-----------|
| All Sonnet (old) | 100 × $0.05 | $5.00 |
| Routed (new) | 60 Haiku + 30 Sonnet + 10 Opus | $2.50 |
| **Savings** | | **50%** |

---

## Pre-Merge Gates (Required)

Every PR that agents produce must pass all four gates before auto-merge:

```yaml
quality_gates:
  pre_merge:
    - type: "compile_check"     # Code builds without errors
      fail_action: "block_merge"
    - type: "test_coverage"     # ≥80% unit test coverage
      min_coverage: 0.80
      fail_action: "block_merge"
    - type: "lint"              # Zero lint errors (TS/SCSS/language-specific)
      fail_action: "block_merge"
    - type: "security_scan"     # No critical vulns; prompt injection scan
      fail_on: ["critical", "prompt_injection"]
      fail_action: "block_merge"
```

> **Note on coverage**: The legacy threshold was 70%. This has been raised to **80%** across all agents. Update any older configs that still reference 70%.

---

## Deployment

### Local Development

```bash
# Copy template
cp templates/base-agent.yaml dev-agent.yaml

# Edit config
nano dev-agent.yaml

# Test locally
python test_agent.py dev-agent.yaml
```

### Production

1. **Review** — Have someone review your agent config
2. **Test** — Verify it works in staging
3. **Document** — Update README and docs
4. **Deploy** — Push to your agent registry
5. **Monitor** — Track agent usage and quality

### Versioning

Use semantic versioning:

```
1.0.0
│ │ └─ Patch: Bug fixes
│ └─── Minor: New features
└───── Major: Breaking changes
```

---

## Troubleshooting

### Agent Responds Too Slowly

→ Reduce max_tokens  
→ Use Haiku instead of Sonnet  
→ Simplify system prompt  

### Agent Makes Mistakes

→ Add examples to system prompt  
→ Enable quality gates  
→ Clarify expertise boundaries  

### Agent Escalates Too Often

→ Add more tools  
→ Improve system prompt  
→ Increase temperature slightly  

### Agent Costs Too Much

→ Use Haiku instead  
→ Reduce max_tokens  
→ Cache common queries  

---

## Next Steps

1. Review the example agents in `examples/`
2. Choose a template that matches your needs
3. Write your system prompt
4. Define your tools
5. Test and iterate
6. Deploy!

---

**Your agent is a reflection of your instructions. Be clear, be specific, be kind.**
