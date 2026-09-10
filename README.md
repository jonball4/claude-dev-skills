# Agent Workflow Skills

A harness-agnostic workflow package for substantial software changes:

```text
build → review-code → handoff → create-pr
              ↘ improve (optional post-build refinement)
```

The package is authored for Oh My Pi's native skill discovery and is also compatible with Claude through optional compatibility links.

## Skills

### `build`

End-to-end implementation orchestration:

```text
DISCOVER → PLAN → WAIT_FOR_PLAN_ACCEPTANCE → EXECUTE → REVIEW
                                      ↑         ↓
                                      └ NEEDS_FIXES
```

It provides durable artifacts, explicit worktree isolation, TDD execution gates, subset-aware independent review, finding resolution, handoff approval, and optional PR publication.

### `review-code`

Read-only, repository-agnostic multi-perspective review. It supports full or explicitly selected dimensions:

- correctness;
- contract;
- security;
- maintainability;
- quality.

Review artifacts are fail-closed and written under a caller-provided artifact directory.

### `create-pr`

Evidence-aware GitHub publication. It validates the current branch, reviewed diff identity, handoff, and verification evidence before creating or updating a pull request. It is independently invocable and does not replace implementation, testing, or review.

### `improve`

Optional post-build workflow analysis. It turns durable build artifacts, review feedback, CI findings, and user steering into bounded improvement proposals. It never changes workflow skills without approval.

## Installation

### Oh My Pi user installation

Oh My Pi's native user skill directory is `~/.agents/skills`:

```bash
git clone <repository-url> ~/Dev/claude-dev-skills
cd ~/Dev/claude-dev-skills
./bootstrap.sh
```

The installer installs:

```text
~/.agents/skills/build/SKILL.md
~/.agents/skills/review-code/SKILL.md
~/.agents/skills/create-pr/SKILL.md
~/.agents/skills/improve/SKILL.md
```

Oh My Pi discovers each skill one level below `skills/`. Do not nest skills below another grouping directory.

### Project-local Oh My Pi installation

To install the package for one repository instead of the user globally:

```bash
./bootstrap.sh --project /path/to/repository
```

This creates `/path/to/repository/.agents/skills/` and does not create Claude compatibility links.

### Claude compatibility

The default user installation also creates symlinks:

```text
~/.claude/skills/build      → ~/.agents/skills/build
~/.claude/skills/review-code → ~/.agents/skills/review-code
~/.claude/skills/create-pr → ~/.agents/skills/create-pr
~/.claude/skills/improve   → ~/.agents/skills/improve
```

Disable them with:

```bash
./bootstrap.sh --no-claude-compat
```

The canonical source remains `.agents/skills`; `.claude/skills` is compatibility-only.

## Tracker settings

`build` stores user-owned workflow settings at:

```text
~/.agents/workflow-settings.json
```

On first invocation, it asks whether the issue tracker is Linear or Jira and writes:

```json
{
  "version": 1,
  "issueTracker": "linear"
}
```

Linear lookup delegates to the `linear-cli` skill. Jira lookup delegates to the configured Jira skill. The repository does not provide an issue adapter and is not required to conform to an issue schema.

Unknown settings are preserved for future workflow controls. A malformed settings file stops discovery before implementation.

## Runtime requirements

The invoking harness must provide equivalent capabilities for:

- reading and searching files;
- editing files when authorized;
- running focused commands and verification;
- durable task and artifact state;
- isolated worker dispatch when parallel execution is selected;
- tracker and publication skill invocation.

The skills do not require Claude-specific metadata or tool names. Shell-based review helpers additionally require a POSIX shell and `jq` when the review workflow is used.

## Build artifacts

Build artifacts remain repository-local and resumable:

```text
.work/build/<BUILD-ID>/
├── issue.json
├── discovery-summary.md
├── plan.md
├── components/
├── state.json
├── execution/
├── reviews/
├── execution-results.md
├── review-results.md
└── handoff.md
```
