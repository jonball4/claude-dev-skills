---
name: phase3-solution
type: agent-task
agent-type: Plan
priority: 1
labels: [solution-design, planning]
---

## Agent Mission: Solution Design

You are designing the solution for bug $TICKET_ID: $TICKET_TITLE

## Your Context

Read:
1. `~/.claude/work/$TICKET_ID/plans/discovery-summary.md` - System context
2. `~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md` - Root cause findings

## Your Objective

Design the fix and create component work packages for execution.

## Required Tasks

### 1. Design Fix Approach

Consider:
- Minimal change to fix root cause
- Impact on existing functionality
- Need for regression tests
- Backward compatibility

### 2. Plan Component Changes

Break fix into components if needed:
- Which files/functions need modification
- What tests need to be added/updated
- Any related edge cases to address

### 3. Create Work Packages

Similar to implement workflow - one package per component.

## Deliverables

### 1. INDEX.md

Write to: `~/.claude/work/$TICKET_ID/plans/INDEX.md`

```markdown
# Bug Fix Plan: $TICKET_ID - $TICKET_TITLE

## Ticket Reference
- **Jira:** ${JIRA_BASE_URL}/browse/$TICKET_ID
- **Root Cause:** [summary from root-cause-analysis.md]

## Fix Approach

### Strategy
[How we'll fix the bug - minimal, targeted change]

### Files to Modify
- path/to/file.go:123 (fix logic error)
- path/to/file_test.go (add regression test)

## Component Architecture

### Components
[If fix spans multiple areas, list components; otherwise single component]

### Dependency Graph
```
[component dependencies if applicable]
```

## Shared Contracts

[Any interface changes needed - should be minimal for bug fixes]

## References
- Root Cause: ~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md
- Related bugs: [from Jira]
```

### 2. Component Work Packages

For each component, write to: `~/.claude/work/$TICKET_ID/plans/components/[component-name].md`

Same template as implement workflow, but focused on:
- Fixing the identified bug
- Adding regression tests
- Validating edge cases

## Success Criteria

- ✅ Fix approach designed (minimal, targeted)
- ✅ **INDEX.md created using Write tool** (orchestrator cannot do this)
- ✅ **Component work packages created using Write tool** (1 per architectural layer)
- ✅ Regression test plan defined
- ✅ Ready for execution

## Before You Return to Orchestrator

🚨 **VERIFICATION CHECKLIST - MANDATORY** 🚨

**STOP. You MUST verify artifacts exist using tool calls:**

```javascript
// 1. Verify INDEX.md exists and is readable
Read({ file_path: "~/.claude/work/$TICKET_ID/plans/INDEX.md" })

// 2. Verify components directory exists
Bash({ command: "ls -la ~/.claude/work/$TICKET_ID/plans/components/" })

// 3. Verify at least one component work package exists (count must be > 0)
Bash({ command: "ls -1 ~/.claude/work/$TICKET_ID/plans/components/*.md 2>/dev/null | wc -l" })

// 4. Verify INDEX.md has required sections (count must be >= 2)
Grep({
  pattern: "^## (Fix Approach|Component Architecture|Dependency Graph)",
  path: "~/.claude/work/$TICKET_ID/plans/INDEX.md",
  output_mode: "count"
})

// 5. For each component file, verify it has required sections
Grep({
  pattern: "^## (Root Cause Reference|Fix Implementation|Regression Test Scenarios|Implementation Guidance)",
  path: "~/.claude/work/$TICKET_ID/plans/components/[component-name].md",
  output_mode: "count"
})
// Each component must return count >= 4
```

**If verification fails:**
- DO NOT return to orchestrator
- Complete missing work first (write missing files/sections)
- Re-run verification commands
- Only return when all verifications pass

**Checklist (verify with tools before returning):**
1. [ ] INDEX.md created with Write tool
2. [ ] components/ directory created with Bash tool
3. [ ] At least one component work package file created
4. [ ] INDEX.md includes: Fix Approach section
5. [ ] INDEX.md includes: Component Architecture or Dependency Graph section
6. [ ] Each component has: Root Cause Reference, Fix Implementation, Regression Test Scenarios, Implementation Guidance

**The orchestrator will check for these files. If they don't exist or are incomplete, the workflow will fail.**
