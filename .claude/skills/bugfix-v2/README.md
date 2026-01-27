# bugfix-v2 Skill

6-phase orchestrated workflow for bug fixing using multi-agent execution with root cause analysis and test-driven development.

## Overview

The bugfix-v2 skill orchestrates a complete bug fix workflow from Jira bug report to merged PR. It extends the implement-v2 workflow with dedicated phases for systematic debugging and root cause documentation.

## When to Use

✅ **Use bugfix-v2 when:**
- Fixing bugs reported in Jira
- Need systematic debugging before implementing fixes
- Want root cause analysis documented in PRs
- Require regression test validation
- Multiple components may be affected by the bug

❌ **Don't use bugfix-v2 for:**
- New feature implementation (use [implement-v2](../implement-v2/README.md) instead)
- Simple typo fixes
- Obvious one-line changes

## Key Differences from implement-v2

| Aspect | implement-v2 | bugfix-v2 |
|--------|--------------|-----------|
| **Phases** | 5 phases | 6 phases |
| **Phase 2** | Planning | Root Cause Analysis (debugging) |
| **Phase 3** | Execution | Solution Design (minimal fix) |
| **Testing** | Feature tests | Regression tests + verification |
| **PR Content** | Feature description | Includes root cause summary |
| **Debugging** | Not allowed | Allowed in Phase 2 (temporary mods) |

## Architecture

### Orchestration Pattern

```
ORCHESTRATOR (you)
    ↓
    ├─ DISCOVERY AGENT        → discovery-summary.md
    ├─ ROOT CAUSE AGENT       → root-cause-analysis.md (allows debugging)
    ├─ SOLUTION DESIGN AGENT  → INDEX.md + components/*.md
    ├─ COMPONENT AGENTS       → TDD implementation (parallel)
    ├─ REVIEW AGENT           → review-results.md (with regression tests)
    └─ HANDOFF AGENT          → pr-description.md + PR (with root cause)
```

### Workflow Phases

| Phase | Purpose | Agent | Artifacts | User Gate |
|-------|---------|-------|-----------|-----------|
| 1. Discovery | Gather context from bug report/codebase | Explore agent | `discovery-summary.md` | Approve to proceed |
| 2. Root Cause | Debug and identify exact bug location | General-purpose (debugging allowed) | `root-cause-analysis.md` | Approve analysis |
| 3. Solution Design | Design minimal fix approach | General-purpose | `INDEX.md`, `components/*.md` | Approve solution |
| 4. Execution | Parallel TDD implementation with regression tests | Multiple general-purpose | Committed code | Auto (continue-on-failure) |
| 5. Review | Verify bug fixed, run regression tests | Code review skill | `review-results.md` | Approve if passing |
| 6. Handoff | PR creation with root cause documentation | General-purpose | `pr-description.md`, PR | None (complete) |

## Usage

### Starting a New Bug Fix

```bash
# With ticket ID
/bugfix-v2 BUG-456

# With Jira URL
/bugfix-v2 https://yourorg.atlassian.net/browse/BUG-456
```

### The Workflow

#### Step 1: Ticket Context
The orchestrator extracts the ticket ID and fetches bug report details from Jira (if Atlassian MCP is available).

#### Step 2: Technical Context (Optional)
If the Jira ticket references a TDD or technical document, you'll be prompted to provide it (similar to implement-v2).

#### Step 3: Phase 1 - Discovery

Discovery agent explores:
- Bug report details (steps to reproduce, expected vs actual behavior)
- Related issues and historical fixes
- Codebase areas likely affected

**Deliverable:** `~/.claude/work/BUG-456/plans/discovery-summary.md`

**Approval Gate:** Review summary, reply "yes" to proceed

#### Step 4: Phase 2 - Root Cause Analysis

Root cause agent debugs the issue:
- Reproduces the bug (if reproduction steps provided)
- Traces execution flow
- Identifies exact location (file:line precision)
- Documents what's broken and why

**Debugging Allowed:** This phase permits temporary code modifications (adding logs, breakpoints, test cases) to understand the bug.

**Deliverable:** `~/.claude/work/BUG-456/plans/root-cause-analysis.md`

Required contents:
- Exact location of bug (file:line)
- What's broken (incorrect logic, missing validation, etc.)
- Why it's broken (root cause explanation)
- How to reproduce
- Impact analysis (what else might be affected)

