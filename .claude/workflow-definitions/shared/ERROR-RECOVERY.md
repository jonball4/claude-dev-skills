# Error Recovery Guide

This guide covers error handling and recovery strategies for workflow failures.

## GPG Signing Failures

### Failure Scenarios

1. **Timeout** - GPG prompt timed out waiting for passphrase
2. **Cancelled** - User cancelled GPG prompt
3. **Wrong passphrase** - Incorrect GPG key passphrase entered
4. **Agent not running** - GPG agent not started or crashed
5. **Key not found** - GPG key not configured

### Detection

GPG failures are detected when `git commit` returns non-zero exit code with GPG-related error message.

### Response Protocol

🚨 **HARD STOP - BLOCK WORKFLOW**

1. **Preserve state** - Do NOT reset, stash, or discard changes
2. **Report failure** - Clear error message to user
3. **Wait for command** - Stop workflow, wait for user action
4. **No auto-retry** - User may need to fix GPG setup first

### Failure Report Format

```
❌ Component: [component-name] - GPG SIGNING FAILED

Error: [gpg error message from git]

Status:
- Code implementation: COMPLETE ✅
- Tests passing: YES ✅
- Commit signed: NO ❌

Uncommitted changes preserved in working directory.

USER ACTION REQUIRED:
- Check GPG agent is running: `gpgconf --list-dirs agent-socket`
- Test GPG key: `echo "test" | gpg --clearsign`
- When ready, reply: "retry [component-name]"
```

### User Recovery Commands

**Retry one component:**
```
retry [component-name]
```

**Retry all failed components:**
```
retry all
```

**Check workflow status:**
```
status
```

### Orchestrator Recovery Action

When user issues `retry [component-name]`:

1. Verify component is in failed state (task status: in_progress, no commit)
2. Respawn component agent with same work package
3. Agent attempts commit again (changes already staged)
4. If GPG succeeds: Mark task completed, continue workflow
5. If GPG fails again: Repeat failure protocol

## Agent Failures

### Failure Types

1. **Artifact missing** - Agent completed but didn't write required file
2. **Incomplete artifact** - File exists but missing required sections
3. **Test failures** - Implementation complete but tests fail
4. **Compilation errors** - Code doesn't compile
5. **Agent crashed** - Agent terminated unexpectedly

### Discovery/Planning/Solution Phase Failures

**Symptom:** Agent completes but artifact verification fails

**Response:**
```
❌ [PHASE] FAILED: Agent did not write required artifacts.

Missing:
- [artifact-name].md

The [Phase] agent MUST write [artifact-name].md.

Retry [phase] phase? (yes/no)
```

**User options:**
- `yes` - Respawn phase agent with same prompt
- `no` - Abort workflow

### Execution Phase Failures

**Symptom:** Component agent reports test failures or compilation errors

**Response:**
```
❌ Component: [component-name] - IMPLEMENTATION FAILED

Error: [test failure / compilation error message]

Status:
- Code implementation: ATTEMPTED ❌
- Tests passing: NO ❌
- Commit created: NO ❌

Retry [component-name]? (yes/no)
```

**User options:**
- `yes` - Respawn component agent
- `no` - Accept partial completion (other components may have succeeded)

### Review Phase Failures

**Symptom:** Integration tests fail after all components committed

**Response:**
```
❌ REVIEW FAILED - Integration issues detected

Failed tests:
- [test name]: [failure reason]
- [test name]: [failure reason]

Root cause: [analysis from review agent]
Affected components: [list]

Cannot proceed to Handoff until fixed.
Review details: ~/.claude/work/$TICKET_ID/review-results.md

Options:
- Manual debugging and fixes
- Abort workflow
```

**User must manually fix issues** - No automatic retry (requires investigation)

## Execution Strategy: Continue-on-Failure

In Phase 3/4 (Execution), multiple component agents run in parallel.

**Policy:** All agents run to completion, even if some fail.

### Rationale

