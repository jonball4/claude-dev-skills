---
name: bootstrap-repo
description: Create or refresh repository-specific context that build workflows use to navigate, execute, test, review, and publish safely
argument-hint: <repository-path-or-current-repository>
user-invocable: true
---

# Bootstrap Repository Context

Create a repository-specific execution adapter for the portable workflow skills. This skill inspects the target repository and writes concise context files under `.agents/repo-context/` so `build`, `review-code`, `create-pr`, and `improve` can use the repository's real conventions without guessing.

This is repository configuration, not ephemeral build/review state. The generated context MAY be committed and maintained with the repository. Do not write build artifacts under this directory; active workflow artifacts belong under `.work/` and are local and ephemeral.

## When to use

Use this skill:

- when adopting the workflow package in a repository;
- after major changes to commands, architecture, branching, worktrees, or CI;
- when the build workflow reports missing, stale, or contradictory repository context.

Do not use it to implement a product feature or to create a ticket. Do not invent commands, architecture, or policies that are not supported by repository evidence.

## Required investigation

Inspect, when present:

- repository instructions and agent configuration;
- package/build/dependency manifests;
- source-tree and test layout;
- CI workflows and verification scripts;
- branch, commit, PR, and release conventions;
- documented worktree/bootstrap procedures;
- coverage configuration and supported commands;
- generated-code and migration procedures;
- security, deployment, and integration references relevant to development.

Prefer existing authoritative documentation and executable scripts. Run only safe, focused discovery or verification commands needed to confirm documented behavior. Record unknowns instead of guessing.

## Output contract

Create or refresh `.agents/repo-context/` with these files:

```text
.agents/repo-context/
├── README.md       # purpose, ownership, refresh triggers, source inventory
├── commands.md     # build, test, lint, format, coverage, integration commands
├── architecture.md # layers, entry points, boundaries, generated code
├── testing.md      # test layout, test modes, fixtures, coverage interpretation
├── workflow.md     # branches, commits, worktrees, CI, PR and release rules
└── manifest.json   # schema version, timestamps, source hashes, open gaps
```

Use repository-relative paths. Every command must include its working-directory assumptions, prerequisites, and whether it is focused or broad. Distinguish commands verified by execution from commands copied from documentation. Record the SHA-256 and last verification time for every source used to generate the context.

`manifest.json` MUST contain:

```json
{
  "schemaVersion": 1,
  "generatedAt": "<ISO-8601 timestamp>",
  "repository": "<repository name>",
  "sources": [
    {"path": "<relative path>", "sha256": "<64 lowercase hex characters>", "lastVerified": "<ISO-8601 timestamp>"}
  ],
  "verifiedCommands": [],
  "openGaps": []
}
```

The installed `scripts/validate-repo-context.sh` validator MUST pass before context is declared ready. It verifies required files, manifest shape, repository-relative sources, source existence, and source hashes. A changed source makes the context stale and requires refresh; the build MUST NOT silently trust stale context.

Do not include secrets, tokens, credentials, personal machine paths, transient build output, or claims that cannot be traced to a source or verification result.

## Refresh and conflict behavior

Preserve intentional human edits only when the file clearly marks them as maintained sections. Otherwise regenerate from current evidence and report changes. If sources conflict, record the conflict in `manifest.json.openGaps` and `README.md`; do not silently choose one.

A successful bootstrap reports:

- files created or refreshed;
- sources consulted;
- commands verified and their observed results;
- unresolved gaps or conflicts;
- whether the context is ready for `build`.

## Build integration

The `build` skill reads `.agents/repo-context/` before discovery and at the start of every subsequent phase. It uses the context to choose repository commands, navigate layers, initialize worktrees, interpret tests and coverage, and understand branch/publication constraints. The build must verify context against current repository state when it is stale or contradictory.
