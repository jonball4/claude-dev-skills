# Claude Development Skills

A collection of sophisticated Claude Code skills for orchestrated software development workflows. These skills enable multi-phase, multi-agent implementation patterns with test-driven development, code review, and automated handoffs.

## Overview

This repository contains four main skills designed to work with Claude Code:

1. **[implement-v2](#implement-v2)** - 5-phase orchestrated feature implementation workflow
2. **[bugfix-v2](#bugfix-v2)** - 6-phase orchestrated bug fixing workflow with root cause analysis
3. **[tdd-to-jira-tickets](#tdd-to-jira-tickets)** - Automated conversion of Technical Design Documents to Jira ticket CSVs with dependency tracking
4. **[create-pr](#create-pr)** - Automated GitHub pull request creation with comprehensive context from commit history

## Architecture

These skills use a **multi-agent orchestration pattern** where:

- An **orchestrator** manages the overall workflow and phase transitions
- Specialized **agents** handle each phase (discovery, planning, execution, review, handoff)
- **Artifacts** stored in `~/.claude/work/$TICKET_ID/` serve as communication between agents
- **Task lists** track progress and enable cross-session resumption

### Artifact-Driven Design

All agents communicate through structured markdown files:

```
~/.claude/work/$TICKET_ID/
├── plans/
│   ├── discovery-summary.md      # From Phase 1
│   ├── INDEX.md                   # From Phase 2
│   ├── components/
│   │   ├── component1.md          # Work packages
│   │   └── component2.md
│   └── root-cause-analysis.md     # Bugfix only
├── review-results.md              # From Phase 4/5
└── pr-description.md              # From Phase 5/6
```

See [workflow-definitions/shared/ARTIFACTS.md](.claude/workflow-definitions/shared/ARTIFACTS.md) for complete structure.

## Skills

### implement-v2

**5-phase workflow for feature implementation**

Orchestrates parallel component development with test-driven development, automated review, and PR creation.

#### When to Use
- Implementing new features from Jira tickets
- Working with Technical Design Documents (TDDs)
- Need parallel component development with dependency tracking
- Require automated code review and quality checks

#### Phases
1. **Discovery** - Gather context from Jira, Confluence, and codebase
2. **Planning** - Design approach, create component work packages
3. **Execution** - Parallel TDD implementation across components
4. **Review** - Integration testing and quality validation
5. **Handoff** - PR creation with comprehensive documentation

#### Usage
```bash
# In Claude Code
/implement-v2 PX-1234

# Or with Jira URL
/implement-v2 https://yourorg.atlassian.net/browse/PX-1234
```

#### Resuming Interrupted Work
```bash
CLAUDE_CODE_TASK_LIST_ID=<task-list-id> claude
# Then use TaskList to see current phase
```

[📖 Full Documentation](.claude/skills/implement-v2/README.md) | [📄 Skill Definition](.claude/skills/implement-v2/implement-v2.md)

---

### bugfix-v2

**6-phase workflow for bug fixing with root cause analysis**

Extends the implementation workflow with dedicated root cause analysis and solution design phases.

#### When to Use
- Fixing bugs reported in Jira
- Need systematic debugging before implementing fixes
- Require root cause documentation in PRs
- Want regression test validation

#### Phases
1. **Discovery** - Gather context from bug report and codebase
2. **Root Cause Analysis** - Debug and identify exact bug location
3. **Solution Design** - Design minimal fix approach
4. **Execution** - Parallel TDD implementation with regression tests
5. **Review** - Verify bug fixed, run regression tests
6. **Handoff** - PR creation with root cause documentation

#### Usage
```bash
# In Claude Code
/bugfix-v2 BUG-456

# Or with Jira URL
/bugfix-v2 https://yourorg.atlassian.net/browse/BUG-456
```

#### Key Differences from implement-v2
- **Phase 2**: Dedicated root cause analysis with debugging
- **Phase 3**: Solution design focused on minimal fixes
- **Phase 6**: PR description includes root cause summary
- **Testing**: RED phase includes regression test validation

[📖 Full Documentation](.claude/skills/bugfix-v2/README.md) | [📄 Skill Definition](.claude/skills/bugfix-v2/bugfix-v2.md)

---

### tdd-to-jira-tickets

**Automated Jira ticket generation from Technical Design Documents**

Converts TDD markdown files into structured Jira ticket CSVs with task granularity, dependency tracking, and vertical slicing for maximum parallelization.

#### When to Use
- Converting TDD documents to Jira tickets
- Need milestone-organized tickets with dependency tracking
- Want vertical slicing (one person owns service + API for feature)
- Require CSV review before programmatic creation

#### Architecture Patterns

**Three-Layer Architecture:**
- **API Layer** - Thin interfaces (one ticket per query/mutation)
- **Service Layer** - Business logic (split by operation groups: Create/Update, Approve/Reject)
- **Data Layer** - Database access (atomic tickets: table + constraints + indices + migration)

**Interface-First Development:**
1. Define interface requirements (capabilities, not signatures)
2. Merge interface definitions → unblocks downstream work
3. Implement with mocks → enables parallel TDD

#### Features
- ✅ Vertical slicing for maximum parallelization
- ✅ Atomic database tickets (no splitting table/constraints/indices)
- ✅ Interface-first dependency management
- ✅ Story point estimation (1-3 ideal, 5 max)
- ✅ Automated ticket creation via Jira API
- ✅ Dependency link creation

#### Usage
```bash
# Phase 1: Generate CSV
/tdd-to-jira-tickets /path/to/TDD.md

# Phase 2 & 3: Create tickets and links
export JIRA_EMAIL="your.email@yourorg.com"
export JIRA_TOKEN="your_jira_api_token"
python .claude/skills/tdd-to-jira-tickets/create_jira_tickets_and_links.py milestone1.csv
```

#### CSV Format
```csv
Key,Jira Key,Summary,Description,Issue Type,Parent,Labels,Priority,Story Points,Blocks,Is Blocked By
M1-DB-1,,Setup payments table,"Create table...",Task,PX-9000,database|milestone-1,Medium,2,,
M1-BL-1,,Payment resolver service,"Implement...",Task,PX-9000,service|milestone-1,Medium,2,M1-API-1,M1-DB-1
M1-API-1,,Payment query,"Add query...",Task,PX-9000,api|milestone-1,Low,1,,M1-BL-1
```

[📖 Full Documentation](.claude/skills/tdd-to-jira-tickets/SKILL.md) | [📖 Setup Guide](.claude/skills/tdd-to-jira-tickets/README.md)

---

### create-pr

**Automated GitHub pull request creation with commit analysis**

Analyzes commit history from branch base to tip, extracts technical decisions, and creates well-structured pull requests using the `gh` CLI with a comprehensive template.

#### When to Use
- Creating a pull request for completed work
- Need structured PR descriptions based on actual commits
- Want to document technical decisions and context
- Submitting work for code review

#### What It Does
1. **Analyzes commits** - Examines all commits from base branch to current HEAD
2. **Reviews changes** - Inspects file diffs and modifications
3. **Extracts context** - Identifies technical decisions, breaking changes, and testing
4. **Generates PR** - Creates structured PR description using comprehensive template
5. **Pushes branch** - Ensures branch is pushed to remote if needed
6. **Creates PR** - Uses `gh pr create` to open the pull request
7. **Outputs context** - Provides session context dump for future reference

#### Usage
```bash
# In Claude Code
User: "Create a PR for this feature"
User: "Open a pull request"
User: "Make a PR"
```

#### PR Template Structure

The skill generates PRs with:

- **⚡ Summary** - Concise description with type and ticket
- **🎯 Motivation** - Why the change was needed
- **🔧 Changes** - Organized list of modifications
- **🧠 Key Decisions** - Technical choices with reasoning
- **📜 Breaking Changes** - API/contract changes if any
- **🧪 Testing & Verification** - Manual and automated test details
- **📝 Checklist** - Standard review items
- **🔗 Related** - Links to issues, docs, related PRs

#### Context Dump

After PR creation, outputs a context dump in chat (not saved as file) containing:

- ⚡ Summary with goal
- 🧠 Decision record with reasoning and alternatives
- 📜 Contract updates and architectural changes
- 🧪 Verification evidence and artifacts

#### Prerequisites
- `gh` CLI installed and authenticated (`gh auth login`)
- Working on a git branch with commits
- Branch differs from base branch

[📖 Full Documentation](.claude/skills/create-pr/README.md) | [📄 Skill Definition](.claude/skills/create-pr/SKILL.md)

---

## Shared Workflow Definitions

### TDD Cycle

All component implementations follow a strict TDD cycle:

```
SCAFFOLDING (interfaces/types)
  ↓
MOCKS (generate with mockery)
  ↓
RED (write failing test)
  ↓
GREEN (implement to pass)
  ↓
COMMIT (atomic: tests + impl + mocks)
```

[📖 Full TDD Guide](.claude/workflow-definitions/shared/TDD-CYCLE.md)

### Commit Protocol

All commits must follow:
- GPG signing (required, hard stop on failures)
- Co-authored by Claude attribution
- Atomic commits (tests + implementation together)
- Conventional commit format

[📖 Full Commit Protocol](.claude/workflow-definitions/shared/COMMIT-PROTOCOL.md)

### Error Recovery

Workflows include comprehensive error recovery:
- GPG signing failures (preserve work, allow retry)
- Agent failures (detailed error reporting)
- Phase blocking (cannot proceed without resolution)
- Cross-session resumption

[📖 Full Error Recovery Guide](.claude/workflow-definitions/shared/ERROR-RECOVERY.md)

### MCP Integration

Optional integration with Model Context Protocol servers:
- **Atlassian MCP** - Jira and Confluence access for discovery
- Fallback to manual context gathering when unavailable

[📖 Full MCP Usage Guide](.claude/workflow-definitions/shared/MCP-USAGE.md)

## Installation

### Prerequisites

**Required:**
- [Claude Code](https://claude.com/claude-code) CLI **version 2.1.17 or later** (required for task list functionality)
- Git with GPG signing configured (for implementation workflows)
- **[Superpowers](https://github.com/obra/superpowers)** - Required skill dependency for code review (see [blog post](https://blog.fsck.com/2025/10/09/superpowers/))
  - Specifically: `superpowers:requesting-code-review` skill (used in Phase 4/5 of implement-v2 and bugfix-v2)

**Optional (skill-specific):**
- Python 3.8+ and pip (for tdd-to-jira-tickets)
- Jira API access (for tdd-to-jira-tickets)
- Atlassian MCP w/ Jira + Confluence (for implement-v2 and bugfix-v2)
- GitHub CLI (`gh`) installed and authenticated (for create-pr)

### Setup

1. **Enable Task List Support**

   Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):
   ```bash
   export CLAUDE_CODE_ENABLE_TASKS=true
   ```

   Then reload:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

   **Learn more about Claude Code task lists:** See [this explanation](https://x.com/trq212/status/2014480496013803643) of how task lists enable multi-agent orchestration.

2. **Install Superpowers** (required for code review):
   ```bash
   git clone https://github.com/obra/superpowers.git ~/.claude/skills/superpowers
   ```

   See the [Superpowers blog post](https://blog.fsck.com/2025/10/09/superpowers/) for more details on this skill framework.

3. **Clone this repository** into your Claude skills directory:
   ```bash
   git clone https://github.com/yourusername/claude-dev-skills.git ~/.claude/skills
   ```

4. **For tdd-to-jira-tickets**, install Python dependencies:
   ```bash
   cd ~/.claude/skills/tdd-to-jira-tickets
   pip install -r requirements.txt
   ```

5. **Configure Jira credentials** (for tdd-to-jira-tickets):
   ```bash
   export JIRA_EMAIL="your.email@yourorg.com"
   export JIRA_TOKEN="your_jira_api_token"
   ```

See [tdd-to-jira-tickets setup guide](.claude/skills/tdd-to-jira-tickets/README.md) for detailed installation.

## Repository Structure

```
.claude/
├── skills/
│   ├── implement-v2/
│   │   ├── implement-v2.md       # Skill definition
│   │   └── README.md             # Full documentation
│   ├── bugfix-v2/
│   │   ├── bugfix-v2.md          # Skill definition
│   │   └── README.md             # Full documentation
│   ├── tdd-to-jira-tickets/
│   │   ├── SKILL.md              # Skill definition
│   │   ├── README.md             # Setup guide
│   │   ├── create_jira_tickets_and_links.py
│   │   ├── create_jira_links_template.py
│   │   └── requirements.txt
│   └── create-pr/
│       ├── SKILL.md              # Skill definition
│       └── README.md             # Full documentation
└── workflow-definitions/
    ├── implement-v2/
    │   ├── phase1-discovery.md
    │   ├── phase2-planning.md
    │   ├── phase3-execution.md
    │   ├── phase4-review.md
    │   └── phase5-handoff.md
    ├── bugfix-v2/
    │   ├── phase1-discovery.md
    │   ├── phase2-root-cause.md
    │   ├── phase3-solution.md
    │   ├── phase4-execution.md
    │   ├── phase5-review.md
    │   └── phase6-handoff.md
    └── shared/
        ├── ARTIFACTS.md          # Artifact structure
        ├── TDD-CYCLE.md          # TDD protocol
        ├── COMMIT-PROTOCOL.md    # Git commit rules
        ├── ERROR-RECOVERY.md     # Error handling
        └── MCP-USAGE.md          # MCP integration
```

## Key Concepts

### Orchestration Pattern

The skills use a **delegating orchestrator** pattern:

- **Orchestrator remains lean** - Spawns agents, monitors progress, coordinates transitions
- **Agents do heavy lifting** - Deep exploration, planning, implementation
- **Artifacts drive workflow** - Agents communicate via structured markdown files
- **Parallel execution** - Components run simultaneously for maximum efficiency
- **User approval gates** - Phase transitions require explicit user approval

### Test-Driven Development

All implementations follow TDD:

1. **SCAFFOLDING** - Define interfaces, types, empty implementations (must compile)
2. **MOCKS** - Generate with mockery (never hand-written)
3. **RED** - Write failing test (verifies test validates behavior)
4. **GREEN** - Add minimal implementation to pass
5. **COMMIT** - Atomic commit with tests + implementation + mocks

### Vertical Slicing

Tasks are sliced vertically for maximum parallelization:

- One person owns service + API for a feature (context locality)
- Multi-operation services split by operation groups (2-3 points each)
- Interface definitions merged first → unblocks downstream work
- Dependencies on interfaces (not implementations) → enables parallel TDD

### Dependency Management

Explicit dependency tracking:

- Component tasks linked via `blockedBy` relationships
- Dependencies resolved before agent spawning
- Parallel execution of independent components
- Failures isolated (continue-on-failure strategy)

## Best Practices

### For implement-v2 and bugfix-v2

1. **Always provide ticket context** - Jira URL or ticket ID
2. **Review discovery summaries** - Approve Phase 1 before planning
3. **Verify component plans** - Check work packages before execution
4. **Monitor parallel execution** - Watch for component failures
5. **Handle GPG failures gracefully** - Use retry commands
6. **Resume interrupted work** - Use task list ID for cross-session resumption

### For tdd-to-jira-tickets

1. **Read entire TDD uncompacted** - Vertical slicing requires deep understanding
2. **Create atomic database tickets** - Table + constraints + indices + migration (ONE ticket)
3. **Define interfaces first** - Unblocks downstream parallel work
4. **Apply vertical slicing** - Split by operation groups (1-3 points ideal)
5. **Map dependencies explicitly** - Use Blocks/Is Blocked By columns
6. **Review CSV before creation** - Verify breakdown before API calls

### For create-pr

1. **Write descriptive commits** - PR context comes from commit messages
2. **Review generated PR** - Verify technical decisions are accurate
3. **Include ticket references** - Link to issues/tickets in commits
4. **Ensure tests pass** - Run verification before PR creation
5. **Check branch status** - Confirm branch is up to date with base

## Troubleshooting

### Common Issues

#### "GPG signing failed"
- Ensure GPG is configured: `git config --global user.signingkey <key-id>`
- Verify GPG agent is running: `gpg-agent`
- Check commit signing: `git config --global commit.gpgsign true`

#### "Discovery artifact missing"
- Discovery agent writes `discovery-summary.md` - if missing, agent failed
- Check agent output for errors
- Retry discovery phase with `retry discovery`

#### "Component dependencies not linked"
- Orchestrator links dependencies after Phase 2 approval
- Verify INDEX.md contains dependency graph
- Check task list for `blockedBy` relationships

#### "Jira ticket creation failed"
- Verify JIRA_EMAIL and JIRA_TOKEN environment variables
- Check API token hasn't expired
- Ensure parent Epic exists in Jira

#### "gh: command not found"
- Install GitHub CLI: `brew install gh` (macOS) or see [gh installation](https://cli.github.com/)
- Verify installation: `gh --version`

#### "Not authenticated with GitHub"
- Run `gh auth login` to authenticate
- Follow prompts to authorize with browser or token

## Contributing

Contributions welcome! Please:

1. Follow existing skill patterns
2. Update documentation for changes
3. Test workflows end-to-end
4. Add error recovery guidance

## License

[Add your license here]

## Support

For issues or questions:

1. Check troubleshooting sections in individual skill READMEs
2. Review workflow-definitions for phase-specific guidance
3. Open an issue in this repository

## Credits

Created for use with [Claude Code](https://claude.com/claude-code) by Anthropic.
