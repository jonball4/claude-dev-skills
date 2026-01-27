---
argument-hint: <ticket-id or jira-url>
description: Initialize orchestrated 5-phase workflow using multi-agent execution
---

I'm starting implementation work on ticket: $ARGUMENTS

**I am the ORCHESTRATOR.** My role: spawn phase agents, monitor artifacts, coordinate execution, handle failures.

## Resuming This Workflow

If interrupted: `CLAUDE_CODE_TASK_LIST_ID=<task-list-id> claude` then use TaskList to continue.

---

## Step 1: Extract Ticket ID

Extract from $ARGUMENTS: URL `${JIRA_BASE_URL}/browse/PX-1234` → **PX-1234**, or text "work on PX-1234" → **PX-1234**. If unclear, ask user.

---

## Step 2: Fetch Ticket Details (if JIRA MCP available)

```javascript
getJiraIssue(cloudId: "...", issueIdOrKey: "PX-1234")
// Extract: Title, Description, Acceptance criteria, Priority, Documentation links
```

---

## Step 3: Check for Technical Design Document (TDD)

**If Jira description references a TDD document:**

Ask user:
```
📄 Jira ticket references a Technical Design Document.

Please provide the TDD in markdown format, "skip" if no TDD available.

Reply with TDD source or "skip":
```

**If TDD provided:** URL → WebFetch or ask user to save; file path → copy to `~/.claude/work/PX-1234/TDD.md`; inaccessible → ask user to save. Discovery and Planning agents will use it.

---

## Step 4: Initialize Task List with 5 Phases

🚨 **MANDATORY TOOL INVOCATION - YOU MUST DO THIS NOW** 🚨

**STOP. You MUST invoke TaskCreate tool 5 times before proceeding.**

This is NON-NEGOTIABLE. Do NOT describe what you will do. Do NOT skip this step.

### Artifact Structure Overview

Agents write artifacts to `~/.claude/work/$TICKET_ID/` directory.

See [workflow-definitions/shared/ARTIFACTS.md](../workflow-definitions/shared/ARTIFACTS.md) for complete structure and file format requirements.

**Phase 1:**
```javascript
TaskCreate({
  subject: "Phase 1: Discovery - PX-1234",
  description: "Gather context from Jira, Confluence, codebase. Requirements in .claude/workflow-definitions/implement-v2/phase1-discovery.md",
  activeForm: "Performing discovery on system and codebase"
})
```

**Phase 2:**
```javascript
TaskCreate({
  subject: "Phase 2: Planning - PX-1234",
  description: "Design approach, create component work packages. Requirements in .claude/workflow-definitions/implement-v2/phase2-planning.md",
  activeForm: "Planning implementation approach"
})
```

**Phase 3:**
```javascript
TaskCreate({
  subject: "Phase 3: Execution - PX-1234",
  description: "Parallel component implementation with test-driven-development. Requirements in .claude/workflow-definitions/implement-v2/phase3-execution.md",
  activeForm: "Implementing feature with test-driven-development"
})
```

**Phase 4:**
```javascript
TaskCreate({
  subject: "Phase 4: Review - PX-1234",
  description: "Integration testing and quality validation. Requirements in .claude/workflow-definitions/implement-v2/phase4-review.md",
  activeForm: "Reviewing and verifying implementation"
})
```

**Phase 5:**
```javascript
TaskCreate({
  subject: "Phase 5: Handoff - PX-1234",
  description: "PR creation and documentation. Requirements in .claude/workflow-definitions/implement-v2/phase5-handoff.md",
  activeForm: "Creating PR and handoff documentation"
})
```

**Store task IDs returned for use in TaskUpdate calls.**

---

## Step 5: Start Phase 1 (Discovery)

🚨 **MANDATORY: Mark Phase 1 in_progress, then spawn agent NOW:**

```javascript
TaskUpdate({ taskId: [Phase 1 task ID], status: "in_progress" })
```

```javascript
Task(
  subagent_type: "general-purpose",
  description: "Discovery for PX-1234",
  prompt: `Discovery agent for PX-1234: [TICKET_TITLE]

Context: [Jira details], [TDD at ~/.claude/work/PX-1234/TDD.md if available]
Mission: Follow .claude/workflow-definitions/implement-v2/phase1-discovery.md
Deliverable: ~/.claude/work/PX-1234/discovery-summary.md
Task tracking: TaskCreate per discovery area, TaskUpdate when complete
`
)
```

