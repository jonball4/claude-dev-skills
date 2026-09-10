---
name: improve
description: Analyze a completed build execution and turn evidence-backed steering, review feedback, execution failures, and user corrections into safe improvements to repository- and service-agnostic development workflow skills. Use when asked to improve the workflow, learn from a completed build, reduce repeated agent waste, or extract process changes from build artifacts.
argument-hint: ARTIFACT_DIR-or-build-ID
---

# Improve

Improve the development workflow from evidence, not intuition. This skill is an optional post-build process. It consumes a completed build's durable artifacts plus explicit user steering and produces a bounded workflow-improvement proposal. It may apply changes to workflow skills only after the user approves the proposed changes.

The workflow is repository- and service-agnostic. It MUST reason from supplied artifacts and repository instructions, never from assumed languages, frameworks, issue trackers, hosting providers, source-tree layouts, service names, or deployment platforms. Repository-specific context and rules remain inputs owned by the repository. Do not encode them into a personal skill.

Use this skill after a build reaches `HANDOFF`, `APPROVED`, or another terminal state with sufficient artifacts. It may also run after a branch or pull request receives external review feedback, including automated review, human review, CI, or post-merge findings. It produces a bounded workflow-improvement proposal. It may apply changes to workflow skills only after the user approves the proposed changes.
The invoking harness must provide equivalent capabilities for reading artifacts, inspecting external feedback, editing workflow files only after approval, running validation commands, and asking for approval. Capability names and tool schemas are harness-specific; this skill defines workflow outcomes, evidence, and safety boundaries rather than a tool API.

## Scope

Use this skill to improve workflow instructions and validation resources supplied by the caller, normally:

- the build orchestration skill;
- the review skill and its scripts;
- review prompts;
- the pull-request or publication skill;
- optional execution references.

Resolve actual target paths from the current harness and caller context. Do not hard-code a repository, service, issue tracker, language, framework, or provider.

It MUST NOT silently change repository source code, ticket scope, product behavior, review findings, PR content, or historical build artifacts. It MUST NOT convert one ticket-specific preference into a global workflow rule without evidence that the lesson generalizes.

## Inputs

The caller should provide:

- `BUILD_DIR`: completed build artifact directory supplied by the caller;
- optional `STEERING`: user corrections, observed inefficiencies, or desired workflow behavior;
- optional `EXTERNAL_FEEDBACK`: review URL, review comments, CI findings, post-merge defects, or human feedback;
- optional `TARGET_SKILLS`: the build, review, review-prompt, or publication workflow targets selected by the caller.

If only a build ID is supplied, locate it using the repository's documented artifact convention. If external feedback is a review URL, read the provider's available metadata, body, review summaries, inline comments, and current diff. Do not assume a particular provider or fetch a new ticket. Do not infer missing requirements when the build artifacts are incomplete.

## Required artifact assessment

Read, when present:

- `state.json`;
- `plan.md`;
- `issue.json`;
- `discovery-summary.md`;
- `execution-results.md`;
- every `execution/iteration-*.md`;
- `review-results.md`;
- every `reviews/iteration-*.md`;
- `handoff.md`;
- referenced raw review artifacts, including `critique_result.json`, `refined_critique_result.json`, challenge output, and per-dimension results.

Assess artifact sufficiency before drawing conclusions.

### Sufficient evidence

The build is sufficiently evidenced when the artifacts establish:

- terminal or current workflow state;
- approved scope and acceptance criteria;
- execution iterations and changed files;
- verification commands and observed results;
- review iterations, findings, severities, and resolution history;
- the final handoff and final diff/commit identity;
- enough raw review detail to distinguish dimension-specific misses from orchestration mistakes.

### Insufficient evidence

Report gaps explicitly when any of these apply:

- review artifacts are referenced but unavailable;
- final state claims a review iteration whose artifact is missing;
- `state.json` conflicts with execution/review indexes;
- worktree, branch, commit, or diff identities are contradictory;
- findings are summarized without their original severity/category/location;
- steering or user corrections are absent;
- a workflow failure cannot be separated from a ticket-specific failure.

Continue with bounded recommendations when possible. Do not fabricate missing evidence or claim a workflow defect solely from an incomplete artifact.

## Workflow

### 1. Establish the baseline

Confirm the build's phase, plan acceptance, execution iterations, review iterations, findings, final verification, and handoff status. Build a compact evidence table:

| Evidence | Observed fact | Artifact | Confidence |
|---|---|---|---|
| Execution | ... | ... | high/medium/low |
| Review | ... | ... | high/medium/low |
| Steering | ... | ... | high/medium/low |

### 2. Extract improvement signals

Classify each signal as one or more of:

- `waste`: unnecessary agents, repeated review work, excessive context, or avoidable token/time cost;
- `miss`: a required check, artifact, or review dimension was absent or ineffective;
- `failure`: a command, agent, worktree, artifact, or state transition failed;
- `friction`: the workflow required manual correction or ambiguous orchestration;
- `drift`: implementation or PR content diverged from the approved plan or handoff;
- `quality`: a result was technically valid but could be more reliable, precise, or maintainable.

Separate:

- ticket-specific issues;
- agent execution mistakes;
- orchestration-policy defects;
- missing tooling or artifact-schema defects.

