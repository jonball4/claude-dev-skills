#!/usr/bin/env bash
set -euo pipefail
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR is required}"
RAW="$ARTIFACTS_DIR/critique_result.json"
REFINED="$ARTIFACTS_DIR/refined_critique_result.json"
[[ -f "$RAW" && -f "$REFINED" ]] || { echo "missing final review artifact" >&2; exit 1; }

IFS=',' read -r -a SELECTED <<< "${REVIEW_DIMENSIONS:-correctness,quality,maintainability,security,contract}"
[[ "${#SELECTED[@]}" -gt 0 ]] || { echo 'REVIEW_DIMENSIONS must not be empty' >&2; exit 1; }
ALLOWED_JSON=$(printf '%s\n' "${SELECTED[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')

readonly SCHEMA='def severity: if any(. == "error") then "error" elif any(. == "warning") then "warning" elif any(. == "info") then "info" else "none" end; type == "object" and (.max_severity | IN("none","info","warning","error")) and (.comment_count | type == "number" and floor == . and . >= 0) and (.comments | type == "array") and (.comment_count == (.comments | length)) and (.selected_dimensions | type == "array" and . == $allowed) and (.dimensions | type == "array" and (map(.dimension) | sort) == ($allowed | sort)) and (all(.comments[]; type == "object" and (.file | type == "string" and length > 0) and (.line | type == "number" and floor == . and . >= 1) and (.message | type == "string" and length > 0) and (.severity | IN("info","warning","error")) and (.dimension | IN($allowed[])))) and (.max_severity == ([.comments[].severity] | severity))'
jq -e --argjson allowed "$ALLOWED_JSON" "$SCHEMA" "$RAW" >/dev/null || { echo "invalid raw review artifact" >&2; exit 1; }
REFINED_SCHEMA="$SCHEMA and (.challenge_summary | type == \"string\") and (.blind_spots | type == \"array\") and (.empty_critique_flags | type == \"array\") and (.removals | type == \"array\") and (.downgrades_applied | type == \"array\")"
JQ_STATUS=0
jq -e --argjson allowed "$ALLOWED_JSON" "$REFINED_SCHEMA" "$REFINED" >/dev/null || JQ_STATUS=$?
if [[ "$JQ_STATUS" -ne 0 ]]; then echo "invalid refined review artifact" >&2; exit 1; fi
printf 'Validated review artifacts for dimensions=%s in %s\n' "$(IFS=,; echo "${SELECTED[*]}")" "$ARTIFACTS_DIR"
