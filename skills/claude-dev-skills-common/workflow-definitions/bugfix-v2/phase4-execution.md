---
name: phase4-execution
type: agent-task
agent-type: general-purpose
priority: 1
labels: [execution, tdd-enforced, atomic-commits]
---

## Agent Mission: Component Implementation

You are implementing component: $COMPONENT_NAME for ticket $TICKET_ID

## Your Context

Read these files ONLY:
1. `~/.claude/work/$TICKET_ID/plans/INDEX.md` - Shared contracts and dependencies
2. `~/.claude/work/$TICKET_ID/plans/components/$COMPONENT_NAME.md` - Your work package

## TDD Cycle (MANDATORY)

**YOU MUST follow the complete TDD cycle defined in the shared documentation.**

See [shared/TDD-CYCLE.md](../shared/TDD-CYCLE.md) for detailed instructions.

### Quick Summary

**Critical order:**
1. **Step 0:** Define interfaces, types, constructors (scaffolding) - Code must compile
2. **Step 1:** Generate mocks with mockery (never hand-write)
3. **Steps 2-7:** RED → GREEN loop for each test scenario (start with regression test)
4. **Commit:** ONE atomic commit with regression tests + fix + mocks

**Key Requirements for Bugfix:**
- **First test MUST be regression test** (reproduces bug, fails before fix)
- Store dependencies as INTERFACE types (not concrete types)
- Provide TWO constructors (FX-compatible + direct)
- Empty implementations for scaffolding (return nil/zero values)
- Use mockery with config file (`.mockery.yaml`)
- RED phase must FAIL before implementing fix
- GREEN phase must PASS after fix

**Refer to TDD-CYCLE.md for:**
- Complete scaffolding patterns and examples
- Mockery configuration and usage
- Constructor patterns for FX compatibility
- Common mistakes and how to avoid them
- Step-by-step TDD loop instructions

## Commit Protocol

**YOU MUST follow the commit protocol defined in the shared documentation.**

See [shared/COMMIT-PROTOCOL.md](../shared/COMMIT-PROTOCOL.md) for complete requirements.

### Quick Summary

**Commit format (for bugfix use `fix` type):**
```bash
git commit -m "$(cat <<'EOF'
fix(scope): description of bug fix

Root cause: [brief root cause summary]

Ticket: $TICKET_ID
EOF
)"
```

**Valid types:** fix (for bugs), feat, docs, refactor, test, chore
**Valid scopes:** See your project's `~/.claude/config.json` for configured scopes
**Length limits:** Title ≤ 50 chars (configurable), body lines ≤ 72 chars (configurable)

**GPG Signing:**
- All commits MUST be GPG signed (non-negotiable)
- On GPG failure: HARD STOP, report failure, wait for user "retry" command
- NEVER use `--no-gpg-sign`
- NEVER retry automatically

**Atomic Commit Rules:**
- Individually shippable (complete fix, deployable)
- Safely revertible
- Include regression tests with fix
- All tests must pass
- Follow forward dependencies only

**Refer to COMMIT-PROTOCOL.md for:**
- Complete commit format examples
- GPG failure handling procedures
- Atomic commit requirements
- Staging and verification steps

## Completion Criteria

- ✅ All test scenarios from work package implemented
- ✅ All tests passing
- ✅ One atomic commit created and GPG signed
- ✅ Report success to orchestrator

## If You Encounter Issues

- **Contract unclear?** Check INDEX.md for interface definitions
- **Dependency missing?** Note in completion report, cannot proceed
- **Test failing?** Debug before committing, never commit failing tests
- **GPP signing fails?** Report immediately, wait for user retry

## Success Report Format

```
✅ Component: $COMPONENT_NAME - COMPLETE

Commit: [hash]
Tests: All passing
Files modified: [list]

Ready for integration testing.
```