Only the last two categories normally justify changing a personal workflow skill.

### 3. Compare external feedback with internal review

When `EXTERNAL_FEEDBACK` is supplied, reconcile it against the build's final review artifacts:

| Question | Result |
|---|---|
| Was the external finding present internally? | yes / no / partially |
| Which review dimension should have found it? | correctness / contract / security / maintainability / quality |
| Was that dimension selected and completed? | yes / no |
| Did the internal review explicitly inspect the relevant boundary or state matrix? | yes / no |
| Was the finding caused by missing context, weak rubric, stale diff, or reviewer error? | classification |
| What smallest workflow change reduces recurrence? | proposed rule |

Treat an external finding missed by a completed internal review as a `miss`, even when the finding is low severity. Do not conclude that the five-agent structure is sufficient merely because every selected critic returned a valid artifact. Distinguish:

- **coverage miss:** the implicated dimension was not selected;
- **rubric miss:** the dimension ran but did not require the relevant boundary, state, input-combination, or contract check;
- **evidence miss:** the reviewer lacked a required file, callsite, test output, or external context;
- **reviewer miss:** the rubric and evidence were sufficient but the reviewer failed to identify the issue.

For a rubric or evidence miss, propose a prompt, input, or artifact change. For a reviewer miss, propose a targeted challenge or mandatory scenario check before adding more parallel critics. For a coverage miss, improve build dimension selection.

### 4. Derive the smallest general rule

For every candidate improvement, record:

```markdown
## Candidate
Problem: <observable workflow problem>
Evidence: <artifact path and exact observation>
Generalization: <why this applies beyond this ticket>
Proposed owner: build | review | create-pr | script | none
Proposed rule: <smallest enforceable change>
Expected benefit: <time, token, quality, or reliability benefit>
New cost: <latency, complexity, coverage risk, or user friction>
Rejected alternative: <larger or weaker rule not chosen>
```

Prefer a deterministic gate or artifact field over prose guidance when the same mistake can recur. Prefer a subset review, targeted check, or changed prompt over a full-workflow redesign when only one risk surface changed.

### 4. Decide whether the evidence supports change

Use this decision policy:

- one isolated agent mistake: improve the prompt or record a warning, not the workflow contract;
- repeated mistake or user correction across iterations: propose a workflow rule;
- missing evidence caused by the artifact schema: improve the schema and validator;
- unnecessary full review caused by an over-broad dispatch rule: improve dimension selection and review invocation;
- unresolved ambiguity that tools cannot settle: ask the user one focused question;
- contradictory artifacts: propose validation/fail-closed behavior before adding quality policy.

Never optimize away a review dimension solely to save tokens when the changed risk surface still implicates that dimension. The improvement must preserve correctness and review coverage.

### 5. Produce the improvement report

Write a report under the build directory when writable:

```text
improvements/<timestamp>-improve.md
```

The report MUST contain:

- artifact sufficiency assessment;
- observed build timeline;
- user steering and corrections;
- confirmed workflow problems;
- candidate improvements with evidence;
- recommended changes and exact target files/sections;
- rejected alternatives;
- expected benefit and risk;
- validation plan;
- whether approval is required before applying changes.

Do not overwrite build artifacts or prior improvement reports.

### 6. Apply only after approval

Present the recommended changes before editing personal skills. On explicit approval:

1. re-read each target skill and current script before editing;
2. make the smallest surgical changes;
3. preserve existing contracts unless the report explicitly changes them;
4. validate Markdown/frontmatter and run applicable script syntax or smoke checks;
5. report changed files, evidence, and any remaining artifact gaps.
### Change-set provenance

Every applied improvement MUST record in the report and in the change summary:

- source `BUILD_DIR` and the build artifact state/diff identity;
- external feedback source, when supplied;
- target skill and script paths;
- before and after content hashes;
- recommendation/candidate identifiers applied;
- validation commands and observed results.

An improvement report MUST distinguish proposed changes from changes actually applied. Do not claim application from a proposal alone.


If the user explicitly invokes `improve --apply`, approval is implied for the recommended changes only; do not expand scope during application.

## Build integration

A completed build invokes this skill without requiring the user to supply parameters. The build caller passes the completed artifact directory and injects the material `Workflow Improvement Signals` as context. The user only decides whether to invoke the optional improvement run.

Direct invocation is also supported:

```text
/improve <artifact-directory-or-build-id>
```

The build handoff SHOULD include an optional section:

```markdown
## Workflow Improvement Signals
- Observed waste:
- Manual steering:
- Review redispatch decisions:
- Artifact inconsistencies:
- Candidate workflow improvements:
```

This section records evidence for the next improve run; it does not itself change workflow policy. The build MUST NOT ask about `improve` when this section is empty or contains only non-material signals.

## Output contract

Return:

- `artifact_sufficiency`: `sufficient | partial | insufficient`;
- `build_dir`;
- `observations`: evidence-backed workflow observations;
- `recommended_changes`: bounded changes grouped by target skill;
- `unresolved_gaps`;
- `approval_required`: boolean;
- `report_path`, when written.

Do not claim that a workflow improved until the target skill files and any scripts were actually changed and validation passed.
