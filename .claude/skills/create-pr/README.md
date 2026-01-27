# Create PR Skill

Automate GitHub pull request creation with comprehensive context analysis from your commit history.

## Overview

This skill analyzes all commits from your branch base to tip, extracts technical decisions and changes, and creates a well-structured pull request using the `gh` CLI with a detailed template.

## When to Use

- Creating a pull request for completed work
- Need structured PR descriptions based on actual commits
- Want to document technical decisions and context
- Submitting work for code review

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth login`)
- Working on a git branch with commits
- Branch differs from base branch (main/master/etc.)

## What It Does

1. **Analyzes commits** - Examines all commits from base branch to current HEAD
2. **Reviews changes** - Inspects file diffs and modifications
3. **Extracts context** - Identifies technical decisions, breaking changes, and testing
4. **Generates PR** - Creates structured PR description using comprehensive template
5. **Pushes branch** - Ensures branch is pushed to remote if needed
6. **Creates PR** - Uses `gh pr create` to open the pull request
7. **Outputs context** - Provides session context dump for future reference

## Usage

Invoke the skill when ready to create a PR:

```
User: "Create a PR for this feature"
User: "Open a pull request"
User: "Make a PR"
```

## PR Template Structure

The skill generates PRs with:

- **⚡ Summary** - Concise description with type and ticket
- **🎯 Motivation** - Why the change was needed
- **🔧 Changes** - Organized list of modifications
- **🧠 Key Decisions** - Technical choices with reasoning
- **📜 Breaking Changes** - API/contract changes if any
- **🧪 Testing & Verification** - Manual and automated test details
- **📝 Checklist** - Standard review items
- **🔗 Related** - Links to issues, docs, related PRs

## Context Dump

After PR creation, outputs a context dump in chat (not saved as file) containing:

```markdown
# 🏗️ Context Dump & PR Description

## ⚡ Summary
Goal and type of change

## 🧠 Decision Record
Key technical decisions with reasoning and alternatives

## 📜 Contract Updates
Architectural change documentation

## 🧪 Verification
Testing evidence and artifacts
```

## Example Output

```
Title: Feature: Add dark mode support to dashboard

Body:
## ⚡ Summary
Implements dark mode theme switching for the main dashboard with user
preference persistence.

**Type:** Feature
**Ticket:** PROJ-123

## 🎯 Motivation
Users requested dark mode to reduce eye strain during extended sessions.
Analytics showed 60% of users prefer dark themes in similar applications.

## 🔧 Changes
- **Theme System:** Added ThemeProvider with dark/light mode support
- **Dashboard Components:** Updated all components to use theme tokens
- **User Preferences:** Added theme preference storage to user settings
- **Toggle UI:** Implemented theme switcher in navigation bar

...
```

## Best Practices

✅ **Do:**
- Review commit messages before creating PR
- Include ticket/issue references
- Document technical decisions made during implementation
- Add verification evidence (test results, benchmarks)
- Link related PRs or documentation

❌ **Avoid:**
- Creating PRs without reading commit history
- Using generic descriptions without specifics
- Skipping sections because they seem empty
- Guessing at technical context not in commits

## Configuration

No configuration needed. The skill adapts to:
- Your repository's base branch (main/master/develop)
- Your commit history and messages
- Your project structure

## Tips

- Write good commit messages - they become PR context
- Use conventional commit format for better categorization
- Include "why" in commit messages, not just "what"
- Reference issues/tickets in commits for automatic linking
- Add test results to commit messages when relevant

## Troubleshooting

**"gh: command not found"**
- Install GitHub CLI: `brew install gh` (macOS) or see [gh installation](https://cli.github.com/)

**"Not authenticated"**
- Run `gh auth login` to authenticate with GitHub

**"No commits found"**
- Ensure you're on a branch with commits different from base branch
- Check base branch detection with `git remote show origin`

**Empty PR description sections**
- Write more detailed commit messages
- Include technical context in commit bodies
- Claude will ask for clarification if context is unclear

## Related Skills

- **verification-before-completion** - Use before creating PR to ensure tests pass
- **requesting-code-review** - Use after PR creation for review preparation
- **systematic-debugging** - Use if PR introduces issues

## License

Part of claude-dev-skills repository.
