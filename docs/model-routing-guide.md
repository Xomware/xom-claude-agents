# Model Routing Guide

> **Goal:** ≥40% of tasks on Haiku · ≤50% on Sonnet · ≤10% on Opus  
> **Why it matters:** Haiku is 10x cheaper than Sonnet, 19x cheaper than Opus.

---

## Cost Table

| Model | Name | Cost / 1M tokens | Relative cost | Best for |
|-------|------|-----------------|--------------|---------|
| **Haiku** | `claude-haiku-4-5` | $0.80 | 1× (baseline) | Fast, simple, structured tasks |
| **Sonnet** | `claude-sonnet-4-6` | $3.00 | 3.75× | Standard coding and analysis |
| **Opus** | `claude-opus-4-5` | $15.00 | 18.75× | Deep reasoning, architecture |

---

## Decision Flowchart

```
START: New task arrives
         │
         ▼
Is there an AGENT-LEVEL OVERRIDE?
  (dispatcher → always Haiku; see agent_defaults in model-routing.yaml)
         │
    YES  │  NO
   ──────┴──────
   │             │
   ▼             ▼
Use override   Is input context > 50,000 tokens?
model          │
               │ YES → OPUS  (context too large for lighter models)
               │
               │ NO
               ▼
         Is input context > 2,000 tokens?
               │
               │ YES → at least SONNET
               │
               │ NO
               ▼
         What is the task type?

   ┌──────────────────────────────────────────────────────┐
   │  HAIKU tasks (simple/structured)                      │
   │  triage · summary · format · lookup · notify          │
   │  classify · echo · status_check · board_update        │
   └──────────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────────┐
   │  SONNET tasks (standard complex work)                 │
   │  code_review · implementation · debugging · analysis  │
   │  planning · documentation · refactoring · test_writing│
   └──────────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────────┐
   │  OPUS tasks (deep reasoning only)                     │
   │  architecture_design · security_audit                 │
   │  complex_debugging · novel_problem · strategic_planning│
   └──────────────────────────────────────────────────────┘

         │
         ▼
  If token-count tier > task-type tier → escalate to higher tier
         │
         ▼
       DONE: emit model name
```

---

## What Each Model Handles

### 🟢 Haiku — Fast & Cheap (~40% of tasks)

**Use when:** the task is well-defined, context is small, output is structured or short.

| Task | Example prompt |
|------|---------------|
| `triage` | "Classify this incoming message as bug/feature/question" |
| `summary` | "Summarize this 500-word Slack thread in 3 bullets" |
| `format` | "Convert this JSON to YAML" |
| `lookup` | "What's the status of deploy #42?" |
| `notify` | "Write a one-line Slack notification for this event" |
| `classify` | "Label this GitHub issue: bug, feature, or docs?" |
| `status_check` | "Is the staging environment healthy?" |
| `board_update` | "Move card XYZ to In Progress" |

**Cost at 1,000 req/day** (avg 500 tokens/req): ~$0.40/day → **$12/month**

---

### 🟡 Sonnet — Standard Work (~50% of tasks)

**Use when:** the task requires multi-step reasoning, code generation, or detailed analysis.

| Task | Example prompt |
|------|---------------|
| `code_review` | "Review this 200-line PR for correctness and style" |
| `implementation` | "Implement the WebSocket reconnect logic per spec" |
| `debugging` | "Why does this function return null on edge case X?" |
| `analysis` | "Analyze these benchmark results and explain the regression" |
| `planning` | "Break this epic into 5 actionable tickets" |
| `documentation` | "Write API docs for these 10 endpoints" |
| `refactoring` | "Refactor this class to use the repository pattern" |
| `test_writing` | "Write unit tests for the auth module (aim for 80% coverage)" |

**Cost at 1,000 req/day** (avg 2,000 tokens/req): ~$6/day → **$180/month**

---

### 🔴 Opus — Deep Reasoning Only (~10% of tasks)

**Use when:** the problem is genuinely novel, requires cross-system reasoning, or has very high stakes.

| Task | Example prompt |
|------|---------------|
| `architecture_design` | "Design the multi-agent orchestration layer for our platform" |
| `security_audit` | "Audit our entire MCP tool surface for privilege escalation vectors" |
| `complex_debugging` | "This race condition manifests across 3 microservices — debug it" |
| `novel_problem` | "We've never handled multi-tenant AI workloads — design the approach" |
| `strategic_planning` | "Given our roadmap, what's the 6-month technical strategy?" |