**Approval Gate:** Review root cause analysis, reply "yes" to proceed

#### Step 5: Phase 3 - Solution Design

Solution design agent creates minimal fix plan:
- Design approach focused on minimal changes
- Break down into components (if multi-file fix)
- Create work packages with regression test requirements
- Map dependencies

**Philosophy:** Minimal changes to fix the bug, avoid over-engineering

**Deliverables:**
- `~/.claude/work/BUG-456/plans/INDEX.md`
- `~/.claude/work/BUG-456/plans/components/component-name.md` (one per component)

**Approval Gate:** Review solution, reply "yes" to proceed

After approval, orchestrator:
- Creates component tasks (one per work package)
- Links dependencies based on INDEX.md
- Transitions to Phase 4

#### Step 6: Phase 4 - Execution

Multiple component agents run **in parallel**, each following TDD cycle with regression focus:

```
SCAFFOLDING (if new code needed)
    ↓
MOCKS (if new interfaces needed)
    ↓
RED (write regression test that reproduces bug)
    ↓
GREEN (implement fix to pass regression test)
    ↓
COMMIT (atomic: regression test + fix + existing tests)
```

**Regression Tests:** Each component must include a test that:
1. Reproduces the original bug (would fail before fix)
2. Passes after fix is applied
3. Prevents regression in future

**Strategy:** Continue-on-failure (same as implement-v2)

**GPG Failures:** Components preserve work and allow retry (same as implement-v2)

#### Step 7: Phase 5 - Review

Review agent validates:
- Bug is fixed (runs reproduction steps from root-cause-analysis.md)
- Regression tests pass
- All existing tests still pass
- No new bugs introduced
- Code coverage maintained

**Deliverable:** `~/.claude/work/BUG-456/review-results.md`

**Result:** APPROVED or NEEDS_FIXES

**Approval Gate:** If APPROVED, reply "yes" to proceed to handoff

#### Step 8: Phase 6 - Handoff

Handoff agent:
1. Reviews workflow artifacts (INDEX.md, discovery-summary.md, **root-cause-analysis.md**, review-results.md)
2. Invokes **create-pr skill** to:
   - Analyze all commits from base branch to current HEAD
   - Extract technical decisions from commit history
   - Generate comprehensive PR description with:
     - Summary and motivation
     - Key technical decisions with reasoning
     - Testing and verification details
   - Push branch if needed
   - Create PR using `gh pr create`
3. **CRITICAL:** Enhances PR description with root cause analysis section:
   - Bug location (file:line)
   - Why the bug occurred
   - How the fix addresses the root cause
   - Regression test validation
4. Outputs context dump with decision record and verification evidence

**Deliverable:**
- Created PR with auto-generated description + root cause analysis (URL provided)
- Context dump in chat for future reference

**Integration:** The create-pr skill handles commit analysis and base PR generation, while the handoff agent adds bug-specific root cause documentation from Phase 2 analysis.

**Workflow Complete!** 🎉

## Resuming Interrupted Work

Same as implement-v2:

```bash
# Resume with task list ID
CLAUDE_CODE_TASK_LIST_ID=<task-list-id> claude
```

Then check current state:

```bash
TaskList
```

## Artifacts Reference

All artifacts are stored in `~/.claude/work/$BUG_ID/`:

```
~/.claude/work/BUG-456/
├── TDD.md                         # (optional) Technical context
├── plans/
│   ├── discovery-summary.md       # Phase 1 output
│   ├── root-cause-analysis.md     # Phase 2 output (critical!)
│   ├── INDEX.md                   # Phase 3 architecture/contracts
│   └── components/
│       ├── validation-fix.md      # Component work packages
│       └── error-handling-fix.md
├── review-results.md              # Phase 5 output
└── pr-description.md              # Phase 6 output (includes root cause)
```

### root-cause-analysis.md Format

