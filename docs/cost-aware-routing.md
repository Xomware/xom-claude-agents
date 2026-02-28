# Cost-Aware LLM Routing

## Overview

Not every task needs Opus. Routing LLM calls to the cheapest capable model is one of the highest-leverage cost optimizations available. This document defines the routing decision tree, model tiers, cost tracking approach, and caching strategy used across all Xomware agents.

**Target distribution:** ~60% Haiku · ~30% Sonnet · ~10% Opus

---

## Model Tiers

| Tier | Model | Cost (approx) | Latency | Use For |
|------|-------|---------------|---------|---------|
| **Haiku** | claude-3-5-haiku | ~$0.001/1K tokens | <1s | Lookup, format, triage, status, simple Q&A |
| **Sonnet** | claude-sonnet-4 | ~$0.015/1K tokens | 2–5s | Code, analysis, research, multi-step reasoning |
| **Opus** | claude-opus-4 | ~$0.075/1K tokens | 5–30s | Architecture, critical decisions, complex planning |

Opus costs 75× more than Haiku. Routing a lookup from Opus to Haiku saves $0.074 per call. At scale, this compounds dramatically.

---

## Routing Decision Tree

```
Is the task simple? (lookup, status check, format, yes/no, short summary)
  └── YES → Haiku
  └── NO ↓

Does the task require code generation, code review, or multi-step reasoning?
  └── YES → Sonnet (unless complexity score > 8)
  └── NO ↓

Does the task require architecture decisions, critical security review,
long-horizon planning, or synthesis of ambiguous/conflicting information?
  └── YES → Opus
  └── NO → Sonnet (default)
```

### Complexity Score (0–10)

Assign a complexity score before routing:

| Score | Description |
|-------|-------------|
| 0–2 | Single-fact lookup, status check, reformatting |
| 3–4 | Short code snippets, simple explanations, routing decisions |
| 5–6 | Multi-file code changes, debugging, research summaries |
| 7–8 | System design, security audits, complex refactors |
| 9–10 | Architecture decisions, cross-system integration plans, critical incident RCA |

- Score 0–3 → **Haiku**
- Score 4–7 → **Sonnet**
- Score 8–10 → **Opus**

---

## Examples by Category

### Always Haiku

```yaml
- "What's the current status of the deployment?"
- "Format this JSON as a markdown table"
- "Is PR #42 open or closed?"
- "Summarize this error message in one line"
- "Which agent should handle this request?"
- "Translate this shell command to PowerShell"
```

### Always Sonnet

```yaml
- "Implement OAuth2 token refresh in the auth module"
- "Debug this race condition in the job queue"
- "Review this PR for obvious bugs and style issues"
- "Research which job queue library to use for Node.js"
- "Write tests for the payment service"
- "Refactor this module to use dependency injection"
```

### Always Opus

```yaml
- "Design the database schema for a multi-tenant SaaS platform"
- "Review our security model for the API gateway — this is customer-facing"
- "We have 3 conflicting approaches to distributed locking — evaluate and recommend"
- "Perform RCA on this P0 incident with 12 contributing factors"
- "Design our event-driven architecture migration strategy"
```

---

## Cost Tracking

### Per-Session Budget

Each agent session should track:

```yaml
session_budget:
  limit_usd: 0.50        # hard limit per session
  warn_at_usd: 0.30      # log warning when crossed
  current_spend_usd: 0.00
  token_counts:
    haiku_in: 0
    haiku_out: 0
    sonnet_in: 0
    sonnet_out: 0
    opus_in: 0
    opus_out: 0
```

### Cost Estimation Formula

```
cost = (input_tokens / 1000 * input_rate) + (output_tokens / 1000 * output_rate)
```

Approximate rates (verify against current Anthropic pricing):

| Model | Input $/1K | Output $/1K |
|-------|-----------|------------|
| Haiku | $0.00080 | $0.00400 |
| Sonnet | $0.01500 | $0.07500 |
| Opus | $0.07500 | $0.37500 |

### Budget Enforcement

```python
def check_budget(session: Session, estimated_cost: float) -> bool:
    if session.current_spend + estimated_cost > session.limit_usd:
        raise BudgetExceededError(
            f"Estimated cost ${estimated_cost:.4f} would exceed session budget "
            f"(${session.limit_usd}). Current spend: ${session.current_spend:.4f}."
        )
    return True
```

---

## Caching Strategy

### What to Cache

| Content Type | Cache TTL | Notes |
|--------------|-----------|-------|
| GitHub repo metadata | 5 min | Changes infrequently |
| npm/PyPI package info | 1 hour | Very stable |
| Static document summaries | 24 hours | Regenerate on change |
| Code review of unchanged diff | Permanent | Hash the diff |
| Research reports | 7 days | Add staleness flag |

### Cache Key Design

```python
def cache_key(model: str, prompt: str, system: str = "") -> str:
    content = f"{model}|{system}|{prompt}"
    return hashlib.sha256(content.encode()).hexdigest()
```

### Cache Hit Savings

A cached Opus call that cost $0.10 on first run saves $0.10 on every subsequent hit. For repeated research tasks or common code patterns, caching can reduce effective cost by 50–80%.

---

## Escalation Protocol

If a Haiku or Sonnet response is insufficient:

1. **Haiku → Sonnet escalation**: Triggered when response contains uncertainty markers ("I'm not sure", "this may not be accurate", "you should verify") OR output is under 50 tokens for a complex request
2. **Sonnet → Opus escalation**: Triggered when confidence is low AND the task is flagged as critical (security, production, architecture)
3. **Human escalation**: Always available; triggered when any model expresses inability to complete the task

---

## Implementation Reference

See `agents/cost-router/` for the cost-router agent implementation:
- `agents/cost-router/AGENT.md` — Agent definition and responsibilities
- `agents/cost-router/routing-rules.md` — Complete routing rule set with examples
