---
name: phase6-handoff
type: agent-task
agent-type: general-purpose
priority: 1
labels: [handoff, pr-creation]
---

## Agent Mission: PR Creation & Handoff

You are creating the pull request for bug fix ticket $TICKET_ID: $TICKET_TITLE

## Your Context

Read the following artifacts for context:
1. `~/.claude/work/$TICKET_ID/plans/INDEX.md` - Solution design and fix approach
2. `~/.claude/work/$TICKET_ID/plans/discovery-summary.md` - Discovery findings
3. `~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md` - **CRITICAL: Root cause analysis**
4. `~/.claude/work/$TICKET_ID/review-results.md` - Review and regression test results

These artifacts provide important context about the bug fix that should inform the PR description.

## Your Objective

Create a comprehensive pull request using the create-pr skill, ensuring the PR description includes root cause analysis.

## Directory Structure

All planning and handoff artifacts are stored in `~/.claude/work/$TICKET_ID/`:
- `~/.claude/work/$TICKET_ID/plans/` - Planning artifacts (INDEX.md, discovery-summary.md, root-cause-analysis.md, review-results.md)

**IMPORTANT:** These directories are NOT committed to git. They are local working directories only.

## Required Tasks

### 1. Review Context Artifacts

Before creating the PR, read the context artifacts listed above to understand:
- Root cause analysis with exact file:line location (root-cause-analysis.md) **MUST be included in PR**
- Solution approach and technical decisions (INDEX.md)
- Bug reproduction steps and symptoms (discovery-summary.md)
- Regression test results and validation (review-results.md)

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

**CRITICAL for bug fixes:**

After the create-pr skill generates the PR description, you MUST enhance it with root cause analysis:

1. Read `~/.claude/work/$TICKET_ID/plans/root-cause-analysis.md`
2. Add a "## 🐛 Root Cause Analysis" section to the PR description with:
   - Exact bug location (file:line)
   - Why the bug occurred
   - How the fix addresses the root cause
   - Regression test validation

You can update the PR description with:
```bash
gh pr edit --body-file <updated-description-file>
```

### 3. Report Success

After create-pr completes and root cause is added, present:
- PR URL
- Summary of bug fix
- Root cause location
- Link to Jira ticket $TICKET_ID

## Success Report Format

```
✅ PR CREATED FOR BUG FIX

PR: [URL from create-pr output]
Ticket: [JIRA_BASE_URL]/browse/$TICKET_ID
Bug: [Brief description]
Root Cause: [file:line from root-cause-analysis.md]
Fix Components: [list from INDEX.md]
Commits: [count]

Context dump provided by create-pr skill includes:
- Decision record
- Verification evidence
- Root cause analysis

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

- ✅ Context artifacts reviewed (especially root-cause-analysis.md)
- ✅ create-pr skill invoked successfully
- ✅ PR created with comprehensive description
- ✅ **Root cause analysis added to PR description**
- ✅ PR URL returned to user
- ✅ Context dump provided for future reference
