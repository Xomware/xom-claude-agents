#!/usr/bin/env bash
# route-model.sh — CLI model router for Xomware Claude Agents
# Reads templates/model-routing.yaml and outputs the model name to use.
#
# Usage:
#   ./scripts/route-model.sh --task-type triage
#   ./scripts/route-model.sh --task-type implementation --context-tokens 5000
#   ./scripts/route-model.sh --task-type architecture_design --explain
#   ./scripts/route-model.sh --agent dispatcher --task-type triage --explain
#
# Outputs the model name (e.g., claude-haiku-4-5) to stdout.
# Use --explain for human-readable reasoning.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROUTING_YAML="${REPO_ROOT}/templates/model-routing.yaml"

# Model names (kept in sync with model-routing.yaml)
MODEL_HAIKU="claude-haiku-4-5"
MODEL_SONNET="claude-sonnet-4-6"
MODEL_OPUS="claude-opus-4-5"

# Defaults
TASK_TYPE=""
CONTEXT_TOKENS=0
AGENT=""
EXPLAIN=false

# ── Parse args ────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") --task-type <type> [OPTIONS]

Options:
  --task-type <type>        Task type (required). Examples:
                              haiku:  triage, summary, format, lookup, notify,
                                      classify, echo, status_check, board_update
                              sonnet: code_review, implementation, debugging,
                                      analysis, planning, documentation,
                                      refactoring, test_writing
                              opus:   architecture_design, security_audit,
                                      complex_debugging, novel_problem,
                                      strategic_planning
  --context-tokens <n>      Approximate input token count (default: 0)
  --agent <name>            Agent name for agent-specific overrides
                              (dispatcher, orchestrator, forge-code,
                               recon-research, scribe-docs, deployer-devops)
  --explain                 Print routing reasoning to stderr
  -h, --help                Show this help

Examples:
  $(basename "$0") --task-type triage
  $(basename "$0") --task-type implementation --context-tokens 8000
  $(basename "$0") --task-type architecture_design --explain
  $(basename "$0") --agent dispatcher --task-type triage --explain
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-type)        TASK_TYPE="$2";       shift 2 ;;
    --context-tokens)   CONTEXT_TOKENS="$2";  shift 2 ;;
    --agent)            AGENT="$2";           shift 2 ;;
    --explain)          EXPLAIN=true;         shift   ;;
    -h|--help)          usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$TASK_TYPE" ]]; then
  echo "Error: --task-type is required" >&2
  usage
  exit 1
fi

# ── Agent-level override (highest priority) ───────────────────────────────────
#    dispatcher → always haiku, never opus
#    scribe-docs → default haiku
apply_agent_override() {
  local agent="$1"
  case "$agent" in
    dispatcher)
      # dispatcher is always haiku; opus is explicitly forbidden
      if [[ "$TASK_TYPE" == "architecture_design" || "$TASK_TYPE" == "security_audit" || \
            "$TASK_TYPE" == "complex_debugging"   || "$TASK_TYPE" == "novel_problem"   || \
            "$TASK_TYPE" == "strategic_planning" ]]; then
        # Even for "heavy" types, dispatcher should not use opus — escalate to orchestrator instead
        echo "$MODEL_SONNET"
        [[ "$EXPLAIN" == true ]] && echo "[explain] Agent override: dispatcher never uses Opus; escalate complex tasks to orchestrator instead. Routing to Sonnet." >&2
      else
        echo "$MODEL_HAIKU"
        [[ "$EXPLAIN" == true ]] && echo "[explain] Agent override: dispatcher default is Haiku (all triage is fast classification)." >&2
      fi
      return 0
      ;;
    scribe-docs)
      # scribe defaults haiku; escalates for heavy analysis
      if [[ "$TASK_TYPE" == "analysis" || "$TASK_TYPE" == "architecture_design" || \
            "$TASK_TYPE" == "security_audit" ]]; then
        echo "$MODEL_SONNET"
        [[ "$EXPLAIN" == true ]] && echo "[explain] Agent override: scribe-docs uses Sonnet for analysis tasks (default is Haiku)." >&2
        return 0
      fi
      ;;
  esac
  return 1  # No override applied
}

# ── Token-count escalation ────────────────────────────────────────────────────
#    >50k tokens → Opus territory regardless of task type
#    >2k tokens  → at least Sonnet
token_tier() {
  local tokens="$1"
  if   (( tokens > 50000 )); then echo "opus"
  elif (( tokens > 2000  )); then echo "sonnet"
  else                            echo "haiku"
  fi
}

# ── Task-type → model tier ────────────────────────────────────────────────────
task_tier() {
  local task="$1"
  case "$task" in
    # Haiku tasks
    triage|summary|format|lookup|notify|classify|echo|status_check|board_update)
      echo "haiku" ;;
    # Sonnet tasks
    code_review|implementation|debugging|analysis|planning|documentation|refactoring|test_writing)
      echo "sonnet" ;;
    # Opus tasks
    architecture_design|security_audit|complex_debugging|novel_problem|strategic_planning)
      echo "opus" ;;
    *)
      # Unknown task type → default to Sonnet (safe middle ground)
      echo "sonnet" ;;
  esac
}

tier_to_model() {
  case "$1" in
    haiku)  echo "$MODEL_HAIKU"  ;;
    sonnet) echo "$MODEL_SONNET" ;;
    opus)   echo "$MODEL_OPUS"   ;;
  esac
}

# ── Main routing logic ────────────────────────────────────────────────────────

# 1. Agent override (returns early if applicable)
if [[ -n "$AGENT" ]]; then
  if apply_agent_override "$AGENT"; then
    exit 0
  fi
fi

# 2. Determine tiers from task type and token count
TASK_TIER="$(task_tier "$TASK_TYPE")"
TOKEN_TIER="$(token_tier "$CONTEXT_TOKENS")"

# 3. Pick the higher tier (most capable model wins when signals conflict)
tier_rank() {
  case "$1" in haiku) echo 1;; sonnet) echo 2;; opus) echo 3;; esac
}

TASK_RANK="$(tier_rank "$TASK_TIER")"
TOKEN_RANK="$(tier_rank "$TOKEN_TIER")"

if (( TOKEN_RANK > TASK_RANK )); then
  FINAL_TIER="$TOKEN_TIER"
  REASON="Token count (${CONTEXT_TOKENS}) escalated from ${TASK_TIER} → ${TOKEN_TIER}"
else
  FINAL_TIER="$TASK_TIER"
  REASON="Task type '${TASK_TYPE}' maps to ${TASK_TIER}"
fi

MODEL="$(tier_to_model "$FINAL_TIER")"

# 4. Print reasoning if requested
if [[ "$EXPLAIN" == true ]]; then
  echo "[explain] Task type  : ${TASK_TYPE} → ${TASK_TIER}" >&2
  echo "[explain] Token count: ${CONTEXT_TOKENS} → ${TOKEN_TIER}" >&2
  echo "[explain] Decision   : ${REASON}" >&2
  echo "[explain] Model      : ${MODEL}" >&2
fi

# 5. Output the model name
echo "$MODEL"
