# xom-claude-agents

A production-ready multi-agent framework for building Claude-based agents with specialized roles, hierarchical workflows, and pluggable tool systems.

## Overview

This framework provides a complete system for orchestrating Claude agents in complex workflows:

- **Dispatcher** — Fast, low-latency agent for immediate iMessage-style responses
- **Orchestrator** — Complex workflow coordinator with state management and quality gates  
- **Specialists** — Task-specific agents (Forge for code, Recon for research, Scribe for docs, Deployer for infrastructure)
- **Templates** — Base templates for rapid agent development
- **Examples** — Real-world agent patterns (code review, incident response, research)

## Quick Start

### 1. Choose Your Agent Pattern

```bash
# Fast dispatcher (iMessage-style, <1s latency)
cp templates/dispatcher-agent.yaml my-dispatcher.yaml

# Complex workflow (state, quality gates, Opus-level reasoning)
cp templates/orchestrator-agent.yaml my-orchestrator.yaml

# Custom specialist (code, research, docs, infra)
cp templates/specialist-agent.yaml my-specialist.yaml
```

### 2. Configure & Deploy

```bash
# Edit your agent config
nano my-dispatcher.yaml

# Deploy to your system
./scripts/deploy.sh my-dispatcher.yaml
```

### 3. Use Real-World Examples

See `examples/` for:
- **code-review-agent.yaml** — Automated code review with detailed feedback
- **incident-response-agent.yaml** — On-call incident triage and response
- **research-agent.yaml** — Literature research and synthesis

## Directory Structure

```
agents/
  ├── dispatcher/           # Fast iMessage-style agent
  │   ├── agent.yaml       # Agent config
  │   ├── prompts/         # Specialized prompts
  │   └── tools.yaml       # Tool definitions
  ├── orchestrator/         # Complex workflow coordinator
  ├── specialists/          # Task-specific agents
  │   ├── forge-code-agent/
  │   ├── recon-research-agent/
  │   ├── scribe-docs-agent/
  │   └── deployer-devops-agent/

templates/                  # Agent templates for rapid development
  ├── base-agent.yaml      # Foundation for all agents
  ├── specialist-agent.yaml # Specialist template
  └── README.md

examples/                   # Real-world agent patterns
  ├── code-review-agent.yaml
  ├── incident-response-agent.yaml
  └── research-agent.yaml

docs/                       # Complete documentation
  ├── agent-development.md  # How to build agents
  ├── customization-guide.md
  └── deployment.md

AGENTS.md                   # Agent reference guide
LICENSE                     # MIT License
```

## Agent Types

### Dispatcher (Boris)
- **Purpose**: Immediate response to user queries on iMessage
- **Model**: Haiku (low-latency, cost-effective)
- **Latency**: <1 second target
- **Role**: Triage and spawn specialized sub-agents
- **Tools**: Minimal (message routing, sub-agent spawning)

### Orchestrator (Opus-level reasoning)
- **Purpose**: Complex multi-step workflows with state management
- **Model**: Opus (advanced reasoning, complex tasks)
- **Latency**: Minutes to hours (async)
- **Role**: Coordinate specialists, manage quality gates
- **Tools**: Full suite (code, APIs, databases, analysis)

### Specialists

#### Forge (Code Agent)
- Code generation, refactoring, review
- Languages: Python, JavaScript, Go, Rust, etc.
- Tools: Git, package managers, linters, formatters

#### Recon (Research Agent)
- Literature research, data analysis, synthesis
- Tools: Web search, APIs, databases, data visualization

#### Scribe (Documentation Agent)
- Technical writing, API docs, user guides
- Output: Markdown, AsciiDoc, HTML
- Tools: Documentation generators, style checkers

#### Deployer (DevOps Agent)
- Infrastructure provisioning, CI/CD configuration
- Cloud platforms: AWS, GCP, Azure, K8s
- Tools: Terraform, Helm, cloud CLIs, IaC validators

## Core Concepts

### Agent Config (agent.yaml)
Every agent has a config defining:
- **metadata**: Name, version, description
- **model**: Claude model choice (Haiku, Sonnet, Opus)
- **system_prompt**: Specialized instructions
- **constraints**: Rate limits, safety boundaries
- **tools**: Available tools and permissions
- **quality_gates**: Output validation rules

### Tool System (tools.yaml)
Define tools with:
- **name**: Tool identifier
- **description**: What it does
- **input_schema**: JSON schema for parameters
- **permissions**: ACL and resource limits
- **cost**: Token/API cost estimates

### Quality Gates
Validation rules that run on agent output:
- Accuracy checks (code linters, schema validation)
- Safety checks (content filtering, permission validation)
- Cost checks (API limits, token budgets)
- Latency gates (SLA enforcement)

### Prompts
Agent behavior is defined through specialized prompts in `prompts/` subdirectories:
- `system.md` — Core system instructions
- `constraints.md` — Behavioral boundaries
- `examples.md` — Few-shot examples
- `tools-context.md` — How to use tools

## Configuration Examples

### Minimal Dispatcher
```yaml
metadata:
  name: "fast-dispatcher"
  model: "claude-3-5-haiku"
  latency_sla_ms: 1000

system_prompt: |
  You are a fast dispatcher. Respond in <100 words.
  For complex requests, spawn a sub-agent.

tools:
  - name: spawn_subagent
    description: "Spawn a specialized sub-agent"
  - name: respond_immediate
    description: "Send immediate iMessage response"
```

### Complex Orchestrator
```yaml
metadata:
  name: "orchestrator"
  model: "claude-3-opus"
  async: true

state_management:
  backend: "redis" | "postgres"
  retention_days: 30

quality_gates:
  - type: "code_lint"
    enabled: true
  - type: "permission_check"
    enabled: true
  - type: "cost_limit"
    max_tokens: 100000
```

## Getting Started

### 1. Read the Agent Development Guide
```bash
cat docs/agent-development.md
```

### 2. Review the Dispatcher Agent
```bash
cat agents/dispatcher/agent.yaml
cat agents/dispatcher/prompts/system.md
```

### 3. Try an Example
```bash
cat examples/code-review-agent.yaml
# Customize and use with your system
```

### 4. Build a Custom Agent
```bash
cp templates/base-agent.yaml my-agent.yaml
# Edit config, add prompts, test
```

## Documentation

- **[Agent Development Guide](docs/agent-development.md)** — Complete how-to
- **[Customization Guide](docs/customization-guide.md)** — Extending agents
- **[Deployment Guide](docs/deployment.md)** — Production deployment
- **[AGENTS.md](AGENTS.md)** — Agent reference with capabilities

## Features

✅ **Production-Ready** — Used in real workflows  
✅ **Customizable** — Extend templates for your use case  
✅ **Type-Safe** — JSON schemas for all configs  
✅ **Quality Gates** — Validation and safety checks  
✅ **Cost Controls** — Token budgets and rate limits  
✅ **Complete Examples** — Real-world patterns  

## License

MIT — See [LICENSE](LICENSE)

## Contributing

Contributions welcome! See [docs/agent-development.md](docs/agent-development.md) for guidelines.

---

**Built with Claude** | Fast dispatch meets advanced reasoning
