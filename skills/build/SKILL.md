---
name: build
argument-hint: <issue-id-or-url>
description: Deterministically orchestrate a planned, testable implementation from a configured issue tracker
---

# Build

Execute this workflow for a substantial feature or change described by supplied issue context. The workflow is deterministic: discover, plan, obtain plan acceptance, swarm-execute non-conflicting work packets, review with a fresh unbiased reviewer, flap execution and review until clean, then present the handoff.

Do not use this workflow for trivial edits or a bugfix that belongs in the bugfix workflow.

## Standing build instructions

These instructions apply to every implementation component and integration change:

- Prefer small, pure functions with explicit inputs and outputs.
- Make behavior intentional and easy to test.
- Use dependency injection at boundaries: clocks, randomness, I/O, network clients, persistence, environment, and external services must not be hidden inside domain logic.
- Keep clean separation of concerns between domain logic, orchestration, adapters, persistence, transport, and presentation.
- Reuse existing repository patterns unless the approved plan explicitly changes them.
- Avoid speculative abstractions, hidden global state, incidental coupling, and broad refactors.
- Add or update focused tests for every new observable behavior and important boundary.
- New additions MUST achieve at least 85% measured test coverage using the repository's supported coverage tool. If the repository cannot measure coverage for the changed additions, report that as a review finding rather than claiming success.
- Coverage is not a substitute for behavioral tests; test boundaries, errors, transitions, precedence, and invariants.
- Preserve unrelated user changes. Never reset, discard, or overwrite work outside the approved scope.

## Execution capabilities

The invoking harness must provide equivalent capabilities for:

- reading and searching repository files;
- editing workflow or source files when authorized;
- running short commands and focused verification;
- maintaining durable task/state records;
- dispatching independent implementation and review workers;
- invoking configured tracker and publication skills.

Capability names, tool schemas, and frontmatter are harness-specific. This skill describes required outcomes and boundaries, not a particular tool API. The invoking harness MUST map these capabilities before execution and MUST preserve the contracts, state transitions, review isolation, and evidence requirements below.

## Repository context and execution adapter

When present, read the repository's generated context under `.agents/repo-context/` before discovery and again at the start of every later phase. The context is a repository-specific execution adapter, not build artifact state. Use it to navigate the repository, choose commands, understand architecture, initialize worktrees, and interpret verification; verify stale or contradictory entries against the repository before relying on them. If no repository context exists, use repository instructions and established patterns, and do not invent commands or infrastructure.

The optional `bootstrap-repo` skill creates and refreshes this context. Its files may be committed and maintained as repository configuration; they are distinct from ephemeral `.work/build/` and `.work/review/` artifacts.

## Portable verification oracle contract

The harness or repository adapter MAY expose a composite verification oracle, but a score MUST NOT replace individual gates. Every verification result supplied to this workflow MUST record:

- a stable check name;
- the command or behavioral scenario used;
- `pass`, `fail`, or `skipped` status;
- exit status when a command was run;
- observed output or an artifact path;
- whether failure blocks the current gate.

The orchestrator MUST preserve raw verification evidence and MUST NOT report a passing gate when any blocking check fails. Composite scores may prioritize remediation only; they never override a failed blocking check.


## Worktree and concurrency gate

Before planning parallel implementation execution, search the repository and applicable harness documentation for a clearly defined worktree bootstrap procedure. The procedure MUST define how to create, initialize, identify, retain, and clean up an isolated worktree for each implementation task.

Do not parallelize implementation agents until that procedure is verified. If no documented procedure exists, execute sequentially or ask for one; do not infer isolation from a task prompt.

The procedure MUST include:

- absolute worktree paths;
- branch identity and separation from the main checkout;
- dependency initialization result;
- ownership boundaries for every packet;
- cleanup and retention policy;
- collision and retry handling.

Parallel read-only agents are encouraged when useful. Discovery scouts, documentation researchers, diff inspectors, and reviewers may run concurrently without implementation worktrees when they make no source or generated-file changes. Their prompts MUST explicitly prohibit edits.

Record the selected procedure, implementation worktree paths, branch names, initialization results, and cleanup policy in `plan.md` and `execution-results.md`.

## Local workflow artifacts

