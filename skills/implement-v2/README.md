# implement-v2 Skill

5-phase orchestrated workflow for feature implementation using multi-agent execution with test-driven development.

## Overview

The implement-v2 skill orchestrates a complete feature implementation workflow from Jira ticket to merged PR. It uses specialized agents for each phase, parallel component execution, and artifact-based communication.

## When to Use

✅ **Use implement-v2 when:**
- Implementing new features from Jira tickets
- Working with Technical Design Documents (TDDs)
- Need to coordinate multiple components with dependencies
- Require automated code review and quality checks
- Want comprehensive PR documentation

❌ **Don't use implement-v2 for:**
- Bug fixes (use [bugfix-v2](../bugfix-v2/README.md) instead)
- Simple single-file changes
- Exploratory coding without a ticket

## Architecture

### Orchestration Pattern

```
ORCHESTRATOR (you)
    ↓
    ├─ DISCOVERY AGENT    → discovery-summary.md
    ├─ PLANNING AGENT     → INDEX.md + components/*.md
    ├─ COMPONENT AGENTS   → TDD implementation (parallel)
    ├─ REVIEW AGENT       → review-results.md
    └─ HANDOFF AGENT      → pr-description.md + PR creation
```

### Workflow Phases

| Phase | Purpose | Agent | Artifacts | User Gate |
|-------|---------|-------|-----------|-----------|
| 1. Discovery | Gather context from Jira/Confluence/codebase | Explore agent | `discovery-summary.md` | Approve to proceed |
| 2. Planning | Design approach, create work packages | General-purpose | `INDEX.md`, `components/*.md` | Approve plan |
| 3. Execution | Parallel TDD implementation | Multiple general-purpose (one per component) | Committed code | Auto (continue-on-failure) |
| 4. Review | Integration testing & quality checks | Code review skill | `review-results.md` | Approve if passing |
| 5. Handoff | PR creation with documentation | General-purpose | `pr-description.md`, PR | None (complete) |

## Usage

### Starting a New Implementation

```bash
# With ticket ID
/implement-v2 PX-1234

# With Jira URL
/implement-v2 https://yourorg.atlassian.net/browse/PX-1234
```

### The Workflow

#### Step 1: Ticket Context
The orchestrator extracts the ticket ID and fetches details from Jira (if Atlassian MCP is available).

#### Step 2: Technical Design Document (Optional)
If the Jira ticket references a TDD, you'll be prompted:

```
📄 Jira ticket references a Technical Design Document.

Please provide the TDD in markdown format, "skip" if no TDD available.

Reply with TDD source or "skip":
```

**Options:**
- Provide URL → Orchestrator fetches with WebFetch
- Provide file path → Orchestrator copies to work directory
- Reply "skip" → Proceed without TDD

#### Step 3: Phase 1 - Discovery

Discovery agent explores:
- Jira ticket and related issues
- Confluence documentation (architecture, domain knowledge)
- Codebase patterns and files to modify

**Deliverable:** `~/.claude/work/PX-1234/plans/discovery-summary.md`

**Approval Gate:** Review summary, reply "yes" to proceed

#### Step 4: Phase 2 - Planning

