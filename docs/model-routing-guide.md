# Model Routing Guide

> **Goal:** ≥40% of tasks on Haiku · ≤30% on Sonnet · ≤30% on Opus  
> **Why it matters:** Right model for the right job — quality where it counts, cost savings where it doesn't.

---

## ⚠️ CORRECTED Routing (Updated 2026-03-01)

The routing was previously incorrect. **Opus is for code; Sonnet is for planning.**

**Correct model assignments:**

| Model | Role | Rationale |
|-------|------|-----------|
| **Haiku** | Triage & simple tasks | Fast, cheap, structured lookups |
| **Sonnet** | Planning & strategy | Architecture decisions need reasoning, not raw code power |
| **Opus** | Code & complex problem-solving | Correctness matters most — use the best model |

---

## Cost Table

| Model | Name | Cost / 1M tokens | Relative cost | Best for |
|-------|------|-----------------|--------------|---------|
| **Haiku** | `claude-haiku-4-5` | $0.80 | 1× (baseline) | Fast triage, classification, status checks |
| **Sonnet** | `claude-sonnet-4-6` | $3.00 | 3.75× | Planning, strategy, architecture design |
| **Opus** | `claude-opus-4-5` | $15.00 | 18.75× | Code implementation, debugging, complex problem-solving |

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
Use override   Is context > 50,000 tokens?
model          │
               │ YES → OPUS  (code/complex work with large context)
               │
               │ NO
               ▼
         What is the task type?

   ┌──────────────────────────────────────────────────────┐
   │  HAIKU tasks (triage / simple / structured)           │
   │  triage · summary · format · lookup · notify          │
   │  classify · echo · status_check · board_update        │
   └──────────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────────┐
   │  SONNET tasks (planning / strategy / architecture)    │
   │  planning · strategy · architecture_design            │
   │  roadmapping · design_review · sprint_planning        │
   │  ticket_breakdown · documentation                     │
   └──────────────────────────────────────────────────────┘
   ┌──────────────────────────────────────────────────────┐
   │  OPUS tasks (code / complex problem-solving)          │
   │  implementation · code_review · debugging             │
   │  refactoring · test_writing · security_audit          │
   │  complex_debugging · novel_problem · analysis         │
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

### 🟢 Haiku — Triage & Simple Tasks (~40% of tasks)

**Use when:** the task is well-defined, context is small, output is structured or short. No reasoning required.

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

### 🟡 Sonnet — Planning & Strategy (~30% of tasks)

**Use when:** the task requires structured thinking about *what* to build or *how* to approach a problem — but not yet writing the actual code.

| Task | Example prompt |
|------|---------------|
| `planning` | "Break this epic into 5 actionable tickets with acceptance criteria" |
| `strategy` | "Given our roadmap, what's the 6-month technical strategy?" |
| `architecture_design` | "Design the data model for multi-tenant workspaces" |
| `roadmapping` | "Prioritize these 20 backlog items for Q2" |
| `sprint_planning` | "Plan this 2-week sprint given our velocity" |
| `design_review` | "Review this architecture diagram for gaps" |
| `documentation` | "Write API docs for these 10 endpoints" |

**Rationale:** Planning is about reasoning and trade-offs — Sonnet handles this well. Save Opus budget for *implementation*, where correctness matters most.

**Cost at 300 req/day** (avg 3,000 tokens/req): ~$2.70/day → **$81/month**

---

### 🔴 Opus — Code & Complex Problem-Solving (~30% of tasks)

**Use when:** writing, reviewing, or debugging actual code — or solving genuinely hard problems where quality is non-negotiable.

| Task | Example prompt |
|------|---------------|
| `implementation` | "Implement the WebSocket reconnect logic per spec" |
| `code_review` | "Review this 200-line PR for correctness, edge cases, and security" |
| `debugging` | "Why does this function return null on edge case X?" |
| `refactoring` | "Refactor this class to use the repository pattern" |
| `test_writing` | "Write unit tests for the auth module (aim for 80% coverage)" |
| `complex_debugging` | "This race condition manifests across 3 microservices — debug it" |
| `security_audit` | "Audit our MCP tool surface for privilege escalation vectors" |
| `analysis` | "Analyze these benchmark results and explain the performance regression" |

