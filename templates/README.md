# Agent Templates

Ready-to-customize templates for building your own Claude-based agents.

## Available Templates

### 1. Base Agent Template (`base-agent.yaml`)

Foundation for any agent. Start here if unsure.

**Use When**:
- Building a simple, custom agent
- Don't have a specific category
- Just want a working example

**What It Includes**:
- Basic metadata
- Simple model configuration
- Essential constraints
- Minimal tool setup
- Basic quality gates

**To Use**:
```bash
cp base-agent.yaml my-agent.yaml
nano my-agent.yaml
mkdir my-agent-prompts
cp prompts/system.md my-agent-prompts/system.md
nano my-agent-prompts/system.md
```

### 2. Specialist Agent Template (`specialist-agent.yaml`)

Template for domain-specific experts (code, research, docs, etc).

**Use When**:
- Building an expert in a specific domain
- Creating a reusable specialist
- Need detailed expertise configuration

**What It Includes**:
- Domain expertise definition
- Balanced performance settings
- Comprehensive constraints
- Specialized tools
- Quality gates for domain

**To Use**:
```bash
cp specialist-agent.yaml my-specialist.yaml
# Edit to define your domain
nano my-specialist.yaml
```

---

## Quick Start

### 1. Copy a Template

```bash
# For simple agents
cp base-agent.yaml my-agent.yaml

# For specialized domains
cp specialist-agent.yaml my-agent.yaml
```

### 2. Edit Configuration

```yaml
metadata:
  name: "my-agent"
  description: "What my agent does"
  version: "1.0.0"
  author: "Your Name"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.3

expertise:
  domain: "Your Domain"
  specialties:
    - "Specialty 1"
    - "Specialty 2"

tools:
  - name: "tool_1"
  - name: "tool_2"
```

### 3. Create System Prompt

Create `prompts/system.md`:

```markdown
# Your Agent Name

You are [description].

## Core Principles
1. [Principle 1]
2. [Principle 2]

## Responsibilities
✓ [What you do]
✓ [What you do]

## Examples
[Show how you work]
```

### 4. Test Your Agent

```bash
python test_agent.py my-agent.yaml
```

---

## Template Comparison

| Feature | Base | Specialist |
|---------|------|-----------|
| Complexity | Simple | Medium |
| Flexibility | High | High |
| Setup time | 5 min | 10 min |
| Best for | Quick builds | Expert agents |
| Model | Sonnet | Sonnet |
| Tools | 2-3 | 5-7 |
| Examples | Minimal | Detailed |

---

## Model Selection Guide

When customizing, choose the right model:

```yaml
model:
  name: "claude-3-5-haiku-latest"
```
- ✓ Use for: Fast responses, simple tasks
- ✓ Latency: <1 second
- ✓ Cost: Very low
- ✓ Reasoning: Basic

```yaml
model:
  name: "claude-3-5-sonnet-latest"
```
- ✓ Use for: General purpose (recommended)
- ✓ Latency: <10 seconds
- ✓ Cost: Moderate
- ✓ Reasoning: Good
- **← Start with this for specialists**

```yaml
model:
  name: "claude-3-opus-latest"
```
- ✓ Use for: Complex reasoning, workflows
- ✓ Latency: <30 seconds
- ✓ Cost: High
- ✓ Reasoning: Excellent

---

## Configuration Best Practices

### Metadata

Always include:
```yaml
metadata:
  name: "unique-name"           # Lowercase, no spaces
  description: "One sentence"   # Clear purpose
  version: "1.0.0"              # Semantic versioning
  author: "Your Name"           # Who maintains it
  tags: ["tag1", "tag2"]        # Categorization
```

### Model Config

Adjust for your domain:
```yaml
model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.3              # Lower = consistent
                                # Higher = creative
  max_tokens: 1000              # Output size limit
```

### Constraints

Define safety boundaries:
```yaml
constraints:
  max_response_length: 2000     # Prevent rambling
  max_tokens_per_request: 1000  # Token budget
  rate_limit:
    requests_per_minute: 30     # Prevent abuse
  content_filters:
    - "pii"                     # Personal info
    - "malicious_code"
```

