---
name: phase1-discovery
type: agent-task
agent-type: Explore
thoroughness: thorough
priority: 1
labels: [discovery, read-only-phase]
---

## Agent Mission: Discovery

You are a Discovery agent for ticket $TICKET_ID: $TICKET_TITLE

## Your Objective

Gather comprehensive context from Jira, Confluence, and codebase to inform implementation planning.

## Required Tasks

### 1. Jira Context (MANDATORY if MCP available)

Use Atlassian MCP tools:

```javascript
// Get full ticket details
getJiraIssue(cloudId: "...", issueIdOrKey: "$TICKET_ID")

// Search for related tickets
search(query: "$TICKET_ID related OR linked")
searchJiraIssuesUsingJql(jql: "issue in linkedIssues($TICKET_ID)")

// Find similar past work
search(query: "[feature keywords] type:issue")
```

**Extract:**
- Full ticket description and acceptance criteria
- Linked issues (blocks, is blocked by, relates to)
- Epic context (if part of larger initiative)
- Comments with technical context
- Similar tickets that were solved

### 2. Confluence Context (MANDATORY if MCP available)

Search for relevant architectural and domain documentation:

```javascript
// Architecture (always search)
search(query: "Architecture Overview")
search(query: "System Architecture")

// Domain-specific (based on ticket content)
// Search for relevant domain terms, system names, integration points
// Examples:
//   - search(query: "Order Processing OR Order States")
//   - search(query: "Settlement Process")
//   - search(query: "Message Queue OR Event Processing")
//   - search(query: "Data Integration")
```

**Note:** Check your project's config.json for configured Confluence spaces to prioritize

**Extract:**
- Architectural patterns and constraints
- Business domain knowledge
- Operational considerations (monitoring, alerts)
- Integration requirements
- Known gotchas and edge cases

### 3. Codebase Exploration

After understanding business/architectural context:

- Check for and read common documentation files:
  - docs/ARCHITECTURE.md
  - docs/OVERVIEW.md
  - docs/TESTING.md
  - README.md
- Search for similar patterns in code
- Identify files to modify
- Map dependencies and integration points

## Deliverable

Write findings to: `~/.claude/work/$TICKET_ID/plans/discovery-summary.md`

**Required sections:**

```markdown
# Discovery Summary: $TICKET_ID

## Jira Context

### Ticket Details
- **Title:** [from Jira]
- **Description:** [full description]
- **Acceptance Criteria:** [list]
- **Priority:** [from Jira]

### Related Issues
- [TICKET-ID]: [relationship] - [title]

### Blockers & Dependencies
[Any blocking issues or dependencies noted]

### Historical Context
[Similar tickets found, what we learned]

## Confluence Context

### Architectural Patterns
[Relevant architecture from Confluence docs]

### Business Domain Knowledge
[Business rules, domain concepts from Confluence]

### Operational Considerations
[Monitoring, alerting, on-call concerns from runbooks]

### Integration Requirements
[External system integration details from Confluence]

## Codebase Context

### System Architecture
[How this feature fits in the architecture]

### Similar Patterns Found
[Existing code to use as reference with file:line references]

### Dependencies Identified
[Packages, services, external systems affected]

### Files to Modify
- path/to/file1.go (reason)
- path/to/file2.go (reason)

### Integration Points
[APIs, Kafka topics, database schemas]

## Architectural Considerations
[Important design decisions needed]

## Risks & Gotchas
[Known issues from Confluence docs, past tickets]
```

## If MCP Unavailable

If Atlassian MCP is not accessible:
- Proceed with codebase exploration only
- Note in discovery-summary.md that Jira/Confluence context is missing
- Recommend user provide ticket context manually

## Success Criteria

- ✅ Jira ticket and related issues analyzed (if MCP available)
- ✅ Confluence searched for domain knowledge (if MCP available)
- ✅ Essential codebase documentation read
- ✅ Similar patterns identified
- ✅ **discovery-summary.md written using Write tool** (orchestrator cannot do this)
- ✅ Summary is actionable for Root Cause agent

## Before You Return to Orchestrator

🚨 **VERIFICATION CHECKLIST - MANDATORY** 🚨

**STOP. You MUST verify artifacts exist using tool calls:**

```javascript
// 1. Verify directory exists
Bash({ command: "ls -la ~/.claude/work/$TICKET_ID/plans/" })

// 2. Verify file exists and is readable
Read({ file_path: "~/.claude/work/$TICKET_ID/plans/discovery-summary.md" })

// 3. Verify required sections present (count must be >= 3)
Grep({
  pattern: "^## (Jira Context|Confluence Context|Codebase Context)",
  path: "~/.claude/work/$TICKET_ID/plans/discovery-summary.md",
  output_mode: "count"
})

// 4. Verify code references present (should find file:line patterns)
Grep({
  pattern: "[a-zA-Z0-9_/.-]+\\.(go|ts|tsx|js|jsx):[0-9]+",
  path: "~/.claude/work/$TICKET_ID/plans/discovery-summary.md",
  output_mode: "count"
})
```

**If verification fails:**
- DO NOT return to orchestrator
- Complete missing work first
- Re-run verification commands
- Only return when all verifications pass

**Checklist (verify with tools before returning):**
1. [ ] Directory created: `~/.claude/work/$TICKET_ID/plans/`
2. [ ] File exists: `discovery-summary.md`
3. [ ] File contains: Jira Context section
4. [ ] File contains: Confluence Context section
5. [ ] File contains: Codebase Context section
6. [ ] File includes: Code references (file:line format)

**The orchestrator will check for this file. If it doesn't exist or is incomplete, the workflow will fail.**
