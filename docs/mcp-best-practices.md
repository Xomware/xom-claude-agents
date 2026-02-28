# MCP Tool Discipline — Best Practices

> **TL;DR:** Each agent should have ≤ 10 enabled MCP tools. More tools = more tokens = more cost + more attack surface.

---

## Table of Contents

1. [Why the 10-Tool Limit Matters](#1-why-the-10-tool-limit-matters)
2. [Tool Categories](#2-tool-categories)
3. [The .mcp.json Standard Format](#3-the-mcpjson-standard-format)
4. [Agent YAML Discipline Section](#4-agent-yaml-discipline-section)
5. [Running the Audit Locally](#5-running-the-audit-locally)
6. [Cost Math](#6-cost-math)
7. [FAQ](#7-faq)

---

## 1. Why the 10-Tool Limit Matters

### Token Overhead

Every enabled MCP tool injects a tool definition into the model's context window at the start of every request. A single tool definition averages **200–500 tokens** depending on description verbosity and parameter schema.

| Enabled Tools | Overhead per Request | At 1000 req/day   |
|---------------|---------------------|-------------------|
| 5             | ~1,500 tokens        | ~1.5M tokens/day  |
| 10            | ~3,000 tokens        | ~3M tokens/day    |
| 20            | ~6,000 tokens        | ~6M tokens/day    |
| 30            | ~9,000 tokens        | ~9M tokens/day    |

Halving your tool count from 20→10 cuts token overhead by ~50%, directly reducing inference cost.

### Security Surface

Each enabled tool is a callable capability. Unnecessary tools:
- Expand the blast radius of prompt injection attacks
- Create unintended capability paths for adversarial inputs
- Complicate audit trails when tools are invoked unexpectedly

### Latency

Tool schema parsing adds latency. Fewer tools = faster cold starts, especially for latency-sensitive agents like the dispatcher (SLA: 1s).

### Focus

Agents perform better when their capability set matches their role. A dispatcher that *cannot* write code is naturally nudged toward its intended behavior (triage and spawn), rather than attempting to solve problems itself.

---

## 2. Tool Categories

Classify every tool before enabling it:

### ✅ Essential (Always Enabled)
Core tools the agent *cannot function without*. These should be ≤ 5.

Examples for dispatcher:
- `spawn_subagent` — core purpose
- `respond_immediate` — core purpose
- `query_memory` — required for context

### 🟡 Conditional (Situationally Enabled)
Tools needed for specific task types. Enable these only if the agent regularly handles those tasks.

Keep these ≤ 5 to stay within the 10-tool budget.

### 🔴 Disabled (Commented Out)
Tools that were added "just in case" but aren't used regularly. Comment out with a note:

```yaml
tools:
  - name: "some_tool"
    enabled: false  # conditional: enable only for X scenario
    description: "..."
```

### Decision Checklist

Before enabling a tool, answer:
- [ ] Does this agent need this tool at least once per 10 requests?
- [ ] Is this tool already covered by a sub-agent we can spawn?
- [ ] Would removing this tool break a core workflow?
- [ ] Can this capability be achieved with an existing enabled tool?

If you answered "no" to the first question or "yes" to the second, **don't enable it**.

---

## 3. The .mcp.json Standard Format

For local development, tools are configured via `.mcp.json` at the repo root or agent directory. Follow this structure:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/workspace"],
      "enabled": true,
      "category": "essential"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": true,
      "category": "essential"
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "${DATABASE_URL}"],
      "enabled": false,
      "category": "conditional",
      "enable_when": "database queries required"
    }
  }
}
```

**Key fields:**
| Field | Required | Description |
|-------|----------|-------------|
| `enabled` | Yes | Controls whether the tool is loaded |
| `category` | Recommended | `essential` \| `conditional` \| `disabled` |
| `enable_when` | For disabled/conditional | Documents when to enable |

---

## 4. Agent YAML Discipline Section

Every `agent.yaml` must include the following inside the `tools:` block:

```yaml
tools:
  # MCP Discipline — enforced via scripts/mcp-audit.sh
  max_enabled: 10
  audit_frequency: "weekly"

  - name: "tool_name"
    enabled: true
    description: "What this tool does"
  # ... more tools
```

**Fields:**

| Field | Description |
|-------|-------------|
| `max_enabled` | Hard ceiling on enabled tools (default: 10) |
| `audit_frequency` | Reminder cadence for manual review (`weekly`, `monthly`) |

Specialist agents with narrow scope should target **≤ 8 tools**. The limit of 10 is a ceiling, not a target.

---

## 5. Running the Audit Locally

The audit script scans all `agent.yaml` files and reports tool counts vs. limits.

### Install Prerequisites

```bash
# Python 3 required for --fix mode
python3 --version

# Make script executable (one-time)
chmod +x scripts/mcp-audit.sh
```

### Basic Audit (Table Output)

```bash
./scripts/mcp-audit.sh
```

Example output:
```
Agent                                    Enabled   Max  Status
─────────────────────────────────────────────────────────────────
agents/dispatcher/agent.yaml                   4    10  ✅ OK
agents/orchestrator/agent.yaml                 7    10  ✅ OK
agents/specialists/forge-code-agent/...        8    10  ✅ OK
agents/specialists/recon-research-agent/...    7    10  ✅ OK
agents/specialists/scribe-docs-agent/...       6    10  ✅ OK
agents/specialists/deployer-devops-agent/...   8    10  ✅ OK
─────────────────────────────────────────────────────────────────

✅ All agents within tool limits.
```

Exits `0` if clean, `1` if violations.

### JSON Report

```bash
./scripts/mcp-audit.sh --report
```

Useful for piping into monitoring systems or dashboards:

```bash
./scripts/mcp-audit.sh --report | jq '.violations'
```

### Auto-Fix Mode

```bash
./scripts/mcp-audit.sh --fix
```

Automatically sets `enabled: false` on tools beyond the limit (starting from the bottom of the list). Always review the diff before committing:

```bash
./scripts/mcp-audit.sh --fix
git diff agents/
```

### Pre-commit Hook (Optional)

Add to `.git/hooks/pre-commit`:

```bash
#!/usr/bin/env bash
if git diff --cached --name-only | grep -qE '(agent|tools)\.yaml$'; then
  echo "Running MCP audit..."
  ./scripts/mcp-audit.sh || {
    echo "❌ MCP audit failed. Fix violations or run ./scripts/mcp-audit.sh --fix"
    exit 1
  }
fi
```

---

## 6. Cost Math

### Per-Request Token Cost

Each tool definition injected into context costs approximately:

| Component | Tokens |
|-----------|--------|
| Tool name + type | ~20 |
| Description (verbose) | ~50–200 |
| Parameter schema | ~100–250 |
| **Total per tool** | **~200–500** |

Use **350 tokens** as a conservative average.

### Monthly Cost Projection (claude-3-5-sonnet)

Pricing: ~$3.00 per million input tokens

| Agents | Requests/day | Tools each | Daily overhead tokens | Monthly cost of tool overhead |
|--------|-------------|------------|----------------------|-------------------------------|
| 5      | 500         | 10         | 8,750,000            | **~$787**                     |
| 5      | 500         | 20         | 17,500,000           | **~$1,575**                   |
| 5      | 500         | 5          | 4,375,000            | **~$394**                     |

**Cutting from 20→10 tools saves ~$800/month** at 500 req/day across 5 agents.

### The Real Cost of "Just in Case" Tools

A single unused tool that's kept enabled:
- 500 req/day × 350 tokens × $3/1M tokens = **~$0.53/day = ~$16/month per tool**
- Across 10 agents: **~$160/month in pure waste**

---

## 7. FAQ

**Q: Can I set `max_enabled` higher than 10 for a specific agent?**

Yes, but you must document the justification as a comment in `agent.yaml` and get it reviewed in PR. The CI audit uses `max_enabled` from the yaml, so setting it to `15` will allow 15 tools — but reviewers will see it.

**Q: Do disabled tools still cost tokens?**

No. Tools with `enabled: false` (or not loaded in `.mcp.json`) are not injected into context.

**Q: What about tools.yaml files?**

The audit script scans both `agent.yaml` and `tools.yaml`. If your agent uses a separate `tools.yaml`, apply the same discipline there.

**Q: My agent genuinely needs 12 tools. What do I do?**

1. Audit your tool list using the category framework above
2. Check if any tools overlap in capability
3. Check if any tool should be in a sub-agent instead
4. If still necessary, set `max_enabled: 12` with a comment explaining why
5. The PR reviewer will validate your reasoning

**Q: How often should I review tool counts?**

At minimum `audit_frequency` (default weekly). Also review whenever:
- Adding a new tool
- Changing agent scope
- Costs spike unexpectedly
- A new MCP tool server is integrated org-wide
