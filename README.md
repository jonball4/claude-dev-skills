# Claude Development Skills

Sophisticated Claude Code skills for orchestrated software development with multi-phase workflows, test-driven development, and automated code review.

## Skills

### implement-v2
**5-phase orchestrated feature implementation** - Discovery → Planning → Execution → Review → Handoff

```bash
/implement-v2 PX-1234
```

### bugfix-v2
**6-phase bug fixing with root cause analysis** - Discovery → Root Cause → Solution Design → Execution → Review → Handoff

```bash
/bugfix-v2 BUG-456
```

### tdd-to-jira-tickets
**TDD to Jira ticket conversion** - Convert Technical Design Documents to Jira CSV with dependencies and automated ticket creation

```bash
/tdd-to-jira-tickets /path/to/TDD.md
```

### create-pr
**Automated PR creation** - Analyze commits and create structured GitHub pull requests

```bash
"Create a PR for this feature"
```

[📖 See individual skill documentation in `skills/`](skills/)

## Configuration

### Quick Start

```bash
# After installation, copy example config (if not already done by bootstrap)
cp ~/.claude/skills/claude-dev-skills-common/config.example.json ~/.claude/config.json

# Edit with your values
vim ~/.claude/config.json

# Validate
python3 ~/.claude/skills/claude-dev-skills-common/validate-config.py ~/.claude/config.json
```

### Configuration File

`~/.claude/config.json` (global, used across all projects)

**Namespaced** under `claude-dev-skills` to avoid conflicts with other skills:

```json
{
  "claude-dev-skills": {
    "version": "1.0",
    "jira": {
      "customFields": {
        "storyPoints": "customfield_10115"
      },
      "defaultProjectKey": "PROJ"
    },
    "confluence": {
      "spaces": ["ENGINEERING", "PRODUCT"]
    },
    "commit": {
      "scopes": ["api", "service", "data", "infra"],
      "types": ["feat", "fix", "docs", "refactor", "test", "chore"]
    },
    "quality": {
      "testCoverage": {
        "minimum": 80
      }
    }
  }
}
```

### Configuration Sections

**Jira** (required for tdd-to-jira-tickets)
- `customFields.storyPoints` - Your Jira story points field ID (find: Admin → Custom Fields → Story Points)
- `defaultProjectKey` - Default project when parent not specified

**Confluence** (used in discovery phases)
- `spaces` - Confluence spaces to search for documentation (order matters)

**Commit** (used in all workflows)
- `scopes` - Valid commit scopes for your codebase
- `types` - Valid commit types (Conventional Commits)
- `titleMaxLength` - Max chars for commit title/subject (default: 50)
- `bodyMaxLength` - Max line length for commit body (default: 72)

**Quality** (used in TDD workflows)
- `testCoverage.minimum` - Minimum test coverage percentage

### Environment Variables

**Required for tdd-to-jira-tickets skill:**

Set these in your shell before running the Python scripts:

```bash
export JIRA_BASE_URL=https://yourcompany.atlassian.net
export JIRA_EMAIL=your.email@company.com
export JIRA_TOKEN=your_api_token
```

Or add to your `~/.bashrc` or `~/.zshrc` for persistence.

Get Jira API token: https://id.atlassian.com/manage-profile/security/api-tokens

**Required for multi-phase workflows:**

The bootstrap script adds this to your shell profile automatically:

```bash
export CLAUDE_CODE_ENABLE_TASKS=true
```


### Finding Jira Custom Field IDs

**Method 1: UI**
1. Jira → Administration → Issues → Custom fields
2. Find "Story Points" → gear icon → View details
3. URL contains field ID: `customfield_XXXXX`

**Method 2: API**
```bash
curl -u email:token https://yourcompany.atlassian.net/rest/api/3/field \
  | jq '.[] | select(.name == "Story Points")'
```

### Validation

```bash
# Validate configuration
python3 ~/.claude/skills/claude-dev-skills-common/validate-config.py ~/.claude/config.json
```

### How Configuration Is Used

Configuration is read at workflow start and used by agents throughout execution:

**Phase 1 (Discovery):**
- `confluence.spaces` - Prioritized spaces for documentation search

**Phase 3/4 (Execution):**
- `commit.scopes` - Validates commit scopes are project-specific
- `commit.types` - Validates commit types (defaults to Conventional Commits)
- `commit.titleMaxLength` - Enforces max title length (default: 50 chars)
- `commit.bodyMaxLength` - Enforces max body line length (default: 72 chars)
- `quality.testCoverage.minimum` - Verifies coverage meets threshold before commits

**tdd-to-jira-tickets:**
- `jira.customFields.storyPoints` - Maps to your Jira instance's story points field
- `jira.defaultProjectKey` - Fallback project when parent not specified