Use one canonical repository-local work directory for the active build. These artifacts are ephemeral local workflow state: retain them while the build may resume or while `improve` needs its evidence, but do not treat them as product-repository documentation or a long-term record.

`.work/` is local-only and MUST NOT be committed (ensure it is gitignored). Never reference `.work/` artifact paths in published outputs the user may act on outside this machine — commit messages, pull request titles/bodies, issue comments, or tracker tickets — and do not cite them as if they were committed repository files. When summarizing evidence externally, inline the substantive results (test counts, coverage percentages, review verdicts, artifact-relative section names) instead of pointing at `.work/` paths. The build MUST NEVER delete `.work/` artifacts — not at completion, not during cleanup, not on ambiguous instructions. Treat user phrases like "remove the artifacts" or "clean up" in the context of non-committed files as "do not reference them in published outputs", never as filesystem deletion. Artifact retention is decided only by the user's explicit, unambiguous request; the artifacts are the sole evidence input for `improve`.

.work/build/<ISSUE-ID>/
├── issue.json
├── TDD.md                         # optional source design
├── discovery-summary.md           # requirements and repository findings
├── plan.md                        # approved scope, contracts, ownership, dependencies
├── components/
│   └── <component>.md             # one complete work packet per owner
├── state.json                     # current machine-readable state and finding index
├── execution/
│   ├── iteration-001.md
│   └── iteration-002.md
├── reviews/
│   ├── iteration-001/
│   │   ├── correctness_critique_result.json
│   │   ├── quality_critique_result.json
│   │   ├── maintainability_critique_result.json
│   │   ├── security_critique_result.json
│   │   ├── contract_critique_result.json
│   │   ├── critique_result.json
│   │   ├── challenge_result.json
│   │   ├── refined_critique_result.json
│   │   └── ...
│   └── iteration-002/
├── execution-results.md           # human-readable execution index
├── review-results.md              # human-readable review index and resolution ledger
└── handoff.md                     # final user-facing result
```

Maintain `state.json` as a compact index, not as a replacement for full artifacts:

```json
{
  "phase": "REVIEW",
  "planAccepted": true,
  "executionIteration": 2,
  "reviewIteration": 2,
  "reviewStatus": "NEEDS_FIXES",
  "review": {
    "mode": "SUBSET",
    "selectedDimensions": ["correctness", "contract"],
    "excludedDimensions": ["security", "maintainability", "quality"],
    "dimensionRationale": {"correctness": "runtime state transition changed", "contract": "public response shape changed"},
    "exclusionRationale": {"security": "no trust boundary or sensitive data changed", "maintainability": "no structural or ownership change", "quality": "no local implementation-quality delta beyond selected contract change"},
    "previousDiffIdentity": "<prior commit or diff hash>",
    "currentDiffIdentity": "<current commit or diff hash>",
    "deltaClassification": "mixed",
    "artifact": "reviews/iteration-002.md"
  },
  "packets": {
    "api": {"status": "complete", "executionIteration": 2, "artifact": "execution/iteration-002.md"}
  },
  "worktrees": {
    "api": {"path": "<absolute-path>", "branch": "build/ENG-123-api", "status": "retained"}
  },
  "attempts": [
    {"packet": "api", "iteration": 1, "approach": "<summary>", "result": "failed", "reason": "<evidence-backed reason>", "artifact": "execution/iteration-001.md"}
  ],
  "findings": {
    "open": ["R-003"],
    "resolved": ["R-001", "R-002"],
    "history": [
      {"id": "R-001", "introduced": 1, "resolved": 2, "status": "resolved", "artifact": "reviews/iteration-001.md"},
      {"id": "R-003", "introduced": 2, "resolved": null, "status": "open", "artifact": "reviews/iteration-002.md"}
    ]
  },
  "latestExecutionArtifact": "execution/iteration-002.md",
  "latestReviewArtifact": "reviews/iteration-002.md"
}
```

- when `review.mode` is `SUBSET`, `review.selectedDimensions` and `review.excludedDimensions` are disjoint, their union is the complete supported dimension set, and both rationale maps cover their respective lists;
- when `review.mode` is `FULL`, `review.selectedDimensions` is the complete supported dimension set and `review.excludedDimensions` is empty;
- `review.previousDiffIdentity`, `review.currentDiffIdentity`, `review.deltaClassification`, and `review.artifact` are present for every dispatched review;
Update it after every phase transition, packet result, worktree allocation, retry, and review result. Store full evidence and prose in the referenced artifacts; keep `state.json` bounded and machine-readable. Never create duplicate root-level and `plans/` artifact trees.

## Artifact consistency gate

Artifact validation is part of the EXECUTE → REVIEW loop, not a separate phase. Before a packet or review iteration is considered complete, the orchestrator MUST validate the local workflow records. The installed `scripts/validate-build-state.sh` helper validates the machine-readable state shape and, when given two phases, the allowed transition.


Validate `state.json`:
- required top-level fields exist: `phase`, `planAccepted`, `executionIteration`, `reviewIteration`, `packets`, `worktrees`, `attempts`, `findings`;
- `phase` is one of `DISCOVER`, `PLAN`, `WAIT_FOR_PLAN_ACCEPTANCE`, `EXECUTE`, `REVIEW`, `WAIT_FOR_HANDOFF_APPROVAL`, `SQUASH`, or `HANDOFF`;
- iteration values are non-negative integers;
- `reviewStatus`, when present, is `APPROVED` or `NEEDS_FIXES`;
- every packet and worktree has a corresponding plan entry;
- every artifact path is relative to the build directory and exists;
- `findings.open`, `findings.resolved`, and `findings.history` contain no contradictory status for the same finding;
- every retry records a packet, approach, result, evidence-backed reason, and artifact path.
Validate each component packet:

- all required schema headings are present;
- allowed and forbidden ownership do not overlap;
- dependencies refer to known packets;
- the worktree is allocated and verified before implementation;
- verification and coverage commands are present.

Validate each execution iteration:

- every scheduled packet has a result of `complete`, `blocked`, or `failed`;
- every completed packet has changed-file, worktree, commit-range, per-commit build/test, command, coverage, and evidence records;
- every recorded commit has passing build/test evidence and is independently shippable;
- every reported artifact exists;
- every worktree path is distinct from the main checkout and other active implementation worktrees.

Validate each review iteration:

- its execution iteration and diff identity are recorded;
- every finding has an ID, status, severity, category, evidence, and required change;
- every `resolved` finding has resolution evidence from a later execution or review artifact;
- every open finding appears in both `state.json.findings.open` and the review index;
- every resolved finding appears in `state.json.findings.resolved` and the review index;
- `review-results.md`, `state.json`, and the iteration artifact agree on status and finding state.

Validation failure means the current packet or review is incomplete. It MUST NOT be treated as success or approval.

## State machine

The only valid phase transitions are:

```text
DISCOVER → PLAN → WAIT_FOR_PLAN_ACCEPTANCE → EXECUTE
EXECUTE → REVIEW
REVIEW → EXECUTE                   when review status is NEEDS_FIXES
REVIEW → WAIT_FOR_HANDOFF_APPROVAL when review status is APPROVED
WAIT_FOR_HANDOFF_APPROVAL → SQUASH                   by default (pull request is the standard publication)
WAIT_FOR_HANDOFF_APPROVAL → HANDOFF                   only on explicit user opt-out of PR creation
SQUASH → HANDOFF                                       after the single-commit invariant is verified
```

## Phase 1: Discover

1. Read `~/.agents/workflow-settings.json`. This is user-owned workflow configuration, not repository configuration. If it does not exist, ask once whether the issue tracker is **Linear** or **Jira**, then create it atomically with the selected provider. Do not inspect the repository for an adapter or expect repository instructions to define this behavior.
2. The settings file MUST support this initial shape and MAY gain additional workflow controls later:

```json
{
  "version": 1,
  "issueTracker": "linear"
}
```

`issueTracker` MUST be `linear` or `jira`. Preserve unknown future settings when updating the file. A malformed settings file is a user configuration error: report the path and parse failure, then stop before implementation.
3. Resolve the supplied issue ID or URL by invoking the configured tracker skill, not by embedding provider API calls or raw provider CLI commands in this skill:
   - `linear`: invoke the `linear-cli` skill and request the issue as structured JSON;
   - `jira`: invoke the configured Jira skill and request the issue as structured JSON.
4. Normalize the tracker skill's response inside the build session into the build's internal issue context. Do not require Linear or Jira to emit a shared repository-owned schema.
5. Save the normalized context to `.work/build/<BUILD-ID>/issue.json`.
6. Read the issue title, description, acceptance criteria, comments, linked documents, project, priority, and labels when available.
7. Read repository instructions, relevant source, existing tests, and established patterns.
8. Read linked design material with the harness URL reader, or request an accessible local copy when necessary. Save supplied design material as `TDD.md`.
9. Write `discovery-summary.md` with the desired outcome, acceptance criteria, affected systems, likely files and callsites, constraints, risks, unresolved questions, and sources consulted.

The build MUST NOT assume that the repository provides an issue adapter or conforms to any issue-context contract. Tracker selection and future workflow preferences belong to the user settings file. Provider lookup belongs to the configured tracker skill.


Do not begin planning with invented ticket details. Ask only for missing information that tools and the configured tracker cannot resolve.


## Phase 2: Plan and prepare the swarm

Write `plan.md` and one `components/<component>.md` per independently owned work packet.

`plan.md` MUST define:

- scope and explicit non-goals;
- contracts, data flow, and compatibility boundaries;
- pure-function and dependency-injection opportunities;
- component list and exclusive file/symbol ownership;
- non-conflicting work packets suitable for parallel execution;
- dependencies and scheduling order;
- test strategy and coverage measurement for new additions;
- acceptance criteria mapped to concrete checks or scenarios;
- one delegated integration owner for shared files and final integration;
- worktree bootstrap procedure, worktree paths, branch names, initialization results, and cleanup policy;
- rollback and failure handling;
- sources consulted.

# Component
<stable component name>

# Owner
<agent or integration owner>

# Worktree
<isolated worktree path and branch>

# Allowed files
<exact files or symbols>

# Forbidden files
<files or symbols outside ownership>

# Dependencies
<packet names, or none>

# Contract
<interfaces and behavior>

# Acceptance criteria
<observable requirements>

# TDD mode
strict | focused | none

# Execution risk
low | high

# RED verification command
<focused command proving new tests fail, when TDD mode is strict>

# GREEN verification command
<focused command proving implementation passes>

# REFACTOR verification command
<targeted and broader regression command, when applicable>

# Verification command
<focused command or scenario>

# Coverage command
<command and scope for new additions>

# Minimum new-addition coverage
85%

## Post-plan execution protocol

The approved plan is authoritative. Execution MUST NOT reopen scope, architecture, or ticket requirements. Agents may make only implementation decisions necessary to satisfy the packet contract.

For packets with `TDD mode: strict`, execute separate waves:

1. **RED:** write only tests; do not modify implementation files. The lead independently verifies that the tests fail with assertion failures caused by missing behavior, not import, configuration, or syntax errors.
2. **GREEN:** modify implementation files only as needed to satisfy the failing tests. Do not rewrite test expectations. The lead independently verifies the focused tests pass.
3. **REFACTOR:** simplify or improve the implementation without changing observable behavior. Re-run focused tests, the packet's broader regression checks, and lint/typecheck where applicable.

Never combine RED and GREEN in one agent assignment. A packet with `focused` TDD MAY combine test and implementation work only when the approved plan explicitly says so. A packet with `none` MUST still include behavioral verification for every acceptance criterion.

`Execution risk: high` permits two or three isolated implementations of the same approved contract. Candidates MUST NOT redesign the ticket. Select using acceptance-criteria adherence, focused tests, coverage, integration cost, complexity, and review risk; record rejected candidates and evidence in the execution artifact. Low-risk packets use one implementation path.

Record failed implementation approaches in `state.json` and the execution artifact. Retries MUST include prior failed approaches and MUST NOT repeat one without explaining why its failure no longer applies. Three failed attempts on the same packet require user escalation or explicit packet redesign.

The lead MUST independently verify every RED, GREEN, and REFACTOR gate. Agent success claims without command output are incomplete.

## Layered execution gates

- **TDD gate:** strict RED tests genuinely fail; GREEN tests pass; REFACTOR preserves behavior.
- **Packet gate:** ownership, focused verification, coverage, worktree, and evidence records are valid.
- **Wave gate:** all ready packets complete, dependencies are satisfied, and combined verification passes.
- **Review gate:** the independent review artifacts validate, the reviewed diff matches the current diff, and no actionable findings remain.
- **Handoff gate:** final verification passes, the working tree is clean, and handoff evidence matches the reviewed commit range.

Composite scores MAY prioritize remediation but MUST NOT override a failed gate.

The orchestrator MUST validate every packet against this schema before accepting the plan. A packet without a worktree allocation, ownership boundary, dependency list, TDD mode, execution risk, verification command, or coverage command is not ready for execution.

The plan MUST maximize safe parallelism without splitting shared ownership. Shared files, generated files, public contracts, and integration tests belong to one owner or a serialized integration packet.

Inspect the plan for conflicting ownership, missing dependencies, and untestable contracts. Present the plan and wait for explicit user acceptance before spawning implementation agents. Accepted responses are explicit confirmations such as `approve`, `approved`, `yes`, or `proceed`; ambiguous responses require clarification. No implementation agent may start before acceptance is recorded.

## Phase 3: Execute the approved plan

After plan acceptance, execute only the approved packets and contracts. Do not reopen discovery or design unless a packet is blocked by information absent from the plan.

Allocate and initialize each ready, non-conflicting implementation packet's isolated worktree according to the concurrency gate. Pass the absolute worktree path to the implementation agent and verify that its working directory is distinct from every other active implementation packet and from the main checkout.

### Execution waves


Spawn ready implementation packets as a single swarm only when worktree isolation can be verified by the invoking harness. If isolation cannot be verified for even one implementation packet, do not launch a parallel implementation wave. Fall back to sequential implementation or stop for user input; **DO NOT parallelize implementation agents within the same worktree.** Read-only agents remain safe to parallelize.

Every implementation-agent prompt MUST be structured for compliance and include, in this order:

1. `MUST NOT DO` — forbidden files, behaviors, commands, and previously failed approaches;
2. `TASK` — one atomic objective;
3. numbered `STEPS` — the exact execution sequence;
4. `EXPECTED OUTCOME` — concrete files and observable behavior;
5. `VERIFY` — the focused command or scenario and required evidence;
6. `CONTEXT` — packet contract, repository context, and constraints.

Keep prompts short enough to follow. Put prohibitions first, use numbered steps instead of prose, and require exact command output rather than a success claim. Never combine strict-TDD RED and GREEN work in one assignment.

Every implementation-agent prompt MUST include:

```text
MUST NOT DO
Do not modify another packet's ownership, reopen approved scope, or run formatters, linters, or project-wide suites during parallel implementation. Include failed approaches that must not be repeated.

