---
name: create-pr
description: Create a pull request using gh CLI with structured PR template based on branch commits
---

# Create Pull Request with Context

This skill creates a GitHub pull request using the `gh` CLI tool, analyzing all commits from the base branch to the current branch tip and structuring them into a comprehensive PR description.

## When to Use

- User explicitly requests PR creation ("create a PR", "make a pull request", "open a PR")
- After completing a feature or bugfix on a branch
- When ready to submit work for review

## Prerequisites

- User must have `gh` CLI installed and authenticated
- Must be on a git branch (not detached HEAD)
- Branch must have commits that differ from base branch

## Process

### 1. Gather Branch Context

**Determine the base branch:**
```bash
# Get default branch name
git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
```

**Analyze commits since base:**
```bash
# Get commit history from base to current branch
git log <base-branch>..HEAD --oneline --no-merges

# Get detailed commit messages
git log <base-branch>..HEAD --no-merges --format="%H%n%s%n%b%n---"

# Get file changes
git diff <base-branch>...HEAD --stat
git diff <base-branch>...HEAD --name-status
```

### 2. Analyze Changes

Review all commits and changes to understand:
- **Goal:** What problem is being solved? (Fix/Feature/Refactor)
- **Scope:** What areas of the codebase are affected?
- **Key decisions:** What technical choices were made?
- **Breaking changes:** Any API or contract changes?
- **Testing:** What verification was done?

### 3. Structure PR Description

Use this template structure:

```markdown
## ⚡ Summary
[1-2 sentence description of the change and its purpose]

**Ticket:** [Jira/Issue link if applicable]

## 🧠 Decision Record
[Document significant technical choices made]
- **Decision:** [What was decided]
  - **Reasoning:** [Why this approach]
  - **Alternatives:** [What was considered but not chosen]

## 📜 Contract Updates
Architectural change documentation

## 📜 Breaking Changes
- [ ] No breaking changes
- [ ] Breaking changes (describe below)

[If breaking changes exist, describe migration path]

## 🧪 Testing & Verification
**Manual Testing:**
[Describe manual verification steps taken]

**Automated Tests:**
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests passing locally

**Evidence:**
[Links to test runs, benchmarks, or other verification artifacts]

## 📝 Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (if needed)
- [ ] No new warnings introduced
- [ ] Related tickets linked

## 🔗 Related
[Links to related PRs, issues, documentation, or discussions]
```

### 4. Generate PR Title

Format: `[Type]: Brief description (max 50 chars)`

Examples:
- `Fix: Resolve race condition in user session handling`
- `Feature: Add dark mode support to dashboard`
- `Refactor: Extract authentication logic to separate service`

### 5. Create the PR

```bash
# Push branch if needed
git push -u origin <current-branch>

# Create PR with gh CLI
gh pr create \
  --title "[Generated Title]" \
  --body "$(cat <<'EOF'
[Generated PR Description]
EOF
)" \
  --base <base-branch>
```

### 6. Output Session Context Dump

After PR creation, output this context dump for the user (in chat, NOT as a file):

```markdown
# 🏗️ Context Dump & PR Description

## ⚡ Summary
**Goal:** [Fix/Feat summary]

## 🧠 Decision Record
### Key Decisions
- **Decision:** [e.g., Switched from Mutex to Channels]
- **Reasoning:** [Business driver]
- **Alternatives Discarded:** [What we rejected]

### Evidence & Artifacts
- **Verification:** [e.g., "Load tests show 20% latency reduction"]
- **Links:** [Grafana/DVC/Benchmarks]

## 📜 Contract Updates
- [ ] No architectural changes
- [ ] Updated Architecture Doc [Details]

## 🧪 Verification
- **Manual Test:** [Details]
- **Automated Tests:** [Details]

Ticket: [Jira Link/ID]
```

## Important Notes

- **Read commits carefully:** Don't assume - read the actual commit messages and diffs
- **No placeholders:** Fill in all sections with real information from the commits
- **Be specific:** Vague descriptions like "various improvements" are not helpful
- **Preserve technical details:** Include relevant implementation specifics
- **Ask if unclear:** If commit history doesn't provide enough context, ask user for clarification
- **Don't save context dump:** The context dump goes in chat only, never saved as a file

## Anti-Patterns

❌ **Don't:**
- Create PR without analyzing commits
- Use generic/template language without customization
- Skip sections because "there's nothing to say"
- Guess at technical decisions not evident in commits
- Create the PR before ensuring branch is pushed

✅ **Do:**
- Read all commits and their full messages
- Extract specific technical details from diffs
- Ask user questions if context is missing
- Verify base branch before creating PR
- Include links to related issues/tickets when available

## Example Workflow

```
User: "Create a PR for this feature"

Assistant actions:
1. Get current branch name
2. Determine base branch (main/master)
3. Analyze commits: git log main..HEAD
4. Review diffs: git diff main...HEAD
5. Extract key information from commits
6. Generate PR title and description
7. Push branch if needed
8. Execute: gh pr create --title "..." --body "..."
9. Output context dump in chat
10. Provide PR URL to user
```