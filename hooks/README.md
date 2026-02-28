# Hooks Framework

Deterministic quality gates for the `xom-claude-agents` repo. These hooks run at key lifecycle points to catch issues before they reach `main`.

## Structure

```
hooks/
├── run-hooks.sh          # Master runner — use this
├── pre-pr/               # Gates before creating a PR
│   ├── lint.sh           # Trailing whitespace, TODO without ticket, debug statements
│   ├── test.sh           # Verifies test files exist alongside changed source files
│   ├── type-check.sh     # Runs tsc --noEmit if tsconfig.json present
│   └── docs-check.sh     # Ensures README.md or AGENTS.md exists and isn't a stub
├── pre-commit/           # Checks before git commit
│   ├── format.sh         # YAML formatting consistency, JSON pretty-print warning
│   └── secrets.sh        # Scans staged files for API keys, tokens, passwords
└── post-merge/           # Actions after merging
    ├── sync-board.sh     # Calls XomBoard sync script
    └── notify.sh         # Merge notifications (Slack/iMessage placeholder)
```

## Usage

### Run all hooks for a stage

```bash
# Before creating a PR
./hooks/run-hooks.sh pre-pr

# Before committing
./hooks/run-hooks.sh pre-commit

# After merging
./hooks/run-hooks.sh post-merge
```

### Run a single hook

```bash
bash hooks/pre-pr/lint.sh
bash hooks/pre-commit/secrets.sh
bash hooks/post-merge/sync-board.sh
```

### Exit codes

- `0` — all hooks passed (safe to proceed)
- `1` — one or more hooks failed (block the action)

---

## Hook Details

### `pre-pr/lint.sh`
Checks all files changed vs `main` for:
- **Trailing whitespace** — spaces at end of lines
- **TODO without ticket** — `TODO` without a reference like `TODO(#123)` or `TODO: PROJ-456`
- **Debug statements** — `console.log`, `debugger`, `pdb.set_trace`, `binding.pry`, etc.

### `pre-pr/test.sh`
For each changed source file (`.ts`, `.js`, `.py`, `.go`, etc.), checks that a corresponding test file exists using common patterns:
- `foo.test.ts` / `foo.spec.ts`
- `__tests__/foo.test.ts`
- `tests/test_foo.py`

Set `SKIP_TEST_CHECK=1` to treat failures as warnings only.

### `pre-pr/type-check.sh`
Runs `tsc --noEmit` against `tsconfig.json` if present. Skips gracefully if:
- No `tsconfig.json` found
- `tsc` is not installed

### `pre-pr/docs-check.sh`
- Verifies `README.md` or `AGENTS.md` exists in the repo root
- Warns (non-blocking) if code was changed but no docs were updated
- Blocks if `README.md` is fewer than 5 lines (stub detection)

### `pre-commit/format.sh`
For staged files:
- **YAML**: Checks for tabs (must use spaces), mixed indentation, trailing whitespace, and validates syntax via `python3 yaml`
- **JSON**: Warns if files aren't pretty-printed, errors on invalid JSON

### `pre-commit/secrets.sh`
Scans staged files using regex for:
- AWS access keys / secret keys
- GitHub tokens (`ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_`)
- Generic `api_key`, `secret`, `password` assignments
- Private key PEM headers
- Slack tokens, Stripe keys, SendGrid keys
- Hardcoded credentials in URLs

**If triggered**: Remove the secret, rotate the key, use env vars or a secrets manager.

### `post-merge/sync-board.sh`
Calls `/Users/dom/.openclaw/workspace/scripts/sync-board.sh` to sync GitHub Projects state to `api.xomware.com`. Non-fatal if the script doesn't exist (CI environments).

### `post-merge/notify.sh`
Echoes merge details (repo, branch, commit, author, message, timestamp). Placeholders for:
- Slack webhook (`SLACK_WEBHOOK_URL`)
- iMessage via osascript (`IMESSAGE_TARGET`)
- OpenClaw/Boris dispatch

---

## Integration with Claude Code

Claude Code hooks are configured in `.claude/settings.json`. Two hooks run automatically:

| Hook | When | What |
|------|------|-------|
| `pre-tool-check.sh` | Before any tool call | Validates the tool call isn't a dangerous pattern |
| `post-tool-log.sh` | After any tool call | Logs tool call completions for audit |

See `.claude/hooks/` for implementation.

### Integrating with git

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
bash hooks/run-hooks.sh pre-commit
```

Add to `.git/hooks/post-merge`:
```bash
#!/bin/bash
bash hooks/run-hooks.sh post-merge
```

Or use [husky](https://typicode.github.io/husky/) / [lefthook](https://github.com/evilmartians/lefthook) to manage git hooks.

### CI/CD integration

```yaml
# GitHub Actions example
- name: Run pre-PR quality gates
  run: bash hooks/run-hooks.sh pre-pr
```

---

## Environment Variables

| Variable | Default | Effect |
|----------|---------|--------|
| `BASE_BRANCH` | `main` | Branch to diff against for changed files |
| `SKIP_TEST_CHECK` | `0` | Set to `1` to make test check warn-only |
| `SLACK_WEBHOOK_URL` | (unset) | Enable Slack notifications in notify.sh |
| `IMESSAGE_TARGET` | (unset) | Enable iMessage notifications in notify.sh |

---

## Adding New Hooks

1. Create a `.sh` file in the appropriate stage directory
2. Make it executable: `chmod +x hooks/<stage>/my-hook.sh`
3. The `run-hooks.sh` master runner picks it up automatically
4. Exit `0` for pass, `1` for fail
5. Document it in this README