TASK
One atomic objective for the exact component packet.

STEPS
Numbered steps in the exact execution order, including the packet's RED, GREEN, and REFACTOR gates when applicable.

EXPECTED OUTCOME
Concrete files changed, observable behavior, focused tests, and >=85% coverage for new additions.

VERIFY
The focused command or behavioral scenario, exact output required, and any repository-context verification.

CONTEXT
Exclusive file/symbol ownership, packet contract, TDD mode, execution risk, dependencies, worktree, branch, repository context, and constraints.
```

Keep dependent packets pending until prerequisites complete. If the harness lacks dependency tracking, the orchestrator enforces the dependency graph from `plan.md`.

Agents MUST:

- preserve unrelated changes;
- add focused tests with the implementation;
- measure coverage for new additions;
- create temporary atomic commits at each independently shippable slice when execution uses committed worktrees;
- ensure every temporary commit builds successfully, passes the relevant focused tests, preserves existing behavior, and is safe to ship or deploy in isolation;
- include commit identity, build/test commands, results, coverage, and evidence for every temporary commit;
- never create a commit that leaves the branch knowingly broken, untested, non-deployable, or dependent on a later commit to avoid a regression;
- keep changes that cannot be independently green in one commit rather than splitting them into broken intermediate commits;
- avoid squashing during EXECUTE or REVIEW; preserve temporary atomic commit history until the human approval gate;
- return evidence, not only a success claim.

Temporary execution commits are implementation transport and evidence, not the final publication history. The integration owner may merge them into the approved branch and MUST squash them only after handoff approval when publication requires a single commit. A harness that cannot transport uncommitted worktree changes MUST use temporary commits or an equivalent verified patch-transfer mechanism.

After each implementation packet completes, record its status, worktree, branch, initialization result, atomic commit range, per-commit build/test evidence, changed files, verification commands, coverage measurement, and evidence path in `execution-results.md` and `state.json`. A packet is complete only when its worktree remains inspectable and every commit is independently green and shippable. Missing evidence is failure, not completion.

## Phase 4: Independent review loop

For the initial review, and for any delta classified as full, use the standalone `review-code` skill. The review owner MUST be fresh and read-only for every full review iteration. For a documentation-only delta, use the targeted delta reviewer defined below instead of invoking the full skill.

Before invoking either reviewer, the integration owner MUST ensure the current range contains the implementation changes beyond the base revision and record the previous and current diff identities.

For a full review, invoke the review owner with the current base/head revisions, the current iteration artifact directory, `REVIEW_ROOT` set to `skills/review-code`, the supplied ticket context, acceptance criteria, and execution evidence. Do not pass `discovery-summary.md`, `plan.md`, component packets, implementation-agent reports or prompts, implementation rationale, expected findings, or prior review conclusions.

The full review owner receives only:

1. the original ticket context from `issue.json`;
2. acceptance criteria and explicitly requested constraints;
3. the current repository diff and changed-file list;
4. raw test and coverage output produced by the execute swarm;
5. repository instructions that apply universally to all code.

The review owner MUST remain read-only, MUST NOT contact implementation agents, and MUST NOT rely on a prior review. Read-only review agents do not need implementation worktrees.

After the `review-code` validator passes, normalize `refined_critique_result.json` into the build review schema in `reviews/iteration-<NNN>.md` and `review-results.md`. Assign internal finding IDs there only; never pass those IDs into source, commits, tickets, pull requests, or user-facing text.

The normalized review is `APPROVED` only when the refined result contains no actionable findings, required evidence is present, the build artifact consistency gate passes, and no findings remain open. Any finding requiring a code, test, design, or documentation change is `NEEDS_FIXES` and triggers EXECUTE → REVIEW. Advisory observations requiring no change may be recorded without blocking approval.

The review owner MUST check:

- ticket acceptance criteria and requested constraints;
- behavior and changed callsites visible from the diff;
- pure-function design, dependency injection, and separation of concerns;
- focused tests for new behavior and important boundaries;
- measured coverage of at least 85% for new additions;
- error handling, security, data integrity, regressions, and unrelated changes;
- repository instructions and checks executed by the swarm.

For each review iteration, write `reviews/iteration-<NNN>.md` using this structure:

```markdown
Status: APPROVED | NEEDS_FIXES
Review mode: FULL | SUBSET
Selected dimensions: correctness, contract, security, maintainability, quality
Excluded dimensions: <dimensions not selected, or none>
Dimension rationale: <why each selected dimension covers the current delta>
Exclusion rationale: <why each excluded dimension is not implicated>
Iteration: <number>
Execution iteration: <number>
Previous diff identity: <prior reviewed commit or diff hash>
Diff identity: <current commit or diff hash>
Delta classification: <behavior | contract | security | persistence | workflow | structure | quality | documentation | tests | metadata | mixed>
Inputs: ticket context, acceptance criteria, current diff, changed-file list, raw execute evidence, universal repository instructions