**Agents receive config via system prompts** - they don't read files directly. Python scripts load config explicitly.

## Installation

### Quick Install (Recommended)

Use the bootstrap script for automatic setup:

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-dev-skills.git
cd claude-dev-skills

# Run bootstrap
./bootstrap.sh
```

The bootstrap script will:
1. **Check prerequisites** - Claude Code CLI, Git, Python, GitHub CLI, Superpowers
2. **Install skills** - Copy all skills to `~/.claude/skills/`
3. **Create configuration** - Set up `~/.claude/config.json`
4. **Configure environment** - Add `CLAUDE_CODE_ENABLE_TASKS=true` to shell profile
5. **Install Python dependencies** - For tdd-to-jira-tickets (optional)
6. **Validate configuration** - Check config syntax and completeness

### Installation Structure

After installation, your `~/.claude/` directory will look like:

```
~/.claude/
├── config.json                      # Your configuration
└── skills/
    ├── bugfix-v2/                   # Bug fixing skill
    ├── implement-v2/                # Feature implementation skill
    ├── create-pr/                   # PR creation skill
    ├── tdd-to-jira-tickets/        # TDD to Jira conversion skill
    └── claude-dev-skills-common/    # Shared files
        ├── config.example.json
        ├── config.schema.json
        ├── validate-config.py
        └── workflow-definitions/
            ├── bugfix-v2/
            ├── implement-v2/
            └── shared/
```

### Manual Installation

If you prefer manual setup or the bootstrap script doesn't work:

#### Prerequisites

**Required:**
- [Claude Code](https://claude.com/claude-code) CLI v2.1.17+ (for task lists)
- Git with GPG signing configured
- [Superpowers](https://github.com/obra/superpowers) skills (for code review)

**Optional:**
- Python 3.8+ (for tdd-to-jira-tickets)
- Jira API access (for tdd-to-jira-tickets)
- Atlassian MCP (for Jira/Confluence integration)
- GitHub CLI `gh` (for create-pr)

#### Setup Steps

1. **Enable task lists** (required):
```bash
# Add to ~/.bashrc or ~/.zshrc
export CLAUDE_CODE_ENABLE_TASKS=true

# Reload shell
source ~/.bashrc
```

2. **Install Superpowers** (required for code review):
```bash
# Install from Claude Code marketplace or:
git clone https://github.com/obra/superpowers.git ~/.claude/skills/superpowers
```

3. **Clone this repo and install**:
```bash
# Clone
git clone https://github.com/yourusername/claude-dev-skills.git /tmp/claude-dev-skills
cd /tmp/claude-dev-skills