1. **Partial progress** - Some components may succeed even if others fail
2. **Parallel efficiency** - Don't stop all agents if one fails
3. **Full visibility** - User sees all failures at once, not one-at-a-time

### Success Reporting

```
✅ Execution Phase: 3/4 components succeeded

Successful:
- repository-layer (commit: abc123)
- service-layer (commit: def456)
- kafka-integration (commit: ghi789)

Failed:
- api-layer (GPG signing failed)

Retry failed components? (retry all / retry api-layer / accept partial / abort)
```

### Partial Success Handling

User options:

1. **`retry all`** - Respawn all failed components
2. **`retry [component]`** - Respawn specific component
3. **`accept partial`** - Proceed to Review with partial implementation (may fail review)
4. **`abort`** - Stop workflow, preserve completed commits

## Phase Blocking

### Blocking Rules

Certain failures **BLOCK** phase transitions:

| Failure Type | Blocks Transition? | Recovery |
|--------------|-------------------|----------|
| GPG signing failure | ✅ YES | User must retry after fixing GPG |
| Test failures in execution | ✅ YES | User must retry or accept partial |
| Integration test failures in review | ✅ YES | User must manually fix and re-review |
| Artifact missing (discovery/planning) | ✅ YES | User must retry phase |
| MCP unavailable | ❌ NO | Workflow continues with codebase-only context |

### Non-Blocking Failures

**MCP Unavailable:**
- Note in artifacts that Jira/Confluence context is missing
- Recommend user provide context manually
- Continue with codebase exploration only

**Optional Enhancements:**
- Workflow proceeds even if optional improvements fail
- Note limitation in artifacts

## Cross-Session Resumption

Workflows persist task state across sessions.

### Resume from Interruption

```bash
CLAUDE_CODE_TASK_LIST_ID=<task-list-id> claude
```

### Determine Current State

```javascript
// Check task list to see where workflow stopped
TaskList()
```

**Task statuses indicate state:**
- `pending` - Phase not started yet
- `in_progress` - Phase currently running or failed mid-phase
- `completed` - Phase successfully finished

### Resume Strategy

1. **Check last in_progress task** - This is where workflow stopped
2. **Verify artifacts exist** - Check if phase agent wrote files
3. **If artifacts exist** - Present summary to user, request approval to continue
4. **If artifacts missing** - Phase failed, offer retry
5. **Continue from next phase** - User approves, transition to next pending task

### Example: Resuming After Discovery

```
📋 Workflow Status: PX-1234

Completed:
✅ Phase 1: Discovery

In Progress:
⏸️  Phase 2: Planning (not started)

Pending:
⏳ Phase 3: Execution
⏳ Phase 4: Review
⏳ Phase 5: Handoff

Discovery complete. Review: ~/.claude/work/PX-1234/discovery-summary.md
Continue to Planning phase? (yes/no)
```

## Manual Intervention

Some failures require manual user intervention:

### User Must Fix Directly

1. **Complex merge conflicts** - Cannot be auto-resolved
2. **Integration test failures** - May require system debugging
3. **GPG setup issues** - User must configure GPG agent/keys
4. **Permission issues** - User must grant filesystem/git permissions

### User Intervention Protocol

1. **Workflow pauses** - Clear message about what user must do
2. **State preserved** - Uncommitted changes, task state preserved
3. **Resume instructions** - Clear steps to resume after fix
4. **Verification** - When resumed, workflow verifies fix before continuing

## Logging and Debugging

### Workflow State

Use `TaskList()` to see current state:
```javascript
TaskList()
```

### Artifact Inspection

Check artifacts written by agents:
```bash
ls -la ~/.claude/work/$TICKET_ID/plans/
cat ~/.claude/work/$TICKET_ID/plans/discovery-summary.md
```

### Git State

Check commits and uncommitted changes:
```bash
git log --oneline -10
git status
git diff
```

### Test Output

Run tests manually to see failures:
```bash
go test -v ./service/trade/...
go test -coverprofile=coverage.out ./...
```
