#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
CONTEXT_VALIDATOR="$ROOT_DIR/skills/bootstrap-repo/scripts/validate-repo-context.sh"
STATE_VALIDATOR="$ROOT_DIR/skills/build/scripts/validate-build-state.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

expect_fail() {
  if "$@" >/dev/null 2>&1; then
    echo "expected failure but command passed: $*" >&2
    exit 1
  fi
}

REPO="$TMP_DIR/repo"
CONTEXT="$REPO/.agents/repo-context"
mkdir -p "$CONTEXT"
printf '%s\n' source > "$REPO/package.json"
for file in README.md commands.md architecture.md testing.md workflow.md; do printf '%s\n' context > "$CONTEXT/$file"; done
HASH=$(shasum -a 256 "$REPO/package.json" | cut -d ' ' -f 1)
printf '%s\n' '{"schemaVersion":1,"generatedAt":"2026-01-01T00:00:00Z","repository":"fixture","sources":[{"path":"package.json","sha256":"'"$HASH"'","lastVerified":"2026-01-01T00:00:00Z"}],"verifiedCommands":[],"openGaps":[]}' > "$CONTEXT/manifest.json"
"$CONTEXT_VALIDATOR" "$CONTEXT" >/dev/null
printf '%s\n' changed > "$REPO/package.json"
expect_fail "$CONTEXT_VALIDATOR" "$CONTEXT"
HASH=$(shasum -a 256 "$REPO/package.json" | cut -d ' ' -f 1)
jq --arg hash "$HASH" '.sources[0].sha256 = $hash' "$CONTEXT/manifest.json" > "$CONTEXT/manifest.tmp"
mv "$CONTEXT/manifest.tmp" "$CONTEXT/manifest.json"
"$CONTEXT_VALIDATOR" "$CONTEXT" >/dev/null

STATE="$TMP_DIR/state.json"
cat > "$STATE" <<'JSON'
{"phase":"REVIEW","planAccepted":true,"executionIteration":1,"reviewIteration":1,"packets":{},"worktrees":{},"attempts":[],"findings":{"open":[],"resolved":[]}}
JSON
"$STATE_VALIDATOR" "$STATE" REVIEW EXECUTE >/dev/null
expect_fail "$STATE_VALIDATOR" "$STATE" EXECUTE HANDOFF
jq '.phase = "INVALID"' "$STATE" > "$STATE.tmp"
mv "$STATE.tmp" "$STATE"
expect_fail "$STATE_VALIDATOR" "$STATE"

printf 'Context and build-state contract tests passed\n'
