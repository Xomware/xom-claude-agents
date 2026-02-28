# Cost-Router Agent

## Identity

**Name:** cost-router  
**Role:** LLM call interceptor and model selector  
**Model:** claude-3-5-haiku (the router itself must be cheap)  
**Latency SLA:** <200ms routing decision

---

## Purpose

The cost-router sits between every agent and the Anthropic API. Before any LLM call is dispatched, the cost-router:

1. Scores the request complexity (0–10)
2. Selects the appropriate model tier (Haiku / Sonnet / Opus)
3. Checks session budget remaining
4. Checks cache for an existing response
5. Approves, modifies, or rejects the call

This agent prevents accidental Opus usage for trivial tasks and enforces budget limits across all sessions.

---

## Responsibilities

### 1. Complexity Scoring

Analyze incoming requests and assign a complexity score:

```yaml
complexity_scoring:
  inputs:
    - task_description: string
    - context_length: integer      # tokens of context provided
    - output_length_hint: string   # "short" | "medium" | "long"
    - task_type: string            # "lookup" | "code" | "analysis" | "architecture"
    - criticality: string          # "low" | "medium" | "high" | "critical"

  output:
    score: integer  # 0–10
    rationale: string
    recommended_model: "haiku" | "sonnet" | "opus"
```

### 2. Model Selection

Apply routing rules from `routing-rules.md`. Override logic:

- `criticality: critical` → **minimum Sonnet** (never Haiku for critical tasks)
- `task_type: architecture` → **minimum Opus**
- `context_length > 100_000` → upgrade one tier (long contexts need more reasoning)
- Explicit model override in agent config → honor it, but log the override

### 3. Budget Enforcement

```yaml
budget_enforcement:
  per_session_limit: "$0.50"
  per_call_limit: "$0.25"
  on_exceed:
    per_call: downgrade_model   # try cheaper model first
    per_session: reject_with_error
  warn_at: 70%  # of session limit
```

### 4. Cache Lookup

Before dispatching:
1. Generate cache key from `(model, system_prompt_hash, user_prompt_hash)`
2. Check cache store (Redis or in-memory TTL map)
3. On hit: return cached response, log cache hit, charge $0
4. On miss: dispatch, cache response with appropriate TTL

### 5. Telemetry

Emit for every call:

```json
{
  "event": "llm_call",
  "session_id": "...",
  "model_requested": "opus",
  "model_used": "sonnet",
  "complexity_score": 6,
  "was_downgraded": true,
  "cache_hit": false,
  "input_tokens": 1240,
  "output_tokens": 380,
  "cost_usd": 0.0472,
  "session_total_usd": 0.183,
  "duration_ms": 2100
}
```

---

## Agent Interface

```typescript
interface CostRouterRequest {
  taskDescription: string;
  systemPrompt?: string;
  userPrompt: string;
  contextTokens?: number;
  taskType: 'lookup' | 'code' | 'analysis' | 'architecture' | 'other';
  criticality: 'low' | 'medium' | 'high' | 'critical';
  requestedModel?: 'haiku' | 'sonnet' | 'opus';  // optional override
  sessionId: string;
  budgetLimitUsd?: number;  // override session default
}

interface CostRouterResponse {
  approved: boolean;
  model: 'haiku' | 'sonnet' | 'opus';
  wasDowngraded: boolean;
  wasUpgraded: boolean;
  cacheHit: boolean;
  estimatedCostUsd: number;
  sessionRemainingUsd: number;
  rejectReason?: string;  // if approved = false
}
```

---

## Configuration

```yaml
# cost-router config (set in agent deployment)
cost_router:
  enabled: true
  default_session_budget_usd: 0.50
  cache:
    enabled: true
    backend: "redis"          # or "memory"
    default_ttl_seconds: 3600
  telemetry:
    enabled: true
    log_level: "info"
    emit_to: "stdout"         # or "datadog" | "cloudwatch"
  routing:
    rules_file: "routing-rules.md"
    allow_model_override: true  # agents can request specific model
    log_overrides: true
```

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Budget exceeded (per-call) | Try downgrading model; if still over budget, reject |
| Budget exceeded (per-session) | Reject all calls; return `approved: false` |
| Cache backend unavailable | Log warning, proceed without cache |
| Routing rule parse error | Default to Sonnet, log error |
| Model unavailable (API error) | Try next tier up; if all fail, propagate error |

---

## Monitoring Dashboards

Track these metrics in Datadog/CloudWatch/Grafana:

- `cost_router.session_cost_usd` (histogram by session)
- `cost_router.model_distribution` (% haiku/sonnet/opus)
- `cost_router.cache_hit_rate` (%)
- `cost_router.downgrades_total` (count)
- `cost_router.budget_exceeded_total` (count)
- `cost_router.p99_latency_ms` (routing overhead)

**Target SLOs:**
- Haiku usage ≥ 50%
- Cache hit rate ≥ 20%
- Routing overhead < 200ms p99
- Budget exceeded events < 1% of sessions
