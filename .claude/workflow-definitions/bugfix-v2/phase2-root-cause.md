---
name: phase2-root-cause
type: agent-task
agent-type: general-purpose
priority: 1
labels: [root-cause, debugging]
---

## Agent Mission: Root Cause Analysis

You are performing root cause analysis for bug $TICKET_ID: $TICKET_TITLE

## Your Context

Read:
1. `~/.claude/work/$TICKET_ID/plans/discovery-summary.md` - System context from discovery
2. Jira ticket - Bug report details (if MCP available)

## Your Objective

Find the root cause of the bug through systematic debugging and analysis.

## Required Tasks

### 1. Reproduce the Bug

Based on bug report:
- Understand expected vs actual behavior
- Identify reproduction steps
- Run tests to reproduce (if applicable)
- Document observations

### 2. Debug & Trace

**Allowed debugging operations:**
- Add logging statements to trace execution
- Run debugger/use print statements
- Analyze stack traces
- Review related code
- Check git history for when bug was introduced: `git log --oneline [file]`
- Run specific tests: `go test -v -run TestSpecific`

**Note:** You MAY temporarily modify code for debugging (add logs, etc.), but do NOT fix the bug yet.

### 3. Analyze Root Cause

Determine:
- Where in the code the bug originates
- Why the bug occurs (logic error, race condition, edge case, etc.)
- What assumptions were violated
- Impact and scope of the bug

### 4. Validate Understanding

- Can you reliably reproduce the bug?
- Do you understand the complete failure path?
- Have you identified the exact line(s) causing the issue?

## Deliverable

Write analysis to: `~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md`

```markdown
# Root Cause Analysis: $TICKET_ID

## Bug Description (from Jira)
- **Expected Behavior:** [what should happen]
- **Actual Behavior:** [what happens instead]
- **Impact:** [severity, affected users/systems]

## Reproduction

### Steps to Reproduce
1. [step 1]
2. [step 2]

### Test Case
\`\`\`go
// Test that reproduces the bug
func TestBugReproduction(t *testing.T) {
    // ...
}
\`\`\`

Status: ✅ Reliably reproduced / ❌ Cannot reproduce

## Root Cause

### Location
- **File:** path/to/file.go
- **Function:** FunctionName
- **Line:** 123

### Issue
[Clear explanation of what's wrong in the code]

### Why It Happens
[Explanation of the logic error, edge case, race condition, etc.]

### When It Was Introduced
- **Commit:** [hash from git log]
- **Date:** [date]
- **Context:** [what change introduced this]

## Impact Analysis

### Affected Code Paths
- [code path 1]
- [code path 2]

### Severity
[Critical / High / Medium / Low and why]

### Related Issues
[Other tickets that might be related, from Jira search]

## Debug Notes

[Any relevant observations, logs, stack traces that helped identify the issue]
```

## If Root Cause Cannot Be Found

**Report status:**
```
⚠️ ROOT CAUSE NOT IDENTIFIED

Attempted:
- [debugging approach 1]
- [debugging approach 2]

Findings:
- [what we know]
- [what we don't know]

Blockers:
- [what's preventing identification]

Need: [user input, more context, different approach]
```

## Success Criteria

- ✅ Bug reliably reproduced
- ✅ Root cause identified with file/line precision
- ✅ Understanding validated
- ✅ **root-cause-analysis.md written using Write tool** (orchestrator cannot do this)
- ✅ Ready for solution design

## Before You Return to Orchestrator

🚨 **VERIFICATION CHECKLIST - MANDATORY** 🚨

**STOP. You MUST verify artifacts exist using tool calls:**

```javascript
// 1. Verify file exists and is readable
Read({ file_path: "~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md" })

// 2. Verify required sections present (count must be >= 5)
Grep({
  pattern: "^## (Bug Reproduction|Root Cause Identified|Execution Trace|Impact Analysis|Fix Approach)",
  path: "~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md",
  output_mode: "count"
})

// 3. Verify file:line references present (pinpoint location)
Grep({
  pattern: "[a-zA-Z0-9_/.-]+\\.(go|ts|tsx|js|jsx):[0-9]+",
  path: "~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md",
  output_mode: "count"
})
```

**If verification fails:**
- DO NOT return to orchestrator
- Complete missing work first
- Re-run verification commands
- Only return when all verifications pass

**Checklist (verify with tools before returning):**
1. [ ] File exists: `root-cause-analysis.md`
2. [ ] File contains: Bug Reproduction section
3. [ ] File contains: Root Cause Identified section (with file:line)
4. [ ] File contains: Execution Trace section
5. [ ] File contains: Impact Analysis section
6. [ ] File contains: Fix Approach section

**The orchestrator will check for this file. If it doesn't exist or is incomplete, the workflow will fail.**
