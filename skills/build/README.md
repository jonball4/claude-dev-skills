# build

`build` is a deterministic workflow specification for implementing a substantial feature or change from configured issue context. It is executed by a compatible agent harness; it is not a standalone build runner.

Use it through the harness's `/build` command when available:

```text
/build ENG-123
/build https://linear.app/acme/issue/ENG-123/add-export-filter
/build PROJ-123
```

On first invocation, the workflow asks whether the user uses Linear or Jira and stores the selection in `~/.agents/workflow-settings.json`. Issue lookup is delegated to the separately configured tracker skill. This repository does not provide an issue adapter.

The invoking harness must provide file access, command execution, state/artifact handling, user approval, worker dispatch, and tracker/publication skill invocation. Parallel implementation additionally requires a documented and verified isolated-worktree procedure. Without one, the workflow executes sequentially or stops for a procedure; installation does not provide that infrastructure.

Use a simpler workflow for trivial edits. Use the bugfix workflow for defect investigation and regression fixes.

## What the workflow does

```text
DISCOVER
   ↓
PLAN
   ↓
WAIT FOR PLAN ACCEPTANCE
   ↓
EXECUTE (parallel only when isolation is verified)
   ↓
REVIEW
   ├─ NEEDS_FIXES → EXECUTE → REVIEW  (repeat)
   └─ APPROVED
        ↓
HANDOFF → present to user
```

The plan is presented for approval before implementation begins. Approved work is decomposed into owned packets, executed using the harness's available isolation, and reviewed until no actionable findings remain. Verification is part of the execute-and-review loop; there is no separate final-check phase.

## Quality expectations

The workflow expects implementations to favor:

- clean, small, pure functions;
- explicit inputs and outputs;
- dependency injection at external boundaries;
- clear separation of domain logic, orchestration, adapters, persistence, transport, and presentation;
- focused behavioral and boundary tests;
- at least **85% measured test coverage for new additions**.

The coverage threshold is a completion gate. If the repository cannot measure coverage for changed additions, the workflow records a finding rather than claiming success. Coverage does not replace meaningful tests: new behavior, errors, transitions, precedence rules, and invariants should be tested directly.

## Issue tracker settings

The workflow reads the user-owned settings file:

```json
{
  "version": 1,
  "issueTracker": "linear"
}
```

If the file is absent, `/build` asks once for `linear` or `jira` and creates it. Future workflow preferences may be added to this file; unknown settings are preserved. A malformed file stops discovery before implementation.

Issue lookup is delegated to the configured tracker skill. For Linear, `/build` invokes the `linear-cli` skill for structured issue JSON. For Jira, it invokes the configured Jira skill. The build normalizes the response only inside its local workflow state and stores it in `.work/build/<BUILD-ID>/issue.json`.

## Local workflow artifacts

Build artifacts are local, ephemeral workflow state. They support resumption while the build is retained and provide input to the optional `improve` workflow. They are not intended to be committed to the product repository or maintained as long-term documentation.

```text
.work/build/<BUILD-ID>/
├── issue.json
├── TDD.md                         # optional linked design material
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

Review history is retained within the local build directory while the workflow is active. The skills do not define archival, backup, or long-term retention policy.

## Human decision points

You are asked to approve the plan before implementation begins. Approval should confirm:

- the scope and non-goals;
- the proposed architecture and contracts;
- the work breakdown;
- the sequencing and parallelization approach;
- the test and coverage strategy;
- migration and rollback considerations.

After review approval, the handoff is presented for final user review. Any requested source changes begin another execute-and-review iteration.

## Pull requests

When a GitHub pull request is requested, the workflow uses the `create-pr` skill after review and handoff approval. The configured issue ID or URL is included in the pull-request context. Publication still requires an authenticated `gh` CLI and matching handoff/review evidence.