**Cost at 100 req/day** (avg 5,000 tokens/req): ~$7.50/day → **$225/month**

---

## How to Add Routing to Your Agent

### 1. Reference the routing config in `agent.yaml`

```yaml
model:
  provider: "anthropic"
  name: "claude-sonnet-4-6"      # default model
  routing_enabled: true
  routing_config: "../../templates/model-routing.yaml"
  routing_rationale: "Sonnet for standard tasks; Haiku for status checks"
```

### 2. Add `cost_controls` at the end of `agent.yaml`

```yaml
cost_controls:
  track_model_usage: true
  alert_if_opus_percent_exceeds: 15
  monthly_budget_usd: 50
  preferred_model_target:
    haiku_min_percent: 40
    sonnet_max_percent: 50
    opus_max_percent: 10
```

### 3. Use the CLI router in your scripts

```bash
# Get the model for a task type
MODEL=$(./scripts/route-model.sh --task-type triage)
# → claude-haiku-4-5

# With token count consideration
MODEL=$(./scripts/route-model.sh --task-type implementation --context-tokens 8000)
# → claude-sonnet-4-6

# With agent override
MODEL=$(./scripts/route-model.sh --agent dispatcher --task-type analysis)
# → claude-haiku-4-5  (dispatcher always uses Haiku)

# With explanation
./scripts/route-model.sh --task-type architecture_design --explain
# [explain] Task type  : architecture_design → opus
# [explain] Token count: 0 → haiku
# [explain] Decision   : Task type 'architecture_design' maps to opus
# [explain] Model      : claude-opus-4-5
# claude-opus-4-5
```

---

## Anti-Patterns ❌

| Anti-pattern | Why it's wrong | Fix |
|-------------|----------------|-----|
| Using Opus for JSON formatting | 19× overpay for a deterministic task | Use Haiku |
| Using Haiku for architecture design | Insufficient reasoning depth; bad output | Use Opus |
| Using Haiku for 10k-token codebase review | Context too large; Haiku max is ~2k | Use Sonnet |
| Using Sonnet for every single task | Overpaying for triage/status tasks | Route simple tasks to Haiku |
| Using Opus as the "safe default" | Budget killer; rarely justified | Opus only for truly novel problems |
| Ignoring token count in routing | A "summary" task with 60k context needs Opus | Always factor in context size |

---

## ROI Calculation

### Baseline (no routing — everything on Sonnet)
- 1,000 req/day × avg 2,000 tokens × $3.00/1M = **$6.00/day → $180/month**

### With routing (40% Haiku / 50% Sonnet / 10% Opus)

| Tier | Requests/day | Avg tokens | Cost/1M | Daily cost |
|------|-------------|-----------|---------|-----------|
| Haiku  | 400 | 800   | $0.80  | $0.26 |
| Sonnet | 500 | 2,000 | $3.00  | $3.00 |
| Opus   | 100 | 5,000 | $15.00 | $7.50 |
| **Total** | **1,000** | | | **$10.76/day** |

**Monthly: ~$323** — *but the Opus tasks were previously impossible on Sonnet, so we're not comparing apples-to-apples.*

### Apples-to-apples: routing simple tasks off Sonnet

| Scenario | Monthly cost |
|----------|-------------|
| No routing (all Sonnet, 1,000 req/day) | $180/month |
| With routing (40% to Haiku, no Opus) | ~$116/month |
| **Savings** | **~$64/month (36% reduction)** |

At 5,000 req/day, that savings becomes **~$320/month** — just from routing obvious Haiku tasks off Sonnet.

---

## Quick Reference Card

```
Task type          → Model    Why
─────────────────────────────────────────────────────
triage             → Haiku    classify only
summary            → Haiku    structured output
format             → Haiku    deterministic transform
status_check       → Haiku    yes/no answer
board_update       → Haiku    structured action
code_review        → Sonnet   multi-step reasoning
implementation     → Sonnet   code generation
debugging          → Sonnet   analysis + code
analysis           → Sonnet   detailed reasoning
planning           → Sonnet   structured output + reasoning
documentation      → Sonnet   long-form, detail
refactoring        → Sonnet   code understanding + output
architecture       → Opus     novel design, high stakes
security_audit     → Opus     adversarial reasoning
complex_debugging  → Opus     cross-system, no pattern
```

---

*Maintained by JarvisXomware · Last updated 2026-02-28*
