# Workflow Artifact Structure

All workflow artifacts are stored in `~/.claude/work/$TICKET_ID/` directory structure.

**IMPORTANT:** These directories are NOT committed to git. They are local working directories only.

## Directory Layout

```
~/.claude/work/$TICKET_ID/
├── plans/
│   ├── TDD.md                      # Technical Design Doc (if provided by user)
│   ├── discovery-summary.md        # Phase 1: Discovery agent output
│   ├── root-cause-analysis.md      # Phase 2: Root cause agent output (bugfix only)
│   ├── INDEX.md                    # Phase 2/3: Planning/Solution agent output
│   ├── components/                 # Component work packages
│   │   ├── repository-layer.md     # Database/query component
│   │   ├── service-layer.md        # Business logic component
│   │   ├── api-layer.md            # HTTP handler component
│   │   └── kafka-integration.md    # Message producer/consumer component
│   └── review-results.md           # Phase 4/5: Review agent output
└── pr-description.md               # Phase 5/6: Handoff agent output
```

## Artifact Ownership

| Artifact | Created By | Read By | Purpose |
|----------|-----------|---------|---------|
| `TDD.md` | User (manual) | Discovery, Planning | Technical design reference |
| `discovery-summary.md` | Discovery agent | Planning, Review, Handoff | System context |
| `root-cause-analysis.md` | Root Cause agent (bugfix) | Solution, Execution, Review, Handoff | Bug diagnosis |
| `INDEX.md` | Planning/Solution agent | Execution agents, Review, Handoff | Component architecture |
| `components/*.md` | Planning/Solution agent | Execution agents | Component work packages |
| `review-results.md` | Review agent | Handoff | Quality validation |
| `pr-description.md` | Handoff agent | User (gh pr create) | Pull request description |

## File Format Standards

### discovery-summary.md
- Must include: Jira Context, Confluence Context, Codebase Context sections
- Must include: Code references in `file:line` format
- Must include: Architectural considerations and risks

### INDEX.md
- Must include: Component list with responsibilities
- Must include: Dependency graph (YAML-style format)
- Must include: Shared contracts (interfaces, type definitions)
- Must include: References to Confluence/Jira sources

### components/*.md
- Must include: Architectural context, Business rules, Interface contracts
- Must include: Files to modify (with file paths)
- Must include: TDD test scenarios (numbered list)
- Must include: Implementation guidance
- Must include: Success criteria

### review-results.md
- Must include: Test execution results (PASS/FAIL)
- Must include: Coverage metrics
- Must include: Integration point validation
- Must include: Recommendation (APPROVED or NEEDS_FIXES)

### pr-description.md
- Must follow PR Description Template from AGENTS.md
- Must include: Summary, Testing plan, Architecture notes
- For bugfixes: Must include root cause analysis summary
