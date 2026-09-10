#!/usr/bin/env bash
set -euo pipefail

CONTEXT_DIR=${1:-.agents/repo-context}
ROOT_DIR=$(cd "$CONTEXT_DIR/../.." 2>/dev/null && pwd) || {
  echo "context directory parent repository not found: $CONTEXT_DIR" >&2
  exit 1
}

command -v jq >/dev/null || { echo 'jq is required' >&2; exit 1; }
command -v shasum >/dev/null || { echo 'shasum is required' >&2; exit 1; }

for file in README.md commands.md architecture.md testing.md workflow.md manifest.json; do
  [[ -f "$CONTEXT_DIR/$file" ]] || { echo "missing repository context file: $CONTEXT_DIR/$file" >&2; exit 1; }
done

MANIFEST="$CONTEXT_DIR/manifest.json"
jq -e '
  type == "object" and
  (.schemaVersion == 1) and
  (.generatedAt | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T")) and
  (.repository | type == "string" and length > 0) and
  (.sources | type == "array") and
  (.verifiedCommands | type == "array") and
  (.openGaps | type == "array") and
  (all(.sources[]; type == "object" and (.path | type == "string" and length > 0) and (.path | startswith("/") | not) and (.path | test("(^|/)\\.\\.(/|$)") | not) and (.sha256 | type == "string" and test("^[0-9a-f]{64}$")) and (.lastVerified | type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T"))))
' "$MANIFEST" >/dev/null || { echo "invalid repository context manifest: $MANIFEST" >&2; exit 1; }

while IFS=$'\t' read -r path expected_hash; do
  source_path="$ROOT_DIR/$path"
  [[ -f "$source_path" ]] || { echo "missing context source: $path" >&2; exit 1; }
  actual_hash=$(shasum -a 256 "$source_path" | cut -d ' ' -f 1)
  [[ "$actual_hash" == "$expected_hash" ]] || {
    echo "stale context source: $path (expected $expected_hash, got $actual_hash)" >&2
    exit 1
  }
done < <(jq -r '.sources[] | [.path, .sha256] | @tsv' "$MANIFEST")

printf 'Repository context valid: %s\n' "$CONTEXT_DIR"