Planning agent designs:
- Architecture and component contracts (INDEX.md)
- Individual work packages (components/*.md)
- Dependency graph

**Deliverables:**
- `~/.claude/work/PX-1234/plans/INDEX.md`
- `~/.claude/work/PX-1234/plans/components/component-name.md` (one per component)

**Approval Gate:** Review plan, reply "yes" to proceed

After approval, orchestrator:
- Creates component tasks (one per work package)
- Links dependencies based on INDEX.md
- Transitions to Phase 3

#### Step 5: Phase 3 - Execution

Multiple component agents run **in parallel**, each following TDD cycle:

```
SCAFFOLDING (interfaces, types)
    ↓
MOCKS (generate with mockery)
    ↓
RED (write failing test)
    ↓
GREEN (implement to pass)
    ↓
COMMIT (atomic: tests + impl + mocks)
```

**Strategy:** Continue-on-failure
- Agents run to completion independently
- Successful components commit code
- Failed components report errors
- Orchestrator summarizes: "X/Y succeeded, Z failed: [list]"

**GPG Failures:** Components with GPG signing failures preserve work and report:
```
🚨 GPG FAILURE: [component]. Code complete ✅ | Tests pass ✅ | Commit signed ❌.
Changes preserved. Reply 'retry [component]' when ready.
```

**Recovery Commands:**
- `retry [component]` - Retry specific component
- `retry all` - Retry all failed components
- `status` - Check current state

#### Step 6: Phase 4 - Review

Review agent validates:
- All tests pass (unit + integration)
- Code coverage meets requirements (>80%)
- Implementation matches plan
- No regressions introduced

Uses `/requesting-code-review` skill internally.

**Deliverable:** `~/.claude/work/PX-1234/review-results.md`

**Result:** APPROVED or NEEDS_FIXES

**Approval Gate:** If APPROVED, reply "yes" to proceed to handoff

#### Step 7: Phase 5 - Handoff

Handoff agent:
1. Reviews workflow artifacts (INDEX.md, discovery-summary.md, review-results.md)
2. Invokes **create-pr skill** to:
   - Analyze all commits from base branch to current HEAD
   - Extract technical decisions from commit history
   - Generate comprehensive PR description with:
     - Summary and motivation
     - Key technical decisions with reasoning
     - Breaking changes (if any)
     - Testing and verification details
   - Push branch if needed
   - Create PR using `gh pr create`
3. Outputs context dump with decision record and verification evidence

**Deliverable:**
- Created PR with auto-generated description (URL provided)
- Context dump in chat for future reference

**Integration:** The create-pr skill handles commit analysis and PR generation, while the handoff agent provides workflow-specific context from artifacts.

**Workflow Complete!** 🎉

## Resuming Interrupted Work

If the workflow is interrupted (terminal closed, session ended):

```bash
# Resume with task list ID
CLAUDE_CODE_TASK_LIST_ID=<task-list-id> claude
```

Then check current state:

```bash
# See all tasks and current phase
TaskList
```

The orchestrator can resume from any phase by checking which tasks are completed/in-progress.

## Artifacts Reference

All artifacts are stored in `~/.claude/work/$TICKET_ID/`:

```
~/.claude/work/PX-1234/
├── TDD.md                         # (optional) Technical Design Document
├── plans/
│   ├── discovery-summary.md       # Phase 1 output
│   ├── INDEX.md                   # Phase 2 architecture/contracts
│   └── components/
│       ├── repository-layer.md    # Component work packages
│       ├── service-layer.md
│       ├── api-layer.md
│       └── kafka-integration.md
├── review-results.md              # Phase 4 output
└── pr-description.md              # Phase 5 output
```

See [workflow-definitions/shared/ARTIFACTS.md](../workflow-definitions/shared/ARTIFACTS.md) for detailed format specifications.

## Configuration

### Required Tools

- **Claude Code** - Version **2.1.17 or later** (required for task list functionality)
- **Git with GPG signing** - Required for Phase 3 commits
- **Test framework** - Language-specific (Go: `go test`, JS: `jest`, etc.)
- **[Superpowers](https://github.com/obra/superpowers)** - Required for Phase 4 code review
  - Specifically: `superpowers:requesting-code-review` skill (invoked in Phase 4)
  - See the [Superpowers blog post](https://blog.fsck.com/2025/10/09/superpowers/) for more details

### Optional Integrations

- **Atlassian MCP** - Enables Jira/Confluence access in Phase 1
- **GitHub CLI (`gh`)** - Required for PR creation in Phase 5 (via create-pr skill)

### Environment Variables

**Required:**
```bash
export CLAUDE_CODE_ENABLE_TASKS=true
```

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) and reload.

## Best Practices

### Before Starting

1. **Ensure ticket exists** - Jira ticket should be created first
2. **Prepare TDD** - If available, have TDD document ready
3. **Configure GPG** - Verify commit signing works: `git commit --allow-empty -m "test" -S`
4. **Check branch** - Create feature branch before starting: `git checkout -b feature/PX-1234`

### During Discovery Phase

1. **Review discovery summary** - Don't blindly approve, read the findings
2. **Verify file references** - Check that similar patterns make sense
3. **Ask questions** - Clarify any unclear architectural decisions

### During Planning Phase

1. **Verify work packages** - Read each component/*.md file
2. **Check dependency graph** - Ensure dependencies make sense
3. **Validate scope** - Confirm plan matches acceptance criteria

### During Execution Phase

1. **Monitor parallel execution** - Watch for component failures
2. **Don't interrupt unnecessarily** - Let agents complete their work
3. **Handle GPG failures promptly** - Use retry commands when needed

### During Review Phase

1. **Run tests locally** - Verify tests pass in your environment
2. **Review coverage reports** - Check for untested edge cases
3. **Address NEEDS_FIXES** - Don't skip to handoff if review fails

### During Handoff Phase

1. **create-pr skill handles PR creation** - The handoff agent invokes the create-pr skill
2. **PR description auto-generated** - Based on commit history analysis
3. **Context dump provided** - Decision record and verification evidence output to chat
4. **Add reviewers** - Assign appropriate reviewers in GitHub after PR creation
5. **Update Jira** - Move ticket to "In Review" status

## Troubleshooting

### Discovery Agent Returns Empty Summary

**Symptoms:**
- `discovery-summary.md` is missing or has empty sections

**Causes:**
- Atlassian MCP not available
- Codebase exploration failed
- Agent terminated early

**Solutions:**
1. Check if Atlassian MCP is connected: Tool availability in Claude Code
2. Retry discovery: `retry discovery`
3. Provide manual context: Add notes to discovery-summary.md

### Planning Agent Creates Incomplete Work Packages

**Symptoms:**
- Missing components/*.md files
- Empty or vague work package descriptions

**Causes:**
- Discovery summary lacked detail
- Complex feature needs more breakdown
- Agent didn't understand requirements

**Solutions:**
1. Reply "retry" when asked to approve plan
2. Provide additional context: Edit discovery-summary.md
3. Manually create missing work packages if needed

### Component Execution Failures

**Symptoms:**
- "X/Y succeeded, Z failed: [component]" message
- Component tasks stuck in "in_progress"

**Causes:**
- Test failures
- Compilation errors
- GPG signing failures
- Missing dependencies

**Solutions:**
1. Check error details in component agent output
2. For test failures: Fix tests manually, then retry
3. For GPG failures: Fix GPG config, then `retry [component]`
4. For missing deps: Install dependencies, then retry

### Review Phase Returns NEEDS_FIXES

**Symptoms:**
- Tests failing
- Coverage below threshold
- Code quality issues

**Causes:**
- Implementation bugs
- Missing test cases
- Integration failures

**Solutions:**
1. Read review-results.md for specific failures
2. Fix issues manually
3. Re-run review: Restart Phase 4 or use `/requesting-code-review` skill directly

### GPG Signing Failures

**Symptoms:**
- "🚨 GPG FAILURE: [component]" messages
- Commits not created despite passing tests

**Causes:**
- GPG not configured
- GPG agent not running
- Wrong signing key

**Solutions:**
```bash
# Configure GPG signing
git config --global user.signingkey <your-key-id>
git config --global commit.gpgsign true

# Start GPG agent
gpg-agent --daemon

# Test signing
git commit --allow-empty -m "test" -S
```

Then retry failed components: `retry all`

## Advanced Usage

### Custom Component Parallelization

Orchestrator spawns all independent components in parallel automatically. Dependencies block execution:

```javascript
// Example: service-layer blocks on repository-layer
TaskUpdate({
  taskId: [service-layer task ID],
  addBlockedBy: [[repository-layer task ID]]
})
```

### Manual Phase Control

You can manually control phases if needed:

```bash
# Check current phase
TaskList

# Mark phase completed manually (use with caution)
TaskUpdate({ taskId: [phase task ID], status: "completed" })

# Start next phase manually
TaskUpdate({ taskId: [next phase task ID], status: "in_progress" })
```

### Artifact Editing

Edit artifacts between phases if needed:

```bash
# Edit discovery summary before planning
vi ~/.claude/work/PX-1234/plans/discovery-summary.md

# Edit component work package before execution
vi ~/.claude/work/PX-1234/plans/components/service-layer.md
```

Agents will use updated artifacts when spawned.

## Performance Considerations

### Parallel Execution Benefits

With 4 components:
- **Sequential:** 4 × 30 min = 2 hours
- **Parallel:** max(30 min) = 30 minutes

**Speedup:** ~4× for independent components

### Resource Usage

- **Memory:** Each agent runs in separate subprocess
- **API calls:** Multiple agents call Claude API simultaneously
- **Rate limits:** Respect Claude API rate limits (handled automatically)

## Phase Reference

### Phase 1: Discovery
- **Agent:** Explore (thorough mode)
- **Tasks:** Jira analysis, Confluence search, codebase exploration
- **Output:** `discovery-summary.md`
- [📖 Phase 1 Definition](../workflow-definitions/implement-v2/phase1-discovery.md)

### Phase 2: Planning
- **Agent:** General-purpose
- **Tasks:** Architecture design, component decomposition, dependency mapping
- **Output:** `INDEX.md`, `components/*.md`
- [📖 Phase 2 Definition](../workflow-definitions/implement-v2/phase2-planning.md)

### Phase 3: Execution
- **Agents:** General-purpose (one per component, parallel)
- **Tasks:** TDD implementation (SCAFFOLDING → MOCKS → RED → GREEN → COMMIT)
- **Output:** Committed code
- [📖 Phase 3 Definition](../workflow-definitions/implement-v2/phase3-execution.md)

### Phase 4: Review
- **Agent:** Code review skill
- **Tasks:** Integration testing, coverage validation, quality checks
- **Output:** `review-results.md`
- [📖 Phase 4 Definition](../workflow-definitions/implement-v2/phase4-review.md)

### Phase 5: Handoff
- **Agent:** General-purpose
- **Tasks:** PR description generation, PR creation
- **Output:** `pr-description.md`, GitHub PR
- [📖 Phase 5 Definition](../workflow-definitions/implement-v2/phase5-handoff.md)

## Related Documentation

- [bugfix-v2](../bugfix-v2/README.md) - Similar workflow for bug fixes
- [TDD Cycle](../workflow-definitions/shared/TDD-CYCLE.md) - Test-driven development protocol
- [Commit Protocol](../workflow-definitions/shared/COMMIT-PROTOCOL.md) - Git commit rules
- [Artifacts](../workflow-definitions/shared/ARTIFACTS.md) - File structure and formats
- [Error Recovery](../workflow-definitions/shared/ERROR-RECOVERY.md) - Handling failures
- [MCP Usage](../workflow-definitions/shared/MCP-USAGE.md) - Atlassian integration

## Feedback

Issues or suggestions? Please open an issue in the repository.