# Install skills
cp -r skills/* ~/.claude/skills/

# Configure
cp skills/claude-dev-skills-common/config.example.json ~/.claude/config.json
vim ~/.claude/config.json
```

4. **For tdd-to-jira-tickets**, install Python deps:
```bash
cd ~/.claude/skills/tdd-to-jira-tickets
pip3 install -r requirements.txt
```

## Architecture

### Multi-Agent Orchestration

- **Orchestrator** - Manages workflow, spawns agents, coordinates phases
- **Specialized agents** - Handle discovery, planning, execution, review
- **Artifacts** - Structured markdown files in `~/.claude/work/$TICKET_ID/`
- **Task lists** - Track progress, enable cross-session resumption

### Artifact Structure

```
~/.claude/work/$TICKET_ID/
├── plans/
│   ├── discovery-summary.md      # Phase 1
│   ├── INDEX.md                   # Phase 2
│   ├── components/*.md            # Work packages
│   └── root-cause-analysis.md     # Bugfix only
├── review-results.md              # Phase 4/5
└── pr-description.md              # Phase 5/6
```

### TDD Cycle

All implementations follow:

```
SCAFFOLDING (interfaces/types)
  ↓
MOCKS (generate with language tools)
  ↓
RED (write failing test)
  ↓
GREEN (implement to pass)
  ↓
COMMIT (atomic: tests + impl)
```

See [TDD-CYCLE.md](skills/claude-dev-skills-common/workflow-definitions/shared/TDD-CYCLE.md)

### Language Support

**Go** - Full support with mockery integration ([LANGUAGE-GO.md](skills/claude-dev-skills-common/workflow-definitions/shared/LANGUAGE-GO.md))

**Others** - Adapt TDD principles to your language's testing conventions

## Key Concepts

**Vertical Slicing** - One person owns service + API for a feature (context locality)

**Interface-First** - Define interfaces first → merge → unblocks parallel work

**Atomic Commits** - Tests + implementation together, GPG signed, individually shippable

**Parallel Execution** - Components run simultaneously with dependency tracking

**Error Recovery** - GPG failures, agent failures, cross-session resumption

## Usage Patterns

### Feature Implementation

```bash
/implement-v2 PX-1234
# Phase 1: Reviews discovery
# Phase 2: Approves plan
# Phase 3: Monitors parallel execution
# Phase 4: Reviews integration
# Phase 5: Creates PR
```

### Bug Fixing

```bash
/bugfix-v2 BUG-456
# Phase 1: Reviews discovery
# Phase 2: Approves root cause analysis
# Phase 3: Approves solution design
# Phase 4: Monitors execution
# Phase 5: Validates fix
# Phase 6: Creates PR
```

### TDD to Jira

```bash
# Generate CSV
/tdd-to-jira-tickets TDD.md

# Review CSV, then create tickets
export JIRA_EMAIL="..." JIRA_TOKEN="..."
python create_jira_tickets_and_links.py milestone1.csv
```

### Resuming Work

```bash
# Use task list ID from previous session
CLAUDE_CODE_TASK_LIST_ID=<id> claude

# Check current phase
TaskList
```

## Troubleshooting

### Installation Issues

**"Claude Code CLI is required"**
- Install Claude Code: https://claude.com/claude-code

**"Superpowers skills not found"**
- Install from Claude Code marketplace or:
  ```bash
  git clone https://github.com/obra/superpowers.git ~/.claude/skills/superpowers
  ```

**"Configuration validation failed"**
- Check error messages and fix your config:
  ```bash
  vim ~/.claude/config.json
  python3 ~/.claude/skills/claude-dev-skills-common/validate-config.py
  ```

**"Python dependencies failed to install"**
  ```bash
  # macOS
  brew install python3

  # Ubuntu/Debian
  sudo apt install python3 python3-pip

  # Then retry
  pip3 install -r ~/.claude/skills/tdd-to-jira-tickets/requirements.txt
  ```

**"gh: command not found"**
- Install GitHub CLI (optional, for create-pr skill):
  ```bash
  # macOS
  brew install gh

  # Ubuntu/Debian
  sudo apt install gh

  # Then authenticate
  gh auth login
  ```

### Runtime Issues

**GPG signing failed**
- Configure: `git config --global user.signingkey <key-id>`
- Enable: `git config --global commit.gpgsign true`
- Start agent: `gpg-agent`

**Discovery artifact missing**
- Check agent output for errors
- Retry: `retry discovery`

**Jira ticket creation failed**
- Verify `JIRA_EMAIL`, `JIRA_TOKEN`, and `JIRA_BASE_URL` are set in your environment
- Check API token hasn't expired
- Ensure parent Epic exists

**Invalid commit scope**
- Add scope to `~/.claude/config.json` under `commit.scopes`

**Coverage below minimum**
- Adjust `quality.testCoverage.minimum` in `~/.claude/config.json`
- Or increase test coverage

## Repository Structure

```
skills/
├── bugfix-v2/                    # Bug fixing skill
│   ├── README.md
│   └── SKILL.md
├── implement-v2/                 # Feature implementation skill
│   ├── README.md
│   └── SKILL.md
├── create-pr/                    # PR creation skill
│   ├── README.md
│   └── SKILL.md
├── tdd-to-jira-tickets/         # TDD to Jira conversion skill
│   ├── README.md
│   ├── SKILL.md
│   ├── requirements.txt
│   └── *.py
└── claude-dev-skills-common/    # Shared files
    ├── config.example.json
    ├── config.schema.json
    ├── validate-config.py
    └── workflow-definitions/
        ├── implement-v2/         # 5 phase files
        ├── bugfix-v2/            # 6 phase files
        └── shared/
            ├── ARTIFACTS.md
            ├── TDD-CYCLE.md
            ├── COMMIT-PROTOCOL.md
            ├── ERROR-RECOVERY.md
            ├── MCP-USAGE.md
            └── LANGUAGE-GO.md
```

## Uninstallation

To completely remove claude-dev-skills:

```bash
# Remove skills
rm -rf ~/.claude/skills/bugfix-v2
rm -rf ~/.claude/skills/implement-v2
rm -rf ~/.claude/skills/create-pr
rm -rf ~/.claude/skills/tdd-to-jira-tickets
rm -rf ~/.claude/skills/claude-dev-skills-common

# Remove configuration (optional)
rm ~/.claude/config.json

# Remove environment variables from shell profile (optional)
# Edit your ~/.bashrc or ~/.zshrc and remove:
# export CLAUDE_CODE_ENABLE_TASKS=true
# export JIRA_BASE_URL=...
# export JIRA_EMAIL=...
# export JIRA_TOKEN=...
```

## Credits

Created for [Claude Code](https://claude.com/claude-code) by Anthropic.

Requires [Superpowers](https://github.com/obra/superpowers) by @obra.