### Tools

Start simple, add as needed:
```yaml
tools:
  - name: "essential_tool"
    enabled: true
  - name: "optional_tool"
    enabled: false              # Add later
```

### Quality Gates

Validate output:
```yaml
quality_gates:
  - type: "safety_check"
    enabled: true
  - type: "domain_check"
    enabled: true               # Your domain-specific gate
```

---

## Customization Examples

### Example 1: Customer Support Agent

```yaml
metadata:
  name: "support-agent"
  description: "Customer support specialist"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.2              # Consistent responses

expertise:
  domain: "Customer Support"
  specialties:
    - "Troubleshooting"
    - "Policy explanation"
    - "Escalation handling"

tools:
  - query_customer_history
  - look_up_policy
  - escalate_to_human

quality_gates:
  - type: "empathy_check"
  - type: "accuracy_check"
```

### Example 2: Data Analysis Agent

```yaml
metadata:
  name: "data-analyst"
  description: "Data analysis and visualization specialist"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.3

expertise:
  domain: "Data Analysis"
  specialties:
    - "Statistical analysis"
    - "Data visualization"
    - "Trend identification"

tools:
  - query_database
  - analyze_data
  - create_visualizations
  - generate_reports

quality_gates:
  - type: "accuracy_check"
  - type: "methodology_check"
```

### Example 3: Writing Agent

```yaml
metadata:
  name: "content-writer"
  description: "Professional content writing specialist"

model:
  name: "claude-3-5-sonnet-latest"
  temperature: 0.4              # Some variation

expertise:
  domain: "Content Writing"
  specialties:
    - "Blog posts"
    - "Marketing copy"
    - "Technical documentation"

tools:
  - write_content
  - improve_readability
  - check_grammar
  - optimize_seo

quality_gates:
  - type: "clarity_check"
  - type: "tone_check"
  - type: "grammar_check"
```

---

## Tips for Success

### Writing System Prompts

**DO:**
- ✓ Be specific about expertise
- ✓ Include examples of good behavior
- ✓ Explain your reasoning
- ✓ Define clear boundaries

**DON'T:**
- ✗ Be vague
- ✗ Make it too long
- ✗ Include contradictions
- ✗ Assume too much knowledge

### Choosing Tools

**Start minimal:**
- 2-3 essential tools
- Add more as needed
- Don't include unused tools

**Keep tools focused:**
- One responsibility per tool
- Clear input/output
- Well-documented

### Testing

**Always test before deploying:**
```bash
# Test basic functionality
python test_agent.py my-agent.yaml

# Test with real queries
echo "Test query" | python run_agent.py my-agent.yaml
```

---

## Common Issues

### Agent Responds Too Long

```yaml
# Solution: Reduce max_tokens
model:
  max_tokens: 500  # Was 1000
```

### Agent Lacks Expertise

```yaml
# Solution: Improve system prompt with examples
# File: prompts/system.md
# Add detailed examples of your domain
```

### Agent Makes Mistakes

```yaml
# Solution: Add quality gates
quality_gates:
  - type: "domain_validation"
    enabled: true
  - type: "accuracy_check"
    enabled: true
```

---

## Next Steps

1. **Choose a template** (base or specialist)
2. **Copy and customize** the configuration
3. **Write your system prompt** with examples
4. **Define your tools** specific to your domain
5. **Test locally** before deploying
6. **Review documentation**:
   - `../docs/agent-development.md`
   - `../docs/customization-guide.md`
   - `../docs/deployment.md`

---

## Deployment

When ready to deploy:

```bash
# Check configuration
python validate_agent.py my-agent.yaml

# Deploy to staging
./deploy.sh my-agent.yaml staging

# If successful, deploy to production
./deploy.sh my-agent.yaml production
```

See `../docs/deployment.md` for details.

---

**Start simple. Test thoroughly. Deploy with confidence.**
