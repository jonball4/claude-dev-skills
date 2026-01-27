# Atlassian MCP Usage Guide

This guide provides examples for using Atlassian MCP tools to fetch context from Jira and Confluence.

## Prerequisites

Atlassian MCP must be configured and accessible. If MCP is unavailable, workflows can proceed with codebase-only context.

## Jira Operations

### Fetch Issue Details

```javascript
getJiraIssue(cloudId: "...", issueIdOrKey: "PX-1234")
```

**Extracts:**
- Title, Description, Acceptance Criteria
- Priority, Status, Assignee
- Epic context (if part of larger initiative)
- Related issues (links)

### Fetch Issue with Comments

```javascript
getJiraIssue(cloudId: "...", issueIdOrKey: "PX-1234", expand: "comments")
```

**Use for:** Technical discussions in comments that inform implementation

### Search Related Issues

```javascript
// Using unified search
search(query: "PX-1234 related OR linked")

// Using JQL
searchJiraIssuesUsingJql(jql: "issue in linkedIssues(PX-1234)")
```

**Use for:** Finding blockers, dependencies, related work

### Find Similar Past Work

```javascript
search(query: "[feature keywords] type:issue")
```

**Use for:** Learning from similar tickets that were already solved

### Get Epic Context

```javascript
getJiraIssue(issueIdOrKey: "[EPIC-KEY]")
```

**Use for:** Understanding larger initiative context

## Confluence Operations

### Architecture Search (Always Recommended)

```javascript
// General architecture
search(query: "Architecture Overview Trading System")

// Trade-specific architecture
search(query: "Trade Falcon OR Architecture Overview Trade Falcon")
```

**Prioritize spaces:** TRADING, PRIME, ENG

### Domain-Specific Searches

Based on ticket domain, use appropriate search queries:

**Orders Domain:**
```javascript
search(query: "Client Orders OR Order States Trading")
```

**Settlement Domain:**
```javascript
search(query: "Prime Trading Settlement OR Settlement Trading")
```

**Talos Integration:**
```javascript
search(query: "Talos Processor OR Talos Trading")
```

**DAS (Ledger/Accounting):**
```javascript
search(query: "DAS Documentation OR DAS ledger accounting")
```

**Kafka/Messaging:**
```javascript
search(query: "Kafka producer consumer topic Trading")
```

### Deep Dive on Specific Pages

```javascript
// Get page by ID
getConfluencePage(cloudId: "...", pageId: "123456789")

// Search for design decisions
search(query: "[component name] design decision")
```

### Get Page Comments

```javascript
// Footer comments (general discussion)
getConfluencePageFooterComments(cloudId: "...", pageId: "123456789")

// Inline comments (specific to content)
getConfluencePageInlineComments(cloudId: "...", pageId: "123456789")
```

## Best Practices

1. **Always search architecture first** - Establishes system context before diving into specifics
2. **Use domain triggers** - Consult AGENTS.md for Confluence domain triggers
3. **Prioritize spaces** - TRADING, PRIME, ENG have most relevant documentation
4. **Extract operational context** - Look for monitoring, alerting, runbook documentation
5. **Note known gotchas** - Confluence often documents edge cases and known issues
6. **Fallback gracefully** - If MCP unavailable, proceed with codebase-only context and note limitation

## Error Handling

If Atlassian MCP is not accessible:
- Proceed with codebase exploration only
- Note in artifacts (discovery-summary.md, etc.) that Jira/Confluence context is missing
- Recommend user provide ticket context manually
- Continue workflow without blocking
