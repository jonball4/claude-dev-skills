---
name: phase5-handoff
type: agent-task
agent-type: general-purpose
priority: 1
labels: [handoff, pr-creation]
---

## Agent Mission: PR Creation & Handoff

You are creating the pull request for ticket $TICKET_ID: $TICKET_TITLE

## Your Context

Read the following artifacts for context:
1. `~/.claude/work/$TICKET_ID/plans/INDEX.md` - Implementation plan
2. `~/.claude/work/$TICKET_ID/plans/discovery-summary.md` - Discovery findings
3. `~/.claude/work/$TICKET_ID/review-results.md` - Review results

These artifacts provide important context about the implementation that should inform the PR description.

## Your Objective

Create a comprehensive pull request using the create-pr skill.

## Directory Structure

All planning and handoff artifacts are stored in `~/.claude/work/$TICKET_ID/`:
- `~/.claude/work/$TICKET_ID/plans/` - Planning artifacts (INDEX.md, discovery-summary.md, review-results.md)

**IMPORTANT:** These directories are NOT committed to git. They are local working directories only.

## Required Tasks

### 1. Review Context Artifacts

Before creating the PR, read the context artifacts listed above to understand:
- Implementation approach and technical decisions (INDEX.md)
- Codebase findings and patterns (discovery-summary.md)
- Test results and quality validation (review-results.md)

### 2. Invoke create-pr Skill

🚨 **MANDATORY: Use the create-pr skill to create the PR**

```javascript
Skill({ skill: "create-pr" })
```

The create-pr skill will:
1. Analyze all commits from base branch to current HEAD
2. Review file changes and modifications
3. Extract technical decisions from commit history
4. Generate comprehensive PR description with:
   - ⚡ Summary and motivation
   - 🔧 Changes organized by component
   - 🧠 Key technical decisions with reasoning
   - 📜 Breaking changes (if any)
   - 🧪 Testing and verification details
   - 📝 Review checklist
5. Push branch if needed
6. Create PR using `gh pr create`
7. Output session context dump for future reference

**Integration with workflow artifacts:**

After the create-pr skill generates the PR description, you should verify that:
- Technical decisions align with INDEX.md
- Component changes match discovery-summary.md findings
- Test results reference review-results.md validation

If the PR description needs enhancement with workflow-specific context, you may supplement it.

### 3. Report Success

After create-pr completes, present:
- PR URL
- Summary of components implemented
- Link to Jira ticket $TICKET_ID

## Success Report Format

```
✅ PR CREATED

PR: [URL from create-pr output]
Ticket: [JIRA_BASE_URL]/browse/$TICKET_ID
Components: [list from INDEX.md]
Commits: [count]

Context dump provided by create-pr skill includes:
- Decision record
- Verification evidence
- Contract updates

Ready for review.
```

## If PR Creation Fails

If the create-pr skill fails, report the issue and provide guidance:

```
❌ PR CREATION FAILED

Issue: [error message from create-pr]
Cause: [analysis - gh auth, branch issues, etc.]

Manual steps to resolve:
1. [step 1]
2. [step 2]

After resolving, retry create-pr skill.
```

## Success Criteria

- ✅ Context artifacts reviewed
- ✅ create-pr skill invoked successfully
- ✅ PR created with comprehensive description
- ✅ PR URL returned to user
- ✅ Context dump provided for future reference