Monitoring discovery agent progress...

**When discovery agent completes:**

1. 🚨 **VERIFY FILE EXISTS:**
   ```javascript
   Read({ file_path: "~/.claude/work/PX-1234/plans/discovery-summary.md" })
   ```
   **If missing:** Report failure, ask "Retry? (yes/no)", DO NOT proceed.

2. Read discovery-summary.md, present summary (5-10 lines)
3. Ask: "Phase 1 complete. Review: ~/.claude/work/PX-1234/plans/discovery-summary.md. Approve Phase 2? Reply 'yes'."
4. Wait for approval

---

## Step 6: Phase 2 (Planning) - After User Approval

🚨 **MANDATORY: Complete Phase 1, start Phase 2, spawn agent NOW:**

```javascript
TaskUpdate({ taskId: [Phase 1 task ID], status: "completed" })
TaskUpdate({ taskId: [Phase 2 task ID], status: "in_progress" })
```

```javascript
Task(
  subagent_type: "general-purpose",
  description: "Planning for PX-1234",
  prompt: `Planning agent for PX-1234: [TICKET_TITLE]

Context: discovery-summary.md, TDD.md (if available), Jira PX-1234
Mission: Follow .claude/workflow-definitions/implement-v2/phase2-planning.md
Deliverables: INDEX.md (contracts/architecture), components/*.md (work packages)
Task tracking: TaskCreate per component, TaskUpdate when complete
`
)
```

Monitoring planning agent progress...

**When planning agent completes:**

1. 🚨 **VERIFY ALL FILES EXIST:**
   ```javascript
   Read({ file_path: "~/.claude/work/PX-1234/plans/INDEX.md" })
   Bash({ command: "ls -1 ~/.claude/work/PX-1234/plans/components/*.md 2>/dev/null | wc -l" })
   ```
   **If INDEX.md missing OR component count is 0:** Report failure (list what's missing), ask "Retry? (yes/no)", DO NOT proceed.

2. Read INDEX.md, list components: `ls -1 ~/.claude/work/PX-1234/plans/components/*.md`
3. Read each component file, verify completeness. **If incomplete:** Ask "Accept or retry? (accept/retry)"

4. 🚨 **CREATE COMPONENT TASKS:** For each *.md in components/:
   ```javascript
   TaskCreate({
     subject: "Implement [component-name] - PX-1234",
     description: "TDD implementation. Work package: ~/.claude/work/PX-1234/plans/components/[component-name].md",
     activeForm: "Implementing [component-name] with TDD"
   })
   ```
   Store task IDs for dependency linking.

5. Present plan summary: X components, list names, show dependency graph, location: ~/.claude/work/PX-1234/plans/

6. Ask: "Phase 2 artifacts complete. Created X component tasks (pending dependency linking). Review: INDEX.md and components/. Approve for Phase 3? Reply 'yes'."

7. Wait for approval

**IMPORTANT: Phase 2 is NOT complete yet. After user approval:**
- Link component task dependencies (Step 9)
- Mark Phase 2 task as completed (Step 10)
- Then transition to Phase 3

---

## Step 6b: Complete Phase 2 - After User Approval

9. 🚨 **LINK DEPENDENCIES:** Read dependency graph from INDEX.md. For each component with dependencies:
   ```javascript
   // Example: service-layer depends on repository-layer
   TaskUpdate({
     taskId: [service-layer task ID],
     addBlockedBy: [[repository-layer task ID]]
   })
   ```

10. 🚨 **TRANSITION TO PHASE 3:**
    ```javascript
    TaskUpdate({ taskId: [Phase 2 task ID], status: "completed" })
    TaskUpdate({ taskId: [Phase 3 task ID], status: "in_progress" })
    ```

11. Inform user: "✅ Phase 2 complete. Dependencies linked. Transitioning to Phase 3."

---

## Step 7: Phase 3 (Execution) - Parallel Component Agents

Components (repository, service, API, Kafka) run in parallel. TDD cycle: SCAFFOLDING → MOCKS → RED → GREEN → COMMIT. Details: `.claude/workflow-definitions/implement-v2/phase3-execution.md`

Read INDEX.md to identify components:
```javascript
Read({ file_path: "~/.claude/work/PX-1234/INDEX.md" })
```

🚨 **MARK COMPONENTS IN_PROGRESS, SPAWN AGENTS (ALL IN SINGLE MESSAGE):**

```javascript
// For each component:
TaskUpdate({ taskId: [component task ID], status: "in_progress" })
```
```javascript
// For each component in INDEX.md:
Task(
  subagent_type: "general-purpose",
  description: "Implement [component-name] for PX-1234",
  prompt: `Component agent: [component-name] (PX-1234)

COMPONENT_TASK_ID: [component task ID from Step 6]
Context: INDEX.md (contracts), components/[component-name].md (work package)
Mission: Follow .claude/workflow-definitions/implement-v2/phase3-execution.md (replace $TICKET_ID with PX-1234, $COMPONENT_NAME with [component-name])

Task tracking: On success → TaskUpdate({ taskId: [COMPONENT_TASK_ID], status: "completed" }). On failure → leave in_progress, report error.

TDD cycle: RED → GREEN → Commit. ONE atomic commit. GPG signing REQUIRED (report failure immediately).
`
)
```

**Execution strategy:** Continue-on-failure. Agents run to completion, collect results, report: "X/Y succeeded, Z failed: [list]"

**GPG failure:** Pause, present failure, wait for "retry [component]" or "retry all", respawn when ready.

**When complete:**
1. Check TaskList to verify which components completed
2. Report: "X/Y succeeded" (or "Z failed: [list]")
3. Failed components stuck in "in_progress"
4. If failures: Ask "Retry failed components? (retry all / retry [component] / proceed partial / abort)"
5. If success or user approves partial: transition to Phase 4 (Step 8)

---

## Step 8: Phase 4 (Review) - Integration Testing

🚨 **TRANSITION TO PHASE 4, INVOKE /requesting-code-review SKILL NOW:**

```javascript
TaskUpdate({ taskId: [Phase 3 task ID], status: "completed" })
TaskUpdate({ taskId: [Phase 4 task ID], status: "in_progress" })
```

```javascript
Skill({ skill: "superpowers:requesting-code-review", args: "PX-1234" })
```

The /requesting-code-review skill spawns Review agent, validates against plan/standards, runs integration tests, checks coverage, writes review-results.md, returns APPROVED or NEEDS_FIXES.

**After /requesting-code-review completes:**
1. Read review-results.md, present summary
2. If APPROVED: Ask "Phase 4 complete. Tests passing. Approve Phase 5? Reply 'yes'."
3. If NEEDS_FIXES: Report failures, ask for guidance (fix manually/debug/abort)

---

## Step 9: Phase 5 (Handoff) - PR Creation

🚨 **TRANSITION TO PHASE 5, SPAWN HANDOFF AGENT NOW:**

```javascript
TaskUpdate({ taskId: [Phase 4 task ID], status: "completed" })
TaskUpdate({ taskId: [Phase 5 task ID], status: "in_progress" })
```

```javascript
Task(
  subagent_type: "general-purpose",
  description: "Create PR for PX-1234",
  prompt: `Handoff agent for PX-1234: [TICKET_TITLE]

Context: INDEX.md, discovery-summary.md, review-results.md
Mission: Follow .claude/workflow-definitions/implement-v2/phase5-handoff.md

The handoff agent will:
1. Review all workflow artifacts for context
2. Invoke the create-pr skill to analyze commits and create PR
3. Verify PR description aligns with workflow artifacts
4. Report PR URL and context dump

The create-pr skill handles commit analysis, PR description generation, and gh CLI execution.
`
)
```

**When complete:**
1. Present PR URL from handoff agent
2. Mark Phase 5 completed: `TaskUpdate({ taskId: [Phase 5 task ID], status: "completed" })`
3. Workflow complete!

---

## Error Recovery

**GPG failures:** Report "🚨 GPG FAILURE: [component]. Code complete ✅ | Tests pass ✅ | Commit signed ❌. Changes preserved. Reply 'retry [component]' when ready."

User commands: `retry [component]`, `retry all`, `status`

**Agent failures:** Report what failed, error details, next steps (retry/manual fix/abort).

**Phase blocking:** GPG/test failures BLOCK phase transitions. Cannot proceed without resolution.

---

## Cross-Session Resumption

To resume: `CLAUDE_CODE_TASK_LIST_ID=<task-list-id> claude` then use TaskList to see current phase.

---

## Important Notes

- Orchestrator stays lean; agents do heavy lifting
- Artifacts drive workflow (agents communicate via files)
- Parallel execution (components run simultaneously)
- GPG signing non-negotiable (hard stops on failures)
- User approval required between phases
