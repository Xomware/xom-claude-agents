# Routing Rules

Complete rule set for the cost-router agent. Rules are evaluated in order; first match wins.

---

## Rule Structure

```yaml
rule:
  name: string
  conditions:
    - field: <field>
      operator: <eq|contains|gte|lte|in|matches>
      value: <value>
  model: haiku | sonnet | opus
  rationale: string
```

---

## Rules (Priority Order)

### 1. Hard Overrides (highest priority)

```yaml
- name: "explicit-model-override"
  conditions:
    - field: requestedModel
      operator: in
      value: [haiku, sonnet, opus]
    - field: criticality
      operator: neq
      value: critical
  model: <requestedModel>
  rationale: "Caller explicitly requested a model; honor unless critical"

- name: "critical-minimum-sonnet"
  conditions:
    - field: criticality
      operator: eq
      value: critical
    - field: requestedModel
      operator: eq
      value: haiku
  model: sonnet
  rationale: "Never use Haiku for critical tasks — upgrade to Sonnet minimum"

- name: "architecture-requires-opus"
  conditions:
    - field: taskType
      operator: eq
      value: architecture
  model: opus
  rationale: "Architecture decisions need Opus reasoning depth"
```

---

### 2. Task Type Rules

```yaml
- name: "lookup-to-haiku"
  conditions:
    - field: taskType
      operator: eq
      value: lookup
  model: haiku
  rationale: "Simple lookups: status checks, single-fact queries, yes/no"

- name: "code-to-sonnet"
  conditions:
    - field: taskType
      operator: eq
      value: code
  model: sonnet
  rationale: "Code generation and review needs Sonnet's coding capability"

- name: "analysis-to-sonnet"
  conditions:
    - field: taskType
      operator: eq
      value: analysis
  model: sonnet
  rationale: "Analysis and research tasks need multi-step reasoning"

- name: "other-low-complexity-to-haiku"
  conditions:
    - field: taskType
      operator: eq
      value: other
    - field: complexityScore
      operator: lte
      value: 3
  model: haiku
  rationale: "Low-complexity 'other' tasks don't need Sonnet"
```

---

### 3. Complexity Score Rules

```yaml
- name: "score-0-3-haiku"
  conditions:
    - field: complexityScore
      operator: lte
      value: 3
    - field: criticality
      operator: in
      value: [low, medium]
  model: haiku
  rationale: "Low complexity, non-critical: Haiku is sufficient"

- name: "score-4-7-sonnet"
  conditions:
    - field: complexityScore
      operator: gte
      value: 4
    - field: complexityScore
      operator: lte
      value: 7
  model: sonnet
  rationale: "Medium complexity: Sonnet handles code, research, debugging"

- name: "score-8-10-opus"
  conditions:
    - field: complexityScore
      operator: gte
      value: 8
  model: opus
  rationale: "High complexity: Opus for architecture, critical decisions"
```

---

### 4. Context Length Rules

```yaml
- name: "long-context-upgrade-haiku-to-sonnet"
  conditions:
    - field: contextTokens
      operator: gte
      value: 50000
    - field: model
      operator: eq
      value: haiku
  model: sonnet
  rationale: "Very long contexts need better reasoning; upgrade Haiku to Sonnet"

- name: "very-long-context-upgrade-sonnet-to-opus"
  conditions:
    - field: contextTokens
      operator: gte
      value: 150000
    - field: model
      operator: eq
      value: sonnet
    - field: criticality
      operator: in
      value: [high, critical]
  model: opus
  rationale: "Critical tasks with 150K+ context need Opus for reliable synthesis"
```

---

### 5. Keyword Pattern Rules

Applied to `taskDescription` (case-insensitive regex):

```yaml
haiku_patterns:
  - "status (check|of|update)"
  - "what is (the )?(current )?(status|state)"
  - "is .* (open|closed|running|stopped|passing|failing)"
  - "format (this|the) (json|yaml|csv|markdown|table)"
  - "which (agent|model|workflow) should"
  - "summarize .{0,50} (in one line|briefly|quickly)"
  - "translate (this|the) (command|script|snippet)"
  - "list (all |the )?(current )?(open |active )?(issues|prs|deployments)"
  - "ping|health.?check"

sonnet_patterns:
  - "implement|build|create|add|write (a |the )?(\w+ )?(function|class|module|service|api|endpoint)"
  - "(debug|fix|resolve|diagnose) (this |the )?(bug|error|issue|problem|race condition)"
  - "review (this |the )?(pr|code|diff|change)"
  - "refactor|optimize|improve"
  - "write (tests|specs|unit tests|integration tests)"
  - "research (which|the best|what|how)"
  - "analyze|analyse|evaluate"
  - "explain (how|why|what)"

opus_patterns:
  - "design (the |a )?(system|architecture|schema|database|api|platform)"
  - "security (audit|review|assessment) .*(critical|production|customer)"
  - "(evaluate|compare|choose between) .* (approach|option|strategy|architecture)"
  - "root cause analysis|rca|postmortem"
  - "migration (plan|strategy|path)"
  - "multi.?tenant|distributed (system|architecture|locking)"
  - "critical (decision|review|assessment)"
  - "(long.?term|long.?horizon) (plan|strategy|roadmap)"
```

---

## Examples

### Routed to Haiku ✅ (cheap)

| Request | Score | Reason |
|---------|-------|--------|
| "Is the staging deployment passing?" | 1 | Lookup, low criticality |
| "Format this JSON as a markdown table" | 1 | Format task |
| "Which agent should handle this iMessage?" | 2 | Routing decision |
| "Summarize this error in one line" | 2 | Short output, trivial |
| "List all open PRs in xom-claude-agents" | 2 | Lookup |

### Routed to Sonnet ✅ (balanced)

| Request | Score | Reason |
|---------|-------|--------|
| "Add OAuth2 to the auth module" | 5 | Code, medium complexity |
| "Debug this race condition in the job queue" | 6 | Code + analysis |
| "Research which job queue library to use" | 5 | Analysis, medium |
| "Review PR #42 for bugs" | 4 | Code review, non-critical |
| "Write tests for the payment service" | 5 | Code |

### Routed to Opus ✅ (justified)

| Request | Score | Reason |
|---------|-------|--------|
| "Design the multi-tenant database schema" | 9 | Architecture |
| "Evaluate 3 distributed locking approaches" | 8 | High complexity, critical decision |
| "Security audit of the API gateway (customer-facing)" | 8 | Critical, security |
| "RCA for the P0 incident with 12 factors" | 10 | Critical, high complexity |
| "Design our event-driven architecture migration" | 9 | Architecture, long-horizon |

---

## Default Rule (fallback)

```yaml
- name: "default-sonnet"
  conditions: []  # always matches
  model: sonnet
  rationale: "When no rule matches, Sonnet is the safe default — better than Opus overkill or Haiku under-power"
```
