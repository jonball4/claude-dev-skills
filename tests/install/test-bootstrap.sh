#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PROJECT="$TMP_DIR/project"
mkdir -p "$PROJECT"
"$ROOT_DIR/bootstrap.sh" --project "$PROJECT" >/dev/null
for skill in bootstrap-repo build review-code create-pr improve; do
  [[ -f "$PROJECT/.agents/skills/$skill/SKILL.md" ]] || exit 1
done
[[ -x "$PROJECT/.agents/skills/bootstrap-repo/scripts/validate-repo-context.sh" ]] || exit 1
[[ -x "$PROJECT/.agents/skills/build/scripts/validate-build-state.sh" ]] || exit 1
[[ -x "$PROJECT/.agents/skills/review-code/scripts/validate-review-artifacts.sh" ]] || exit 1
[[ -f "$PROJECT/.agents/skills/review-code/prompts/critique-challenge.md" ]] || exit 1

HOME_DIR="$TMP_DIR/home"
mkdir -p "$HOME_DIR"
HOME="$HOME_DIR" "$ROOT_DIR/bootstrap.sh" --user >/dev/null
for skill in bootstrap-repo build review-code create-pr improve; do
  link="$HOME_DIR/.claude/skills/$skill"
  [[ -L "$link" ]] || exit 1
  [[ "$(readlink "$link")" == "$HOME_DIR/.agents/skills/$skill" ]] || exit 1
done

NO_COMPAT_HOME="$TMP_DIR/no-compat-home"
mkdir -p "$NO_COMPAT_HOME"
HOME="$NO_COMPAT_HOME" "$ROOT_DIR/bootstrap.sh" --user --no-claude-compat >/dev/null
[[ ! -e "$NO_COMPAT_HOME/.claude/skills" ]] || exit 1

printf 'Installer smoke tests passed\n'
