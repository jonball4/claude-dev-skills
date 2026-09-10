# build

`build` is a deterministic workflow for implementing a substantial feature from the configured issue tracker.

Use it through the `/build` command:

```text
/build ENG-123
/build https://linear.app/acme/issue/ENG-123/add-export-filter
/build PROJ-123
```

On first invocation, the workflow asks whether the user uses Linear or Jira and stores the selection in `~/.agents/workflow-settings.json`. The repository does not provide or configure an issue adapter.

Use a simpler workflow for trivial edits. Use the bugfix workflow for defect investigation and regression fixes.

## What the workflow does

```text
DISCOVER
   ↓
PLAN
   ↓
WAIT FOR PLAN ACCEPTANCE
   ↓
EXECUTE SWARM
   ↓
REVIEW
   ├─ NEEDS_FIXES → EXECUTE → REVIEW  (repeat)
   └─ APPROVED
        ↓
HANDOFF → present to user
```

The plan is presented for approval before implementation begins. Once approved, implementation work is decomposed into independently owned packets and executed in parallel when safe. Review findings return the work to execution until the implementation is clean.

There is no separate final-check phase. Verification is part of the execute-and-review loop.

## Quality expectations

The workflow expects implementations to favor:

- clean, small, pure functions;
- explicit inputs and outputs;
- dependency injection at external boundaries;
- clear separation of domain logic, orchestration, adapters, persistence, transport, and presentation;
- focused behavioral and boundary tests;
- at least **85% measured test coverage for new additions**.

Coverage does not replace meaningful tests. New behavior, errors, transitions, precedence rules, and invariants should be tested directly.

## Issue tracker settings

The workflow reads the user-owned settings file:

```json
{
  "version": 1,
  "issueTracker": "linear"
}
```

If the file is absent, `/build` asks once for `linear` or `jira` and creates it. Future workflow preferences may be added to this file; unknown settings are preserved. A malformed file stops discovery before implementation.

Issue lookup is delegated to the configured tracker skill. For Linear, `/build` invokes the `linear-cli` skill for structured issue JSON; it does not embed raw Linear CLI/API calls. For Jira, it invokes the configured Jira skill. The build normalizes the response only inside its session and stores it in `.work/build/<BUILD-ID>/issue.json`.

## Work artifacts

Build artifacts are stored in the repository so the work can be resumed across sessions:

```text
├── issue.json                     # normalized issue context from the selected tracker skill
├── TDD.md                         # optional linked design material
├── discovery-summary.md           # requirements and repository findings
├── plan.md                        # approved scope and work breakdown
├── components/                    # independently owned work packets
│   ├── api.md
│   └── persistence.md
├── state.json                     # resumable workflow and finding summary
├── execution/                     # one record per execution iteration
│   ├── iteration-001.md
│   └── iteration-002.md
├── reviews/                       # complete output from every review iteration
│   ├── iteration-001.md
│   └── iteration-002.md
├── execution-results.md           # execution history index
├── review-results.md              # review and finding-resolution index
└── handoff.md                     # final user-facing result
```

Review history is retained rather than overwritten. Each review records its findings, evidence, and resolution status; the final handoff links the relevant execution and review history.

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

When a GitHub pull request is requested, the workflow uses the `create-pr` skill after review approval. The configured issue ID or URL is included in the pull-request context.
