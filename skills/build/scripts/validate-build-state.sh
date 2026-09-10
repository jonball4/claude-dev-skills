#!/usr/bin/env bash
set -euo pipefail

STATE=${1:?usage: validate-build-state.sh <state.json> [from-phase to-phase]}
[[ -f "$STATE" ]] || { echo "missing state file: $STATE" >&2; exit 1; }
command -v jq >/dev/null || { echo 'jq is required' >&2; exit 1; }

jq -e '
  type == "object" and
  (.phase | IN("DISCOVER","PLAN","WAIT_FOR_PLAN_ACCEPTANCE","EXECUTE","REVIEW","WAIT_FOR_HANDOFF_APPROVAL","SQUASH","HANDOFF")) and
  (.planAccepted | type == "boolean") and
  (.executionIteration | type == "number" and floor == . and . >= 0) and
  (.reviewIteration | type == "number" and floor == . and . >= 0) and
  (.packets | type == "object") and
  (.worktrees | type == "object") and
  (.attempts | type == "array") and
  (.findings | type == "object") and
  (.findings.open | type == "array") and
  (.findings.resolved | type == "array") and
  ((.findings.open + .findings.resolved) | length == (unique | length)) and
  (if has("reviewStatus") then .reviewStatus | IN("APPROVED","NEEDS_FIXES") else true end)
' "$STATE" >/dev/null || { echo "invalid build state: $STATE" >&2; exit 1; }

if [[ $# -eq 3 ]]; then
  FROM=$2
  TO=$3
  case "$FROM:$TO" in
    DISCOVER:PLAN|PLAN:WAIT_FOR_PLAN_ACCEPTANCE|WAIT_FOR_PLAN_ACCEPTANCE:EXECUTE|EXECUTE:REVIEW|REVIEW:EXECUTE|REVIEW:WAIT_FOR_HANDOFF_APPROVAL|WAIT_FOR_HANDOFF_APPROVAL:HANDOFF|WAIT_FOR_HANDOFF_APPROVAL:SQUASH|SQUASH:HANDOFF) ;;
    *) echo "invalid phase transition: $FROM -> $TO" >&2; exit 1 ;;
  esac
elif [[ $# -ne 1 ]]; then
  echo 'usage: validate-build-state.sh <state.json> [from-phase to-phase]' >&2
  exit 2
fi

printf 'Build state valid: %s\n' "$STATE"