## Findings


### R-001
- Severity: blocker | high | medium | low
- Category: correctness | security | test | design | scope
- Status: open | resolved | accepted-without-change
- Evidence: <file, diff hunk, or command output>
- Required change: <exact change, or none>
- Resolution evidence: <later execution/review artifact, or none>

## Coverage
New-addition coverage: <percentage or N/A when no executable additions>
Evidence: <command and output artifact, or documentation verification evidence>

## Verification
Commands: <commands run>
Results: <observed results>

## Resolution Summary
- Newly introduced: <finding IDs>
- Resolved since prior review: <finding IDs>
- Still open: <finding IDs>
```

Update `review-results.md` as an index after every review iteration. It MUST link every `reviews/iteration-<NNN>.md`, summarize the status, list newly introduced findings, list findings resolved in that iteration, and list all remaining open findings. Update `state.json` with the same open/resolved finding IDs and artifact paths. Run the artifact consistency gate before accepting the review result. `APPROVED` is valid only when required evidence is present, artifact records agree, and no finding requires a change. Missing or inconsistent evidence is `NEEDS_FIXES`.

### Review delta classification and discretionary redispatch

The build orchestrator decides which review dimensions to run after each execution iteration. Do not dispatch the full swarm merely because the diff changed. Compare the current delta with the previous reviewed diff and select the smallest review dimension set that can credibly detect regressions introduced by the delta.

Every review iteration MUST record:

- `Review mode: FULL | SUBSET`;
- previous and current diff identities;
- delta classification;
- selected dimensions;
- the reason each selected dimension was included;
- verification evidence.

Use these dimensions:

- `correctness`: runtime behavior, state transitions, errors, retries, concurrency, data integrity, and regression risk;
- `contract`: APIs, schemas, types, callers, compatibility, acceptance criteria, migrations, workflows, and user-facing behavior;
- `security`: authorization, authentication, secrets, trust boundaries, input handling, and sensitive data;
- `maintainability`: structure, coupling, duplication, changeability, and long-term operational cost;
- `quality`: clarity, naming, complexity, consistency, and local implementation quality.

The orchestrator MUST select at least the dimensions implicated by the changed files, changed behavior, and resolved findings. It SHOULD select the full set when the delta crosses concerns or when the mapping is uncertain. It MUST select the full set when the delta changes security-sensitive behavior, persistence or migrations, workflow semantics, public contracts plus implementation, shared infrastructure, or multiple independent concerns.

Minimum mapping rules:

- implementation or test changes affecting runtime behavior → `correctness`;
- public API, schema, type, caller, migration, workflow, or acceptance-criteria changes → `contract`;
- authorization, authentication, secrets, trust boundaries, or sensitive-data handling → `security`;
- refactors, ownership changes, coupling, duplication, or structural changes → `maintainability`;
- local complexity, naming, consistency, or readability changes → `quality`;
- a finding's required fix MUST re-run every dimension that originally reported it, plus any dimension implicated by the new delta.

The build MAY exercise discretion within these rules. It MUST record the rationale and MUST default to the full set when it cannot confidently exclude a dimension. A subset review is not a lower-quality review; it is a scoped review of the changed risk surface.

The selected dimensions are passed to the review skill as `REVIEW_DIMENSIONS`, a comma-separated list. The review skill runs exactly those critique agents, validates exactly those artifacts, and runs the challenge pass over the selected set.

If the delta is metadata-only and no finding or acceptance criterion is affected, no reviewer dispatch is required; record the unchanged review identity and verification state. Otherwise, even documentation, test-only, or implementation-only changes receive a subset review when the mapping permits it.

If a reviewer returns `NEEDS_FIXES` or any finding requiring a code, test, design, or documentation change:

1. Keep the workflow in REVIEW until the finding is captured in `reviews/iteration-<NNN>.md`.
2. Add every new finding to `state.json.findings.open` and the `review-results.md` index.
3. Return to EXECUTE.
4. Assign each required change to its owning packet or the delegated integration owner.
5. Write `execution/iteration-<NNN>.md` with the packet changes, worktrees, commands, coverage, and evidence.
6. Mark findings resolved only when the repair evidence directly addresses them; move their IDs from `open` to `resolved` only after the next review confirms resolution.
7. Reclassify the new delta and select dimensions using the rules above. Do not automatically repeat the previous full swarm.
8. Repeat until the selected review mode returns `APPROVED` with no open findings.

There is no separate final-check phase. Execute evidence is reviewed as part of the EXECUTE → REVIEW loop. Do not ask the user to approve a known failing review or enter handoff with unresolved findings, inadequate coverage, or unverified fixes.

## Phase 5: Handoff, human approval, and publication

Only after an `APPROVED` review:

1. Assign integration to the delegated integration owner. Ensure all implementation changes are represented by frequent atomic commits; do not squash before human approval.
2. Verify every commit in the reviewed range has build/test evidence, is independently shippable, and that the committed tree matches the approved review. Any content change returns to EXECUTE → REVIEW.
3. Verify the current branch is non-detached, differs from its base, contains at least one commit beyond its base, and has a clean working tree and index. Record the atomic commit range, base revision, diff identity, and evidence in `execution-results.md` and `state.json`.
4. Create `handoff.md` containing the issue ID, outcome, changed behavior, files, contract and migration notes, coverage evidence, verification evidence, review iterations, limitations, follow-ups, atomic commit range, diff identity, and an optional `Workflow Improvement Signals` section recording observed waste, manual steering, review redispatch decisions, artifact inconsistencies, and candidate workflow improvements.
5. Transition to `WAIT_FOR_HANDOFF_APPROVAL` and present the handoff. Publishing a pull request is the DEFAULT outcome: the presentation states a PR will be created after approval, and the user opts out only explicitly. The orchestrator MUST NOT treat silence or the absence of a PR request as a local-only choice. Ambiguous responses require clarification; requested changes return to EXECUTE → REVIEW. Continue only after explicit human approval (`approve`, `approved`, `yes`, or `proceed`).
6. If the user explicitly opts out of PR creation, complete the handoff locally without rewriting commit history and record the opt-out in `state.json` and `handoff.md`.
7. When the default applies (no opt-out) and the repository uses GitHub, transition to `SQUASH`. The delegated integration owner MUST squash the approved atomic commit range into exactly one commit without changing the reviewed tree, then verify the new commit's diff identity, clean worktree, base, branch, and commit count.
8. Update `state.json`, `execution-results.md`, and `handoff.md` with the squash commit and verification evidence. A changed content diff invalidates approval and returns to EXECUTE → REVIEW.
9. Invoke the standalone `create-pr` skill only after the single-commit invariant and handoff checks pass. Pass `ISSUE_CONTEXT`, `HANDOFF_FILE`, and generic `REVIEW_EVIDENCE`; the build workflow owns approval, while `create-pr` only publishes.

10. After handoff and any requested publication complete, derive `Workflow Improvement Signals` deterministically from the local workflow artifacts. Record a material signal when any of these predicates is true:
   - `reviewIteration >= 2` and at least one finding was introduced after the first review;
   - the review artifact records external feedback not represented in the internal findings;
   - the same packet has an execution attempt with `result: failed` and a later retry;
   - artifact consistency validation failed and required a correction;
   - the handoff records contradictory, non-portable, or missing identity/evidence fields;
   - explicit user steering changed the workflow contract rather than merely resolving a ticket detail.
   Do not emit a signal for an isolated agent error that was corrected in the same iteration, expected review findings, successful execution, or an empty signal section. Standing filter: record a signal only when the underlying lesson is NOT repo-, service-, or ticket-specific — a signal whose evidence only makes sense for this repository's layout, migrations, databases, trackers, or ticket scope is not a workflow signal; drop it rather than tagging it on. Persist each emitted signal with `predicate`, `evidence`, and `artifact` fields in `state.json`, `execution-results.md`, and `handoff.md`.
11. If material signals exist, present the signals briefly and ask one yes/no question: whether to invoke `improve` on the completed build. If the user agrees, invoke `improve` with the current build artifact directory and inject the recorded signals as context; do not ask the user to provide build paths or repeat parameters. If the user declines, record the decision and finish the build. Improve is optional and MUST NOT reopen the completed ticket unless the user explicitly requests implementation changes.
12. If no material signals exist, do not ask about `improve` and finish normally.
The workflow is complete only when the human-approved handoff is complete and, when requested, the single-commit pull request is successfully published. An optional improve run may follow; it does not change build completion status.
 


Resume from artifacts and repository state, not session-specific environment variables:

1. Read `issue.json`, `state.json`, and all existing artifacts.
2. Inspect the current diff and every active worktree.
3. Determine the state-machine phase from the latest valid artifact and evidence.
4. Re-run missing or invalidated work only.
5. Preserve the review loop: any change after approval invalidates approval and requires a fresh review.

## Failure handling

- **Configured tracker CLI/auth unavailable:** stop before implementation and report the exact prerequisite.
- **Missing linked design material:** continue only when requirements are sufficient; otherwise ask for it.
- **Missing worktree procedure:** do not parallelize implementation agents; ask for a documented mechanism or execute sequentially.
- **Worktree collision or wrong working directory:** stop the affected implementation wave, preserve changes, and re-bootstrap before retrying.
- **Agent failure:** preserve changes, record the failure, and retry or reassign the same packet.
- **Ownership conflict:** stop conflicting work and route the files through the delegated integration owner.
- **Coverage below 85% for new additions:** remain in EXECUTE, add tests or revise design, then review again.
- **Review finding:** mandatory EXECUTE → REVIEW flap.
- **Publishing failure:** preserve verified local work and report the exact failed handoff operation.
