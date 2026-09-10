# Agent Workflow Skills

A harness-agnostic skill package for substantial software changes. The skills define a strict operating procedure for an agent harness; they are not a standalone CLI, orchestrator, issue tracker, test runner, or worktree manager.

The package is built for use with **Oh My Pi** skill discovery and is optimally compatible with Oh My Pi's native skill model. The installer can also create compatibility links for Claude. The skill content itself avoids Claude- or harness-specific tool names where possible.

```text
build → review-code → handoff → create-pr
              ↘ improve (optional workflow refinement)
```

## Why use it

Agent-driven implementation tends to fail at coordination boundaries: work starts before the plan is accepted, multiple workers edit the same files, test claims lack evidence, review findings disappear between iterations, and pull requests lose the reasoning behind the change.

These skills impose explicit gates and records around those failure modes:

- approved scope and non-goals before implementation;
- exclusive ownership and verified isolation before parallel implementation;
- focused behavioral verification and measured coverage;
- fresh, read-only review with selected risk dimensions;
- explicit finding resolution and diff identity checks;
- human-approved handoff before publication;
- local artifacts that make the current workflow inspectable and resumable while the build is retained.

This adds latency, user decision points, and artifact overhead. Use it when those costs are justified by the size, risk, or coordination complexity of the change—not for trivial edits.

## What this package provides

The package provides skill instructions, review prompts, and review-artifact helper scripts. The invoking harness must provide the capabilities that execute them:

- file reading, searching, and authorized editing;
- command execution and focused verification;
- durable in-session task/state handling;
- worker dispatch and, when parallel implementation is selected, isolated worktrees;
- user approval/clarification handling;
- configured tracker and publication skill invocation.

If the harness cannot verify isolated implementation worktrees, `build` must execute sequentially or stop for a documented procedure. Parallelism is not guaranteed by installation.

## Execution adapter contracts

Repository and harness adapters should expose verification as individual named checks, each with its command or scenario, status, exit status when applicable, raw output/artifact, and blocking status. A composite score may route remediation but cannot turn a failed blocking check into a pass.

Implementation prompts should put prohibitions first, assign one atomic task, use numbered steps, state concrete expected outputs, and require exact verification evidence. The build skill defines this shape without prescribing a particular agent API or command runner.

### `bootstrap-repo`

Creates or refreshes committed repository-specific context under `.agents/repo-context/`: commands, architecture, testing, workflow conventions, source inventory, and unresolved gaps. `build` reads this context at discovery and at the start of every later phase. It is the adapter between the portable workflow contract and a repository's actual tools and conventions.

### `build`


The end-to-end workflow for a substantial issue or feature:

```text
DISCOVER → PLAN → WAIT_FOR_PLAN_ACCEPTANCE → EXECUTE → REVIEW
                                      ↑         ↓
                                      └ NEEDS_FIXES
```

It coordinates issue discovery, plan approval, implementation packets, TDD gates where selected, verification, independent review, finding resolution, handoff approval, and optional PR publication. It does not provide tracker integration, worker infrastructure, or repository-specific commands. When `.agents/repo-context/` exists, it uses that repository adapter rather than guessing commands or layout.

The workflow applies an 85% measured-coverage gate to new additions. A repository without a supported way to measure that coverage cannot complete the build without addressing the resulting finding.

### `review-code`

A read-only review procedure for a caller-supplied diff and evidence. It supports `FULL` reviews or an exact selected subset of correctness, contract, security, maintainability, and quality dimensions. Its scripts validate review artifacts and fail closed on missing or malformed output.

The caller supplies revisions, ticket context, repository instructions, execution evidence, artifact paths, and the selected dimensions. The skill does not fetch branches, modify source, decide whether execution should restart, or publish a pull request.

### `create-pr`

An evidence-aware GitHub publication procedure. It analyzes the current branch, checks for an existing PR, validates supplied handoff/review evidence and diff identity, then creates or updates the PR with `gh`. It is a publishing step, not a substitute for implementation, testing, or review.

### `improve`

An optional post-build analysis procedure. It examines the local build artifacts, review feedback, CI findings, and user steering to propose bounded workflow improvements. It requires approval before changing workflow skills and does not change product source code.

## Installation

### Oh My Pi user installation

Oh My Pi discovers user skills under `~/.agents/skills`:

```bash
git clone <repository-url> ~/Dev/claude-dev-skills
cd ~/Dev/claude-dev-skills
./bootstrap.sh
```

The installer recursively copies each skill directory, including review prompts, helper scripts, and the repository bootstrap skill:

```text
~/.agents/skills/bootstrap-repo/
~/.agents/skills/build/
~/.agents/skills/review-code/
~/.agents/skills/create-pr/
~/.agents/skills/improve/
```

Each skill must remain one level below `skills/`; do not nest skills below another grouping directory.

### Project-local Oh My Pi installation

```bash
./bootstrap.sh --project /path/to/repository
```

This installs under `/path/to/repository/.agents/skills/` and does not create Claude compatibility links.

A default user installation also creates symlinks from `~/.claude/skills/` to the canonical `~/.agents/skills/` installation. Disable them with:

```bash
./bootstrap.sh --no-claude-compat
```

These are discovery links only; the skill content remains harness-agnostic. Re-running the installer replaces the package's existing target directories.

### Repository-specific context

After installing the skills, invoke `bootstrap-repo` from the target repository. It creates `.agents/repo-context/`, which is repository configuration and may be committed. This context is distinct from ephemeral `.work/build/` and `.work/review/` artifacts. Refresh it when commands, architecture, testing, worktrees, or publication conventions change.


## Verification and merge protection

Run the deterministic package checks locally:

```bash
bash tests/run-all.sh
```

The suite covers review-artifact schemas and failure cases, repository-context freshness, build-state transitions, and user/project installation behavior. It intentionally does not run a full host-harness or product-repository integration test.

GitHub Actions runs the same command for pushes and pull requests in the `verify` job. Configure the repository's protected branches to require the `verify` check before merging. GitHub branch protection is repository administration and is not enabled by this package automatically.

## Tracker and publication prerequisites
`build` stores user-owned tracker selection at:

```text
~/.agents/workflow-settings.json
```

On first invocation it asks whether to use Linear or Jira. Issue lookup is delegated to the separately installed/configured tracker skill:

- Linear uses the `linear-cli` skill;
- Jira uses the configured Jira skill.

This repository does not provide an issue adapter. GitHub publication additionally requires an authenticated `gh` CLI. Review helper scripts require a POSIX shell and `jq`.

## Local workflow artifacts

Build and review artifacts are local, ephemeral workflow state. They are intended to support the active local build, review loop, and optional workflow-improvement analysis—not to be committed to the product repository or maintained as long-term project documentation.

Typical build state is written under:

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

Retain the directory while the workflow may need to resume or while `improve` needs its evidence. Remove or exclude it according to the host repository's local-work conventions when the work is complete. The skills do not define a long-term retention, backup, or archival policy.

## Tradeoffs and fit

Use this package when you want a repeatable, evidence-bearing process for risky or multi-agent changes. Do not expect it to make an arbitrary harness operational without integration work. The harness and repository still determine available tools, tracker access, worktree lifecycle, test commands, coverage measurement, and publication permissions.