```markdown
# Root Cause Analysis: BUG-456

## Bug Location

**File:** `service/trade/order/validator.go`
**Line:** 127
**Function:** `ValidateOrderAmount()`

## What's Broken

The validator incorrectly allows negative order amounts due to missing validation check.

## Why It's Broken

The validation function only checks for zero amounts but doesn't validate for negative values:

```go
// Current (broken) code
if amount == 0 {
    return errors.New("amount cannot be zero")
}
// Missing: negative amount check
```

## Root Cause

When the validation logic was originally implemented, the assumption was that the input
type (uint64) would prevent negatives. However, after migration to decimal.Decimal type,
this assumption was invalidated but validation wasn't updated.

## How to Reproduce

1. Submit order with amount: -100.00
2. Validation passes incorrectly
3. Order gets created with negative amount

## Impact Analysis

**Files Affected:**
- `service/trade/order/validator.go` (direct)
- `service/trade/order/validator_test.go` (needs regression test)

**No cascade effects expected** - validation is earliest gate.

## Proposed Fix

Add negative amount validation:

```go
if amount.LessThanOrEqual(decimal.Zero) {
    return errors.New("amount must be positive")
}
```
```

## Configuration

### Required Tools

- **Claude Code** - Version **2.1.17 or later** (required for task list functionality)
- **Git with GPG signing** - Required for Phase 4 commits
- **Test framework** - Language-specific (Go: `go test`, JS: `jest`, etc.)
- **[Superpowers](https://github.com/obra/superpowers)** - Required for Phase 5 code review
  - Specifically: `superpowers:requesting-code-review` skill (invoked in Phase 5)
  - See the [Superpowers blog post](https://blog.fsck.com/2025/10/09/superpowers/) for more details

### Optional Integrations

- **Atlassian MCP** - Enables Jira/Confluence access in Phase 1
- **GitHub CLI (`gh`)** - Required for PR creation in Phase 6 (via create-pr skill)

### Environment Variables

**Required:**
```bash
export CLAUDE_CODE_ENABLE_TASKS=true
```

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) and reload.

## Best Practices

### Phase 2: Root Cause Analysis

1. **Be thorough** - Don't rush to solutions, understand the problem deeply
2. **Document precisely** - Use file:line references, not vague descriptions
3. **Test reproduction** - Verify you can actually reproduce the bug
4. **Consider history** - Check git blame, understand why broken code was written
5. **Identify scope** - What else might be affected by the same issue?

### Phase 3: Solution Design

1. **Minimize changes** - Fix the bug, don't refactor unrelated code
2. **Avoid over-engineering** - Simplest fix that works is often best
3. **Plan regression tests** - Each component should test the bug scenario
4. **Consider edge cases** - What similar bugs might exist?

### Phase 4: Execution

1. **RED phase critical** - Regression test must fail before fix
2. **Verify fix completeness** - Test covers all bug scenarios
3. **Don't break existing tests** - All prior tests must still pass
4. **Atomic commits** - Regression test + fix together

### Phase 5: Review

1. **Verify bug fixed** - Actually test the reproduction steps
2. **Check for side effects** - Run full test suite
3. **Validate regression prevention** - Confirm test would catch future regressions

### Phase 6: Handoff

1. **create-pr skill handles base PR** - Commit analysis and description generation automated
2. **Root cause added automatically** - Handoff agent enhances PR with root-cause-analysis.md content
3. **Context dump provided** - Decision record and verification evidence output to chat
4. **Reviewers see full context** - PR includes why code was broken, not just what changed
5. **Update Jira** - Link PR, add root cause summary to ticket

## Troubleshooting

### Root Cause Agent Can't Reproduce Bug

**Symptoms:**
- Agent reports "unable to reproduce"
- Root cause analysis is vague or speculative

**Solutions:**
1. Provide clearer reproduction steps in Jira ticket
2. Manually reproduce and document exact steps
3. Provide specific input data / test case
4. Check if bug is environment-specific

### Solution Design Recommends Large Refactor

**Symptoms:**
- Solution involves rewriting large sections
- Multiple files being modified unnecessarily
- Phase 3 plan looks like a feature implementation

**Solutions:**
1. Reply "retry" when asked to approve
2. Emphasize "minimal fix" in instructions
3. Edit solution design to reduce scope
4. Consider if refactor is truly needed (might be separate ticket)

### Regression Tests Don't Fail Before Fix

**Symptoms:**
- Phase 4 agents report tests pass without implementation
- Regression test validates wrong behavior

**Solutions:**
1. Verify test actually exercises bug scenario
2. Check test assertions are correct
3. Manually run test before and after fix
4. Rewrite test to properly validate bug

### Review Phase Shows New Failures

**Symptoms:**
- Tests that previously passed now fail
- Fix introduced side effects

**Solutions:**
1. Review root cause analysis - was scope underestimated?
2. Check if broken tests are related to fix
3. Expand fix to handle additional cases
4. Consider if new failures reveal deeper issue

## Advanced Usage

### Debugging in Phase 2

Root cause agent is **allowed** to temporarily modify code for debugging:

✅ **Allowed:**
- Adding console.log / fmt.Println statements
- Adding temporary test cases
- Commenting out code to isolate issue
- Adding assertions / invariant checks

🚫 **Not allowed:**
- Implementing the fix (that's Phase 4)
- Committing temporary changes
- Breaking the build

**All debugging changes are temporary and should not be committed.**

### Multi-Component Bug Fixes

For bugs affecting multiple components:

1. **Phase 2** identifies all affected locations
2. **Phase 3** creates separate work packages per component
3. **Phase 4** fixes components in parallel (if independent)
4. **Dependencies** coordinate fixes if components depend on each other

Example:

```
Bug affects: Validation + API + Database

Phase 3 creates:
- components/validation-fix.md (blocks: api-fix, db-fix)
- components/api-fix.md (blocked by: validation-fix)
- components/db-fix.md (blocked by: validation-fix)

Phase 4 executes:
1. Validation fix first
2. API + DB fixes in parallel after validation completes
```

### Emergency Hotfixes

For critical production bugs:

1. **Skip TDD if needed** - Fix first, add tests after (use with caution)
2. **Single-component fixes** - Simplify Phase 3 to one work package
3. **Manual review** - Skip automated review if time-critical
4. **Document post-fix** - Add root cause analysis after merge

**Note:** Only use emergency mode for true production emergencies. TDD prevents introducing new bugs.

## Performance Considerations

Similar to implement-v2, but:

- **Phase 2 is sequential** - Debugging can't be parallelized
- **Phase 4 benefits from parallelization** - Multiple affected components can be fixed simultaneously
- **Regression tests add time** - Need to verify bug reproduction

## Phase Reference

### Phase 1: Discovery
- **Agent:** Explore (thorough mode)
- **Tasks:** Bug report analysis, codebase exploration
- **Output:** `discovery-summary.md`
- [📖 Phase 1 Definition](../workflow-definitions/bugfix-v2/phase1-discovery.md)

### Phase 2: Root Cause Analysis
- **Agent:** General-purpose (debugging allowed)
- **Tasks:** Reproduce, debug, identify exact location
- **Output:** `root-cause-analysis.md`
- [📖 Phase 2 Definition](../workflow-definitions/bugfix-v2/phase2-root-cause.md)

### Phase 3: Solution Design
- **Agent:** General-purpose
- **Tasks:** Design minimal fix, create work packages
- **Output:** `INDEX.md`, `components/*.md`
- [📖 Phase 3 Definition](../workflow-definitions/bugfix-v2/phase3-solution.md)

### Phase 4: Execution
- **Agents:** General-purpose (one per component, parallel)
- **Tasks:** TDD implementation with regression tests
- **Output:** Committed code
- [📖 Phase 4 Definition](../workflow-definitions/bugfix-v2/phase4-execution.md)

### Phase 5: Review
- **Agent:** Code review skill
- **Tasks:** Verify bug fixed, regression tests, integration tests
- **Output:** `review-results.md`
- [📖 Phase 5 Definition](../workflow-definitions/bugfix-v2/phase5-review.md)

### Phase 6: Handoff
- **Agent:** General-purpose
- **Tasks:** PR description with root cause, PR creation
- **Output:** `pr-description.md`, GitHub PR
- [📖 Phase 6 Definition](../workflow-definitions/bugfix-v2/phase6-handoff.md)

## Related Documentation

- [implement-v2](../implement-v2/README.md) - Feature implementation workflow
- [TDD Cycle](../workflow-definitions/shared/TDD-CYCLE.md) - Test-driven development protocol
- [Commit Protocol](../workflow-definitions/shared/COMMIT-PROTOCOL.md) - Git commit rules
- [Artifacts](../workflow-definitions/shared/ARTIFACTS.md) - File structure and formats
- [Error Recovery](../workflow-definitions/shared/ERROR-RECOVERY.md) - Handling failures
- [MCP Usage](../workflow-definitions/shared/MCP-USAGE.md) - Atlassian integration

## Feedback

Issues or suggestions? Please open an issue in the repository.
