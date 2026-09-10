#!/usr/bin/env bash
# Install the workflow package for Oh My Pi, with optional Claude compatibility links.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="${HOME}/.agents"
SKILLS_DIR="${INSTALL_ROOT}/skills"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
PROJECT_DIR=""
CLAUDE_COMPAT=true

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --user                 Install to ~/.agents/skills (default)
  --project PATH         Install to PATH/.agents/skills
  --no-claude-compat     Do not create ~/.claude/skills compatibility links
  -h, --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) INSTALL_ROOT="${HOME}/.agents"; SKILLS_DIR="${INSTALL_ROOT}/skills"; shift ;;
    --project)
      [[ $# -ge 2 ]] || { echo "--project requires a path" >&2; exit 2; }
      PROJECT_DIR="$(cd "$2" && pwd)"
      INSTALL_ROOT="${PROJECT_DIR}/.agents"
      SKILLS_DIR="${INSTALL_ROOT}/skills"
      CLAUDE_COMPAT=false
      shift 2
      ;;
    --no-claude-compat) CLAUDE_COMPAT=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SKILLS=(bootstrap-repo build review-code create-pr improve)
mkdir -p "$SKILLS_DIR"

for skill in "${SKILLS[@]}"; do
  source_dir="${SCRIPT_DIR}/skills/${skill}"
  target_dir="${SKILLS_DIR}/${skill}"
  [[ -f "${source_dir}/SKILL.md" ]] || { echo "missing skill: ${source_dir}/SKILL.md" >&2; exit 1; }
  rm -rf "$target_dir"
  cp -R "$source_dir" "$target_dir"
done

if [[ "$CLAUDE_COMPAT" == true ]]; then
  mkdir -p "$CLAUDE_SKILLS_DIR"
  for skill in "${SKILLS[@]}"; do
    link="${CLAUDE_SKILLS_DIR}/${skill}"
    if [[ -e "$link" && ! -L "$link" ]]; then
      echo "refusing to replace non-symlink: $link" >&2
      exit 1
    fi
    rm -f "$link"
    ln -s "${SKILLS_DIR}/${skill}" "$link"
  done
fi

printf 'Installed workflow skills to %s\n' "$SKILLS_DIR"
if [[ "$CLAUDE_COMPAT" == true ]]; then
  printf 'Created Claude compatibility links in %s\n' "$CLAUDE_SKILLS_DIR"
fi
printf 'User workflow settings: %s\n' "${HOME}/.agents/workflow-settings.json"
printf 'Skills: %s\n' "${SKILLS[*]}"