**Rationale:** Code bugs cost real money and user trust. Opus's superior reasoning prevents subtle bugs that Sonnet would introduce — especially in edge cases and security-sensitive code.

**Cost at 300 req/day** (avg 5,000 tokens/req): ~$22.50/day → **$675/month**

> 💡 **Note:** Yes, Opus for code is more expensive than Sonnet. That's intentional. A single production bug can cost 10× more than the saved inference cost.

---

## How to Add Routing to Your Agent

### 1. Reference the routing config in `agent.yaml`

```yaml
model:
  provider: "anthropic"
  name: "claude-opus-4-5"          # default for code agents
  routing_enabled: true
  routing_config: "../../templates/model-routing.yaml"
  routing_rationale: "Opus for code; Sonnet for planning; Haiku for triage"
```

### 2. Add `cost_controls` at the end of `agent.yaml`

```yaml
cost_controls:
  track_model_usage: true
  alert_if_opus_percent_exceeds: 40
  monthly_budget_usd: 800
  preferred_model_target:
    haiku_target_percent: 40
    sonnet_target_percent: 30
    opus_target_percent: 30
```

### 3. Use the CLI router in your scripts

```bash
# Triage → Haiku
MODEL=$(./scripts/route-model.sh --task-type triage)
# → claude-haiku-4-5

# Planning → Sonnet
MODEL=$(./scripts/route-model.sh --task-type planning)
# → claude-sonnet-4-6

# Implementation → Opus
MODEL=$(./scripts/route-model.sh --task-type implementation)
# → claude-opus-4-5

# With agent override
MODEL=$(./scripts/route-model.sh --agent dispatcher --task-type analysis)
# → claude-haiku-4-5  (dispatcher always uses Haiku)

# With explanation
./scripts/route-model.sh --task-type implementation --explain
# [explain] Task type  : implementation → opus
# [explain] Token count: 0 → haiku
# [explain] Decision   : Task type 'implementation' maps to opus (code quality)
# [explain] Model      : claude-opus-4-5
# claude-opus-4-5
```

---

## Anti-Patterns ❌

| Anti-pattern | Why it's wrong | Fix |
|-------------|----------------|-----|
| Using Sonnet for code implementation | Correctness matters most — Sonnet misses edge cases | Use Opus |
| Using Opus for sprint planning | Overkill; Sonnet handles strategic reasoning fine | Use Sonnet |
| Using Opus for JSON formatting | 19× overpay for a deterministic task | Use Haiku |
| Using Haiku for architecture design | Insufficient reasoning depth; bad output | Use Sonnet |
| Using Haiku for coding tasks | Insufficient capability for correctness | Use Opus |
| Using Sonnet as "safe default" for everything | Misses the code-quality benefit of Opus | Route per task type |
| Ignoring token count in routing | A "summary" with 60k context needs escalation | Always factor context size |

---

## Quick Reference Card

```
Task type            → Model    Why
─────────────────────────────────────────────────────────
triage               → Haiku    classify only
summary              → Haiku    structured output
format               → Haiku    deterministic transform
status_check         → Haiku    yes/no answer
board_update         → Haiku    structured action
planning             → Sonnet   strategy + trade-offs
architecture_design  → Sonnet   design reasoning
roadmapping          → Sonnet   prioritization logic
sprint_planning      → Sonnet   structured planning
documentation        → Sonnet   long-form, structured
implementation       → Opus     code correctness matters
code_review          → Opus     catch edge cases + bugs
debugging            → Opus     deep reasoning required
refactoring          → Opus     correctness-critical
test_writing         → Opus     thoroughness required
security_audit       → Opus     adversarial reasoning
complex_debugging    → Opus     cross-system, no pattern
```

---

## Previous (Incorrect) Routing — For Reference

The old guide incorrectly assigned Sonnet to code tasks and Opus to architecture/planning. This was wrong because:

1. **Code quality is the highest-stakes output** — bugs in production cost more than inference savings
2. **Planning is reasoning, not raw intelligence** — Sonnet handles strategic reasoning well
3. **Opus budget was wasted on docs and planning** — which are low-correctness-risk tasks

---

*Maintained by JarvisXomware · Last updated 2026-03-01*
