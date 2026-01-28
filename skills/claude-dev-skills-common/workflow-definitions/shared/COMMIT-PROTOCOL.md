# Commit Protocol

All commits in workflows MUST follow this protocol.

## Commit Format

Follow Conventional Commits standard per CLAUDE.md:

```
type(scope): description

[optional body with details]

Ticket: $TICKET_ID
```

### Valid Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code restructuring (no behavior change)
- `test` - Adding or fixing tests
- `chore` - Maintenance (dependencies, tooling)

### Scopes

Scopes are project-specific and should be configured in your `~/.claude/config.json`:

```json
{
  "commit": {
    "scopes": ["api", "service", "data", "infra", "docs"]
  }
}
```

Check your project's config for the list of valid scopes for your codebase.

### Message Length Limits

Commit messages should respect configured length limits from `~/.claude/config.json`:

```json
{
  "commit": {
    "titleMaxLength": 50,
    "bodyMaxLength": 72
  }
}
```

**Title (subject line):**
- Maximum length: Configured in `titleMaxLength` (default: 50 characters)
- Format: `type(scope): description` (entire line including type and scope)
- Keep concise, use body for details

**Body:**
- Maximum line length: Configured in `bodyMaxLength` (default: 72 characters)
- Wrap lines to stay within limit
- Blank line separates title from body
- Use bullet points for multiple items

**Why these limits?**
- Title: Fits in git log, GitHub UI, and terminal windows
- Body: Readable in 80-column terminals with some margin

### Examples

**Feature implementation:**
```
feat(service): add payment instruction resolver

Add service for resolving payment instructions based
on institution, instrument, and direction. Supports
method overrides.

Ticket: PX-1234
```

**Bug fix:**
```
fix(service): correct fee calculation precision

Root cause: BigDecimal rounding mode was HALF_UP
instead of HALF_EVEN, causing inconsistent fee
calculations for orders with fractional amounts.

Ticket: PX-5678
```

**Notes on examples:**
- Title ≤ 50 chars: "feat(service): add payment instruction resolver" = 49 chars
- Body lines ≤ 72 chars: Lines wrapped appropriately
- Use body for context, keep title concise

## Creating Commits

### Method 1: Heredoc (Recommended for multi-line messages)

```bash
git add [files]
git commit -m "$(cat <<'EOF'
feat(service): implement payment instruction resolver

Add service for resolving payment instructions.

Ticket: PX-1234
EOF
)"
```

**Benefits:**
- Preserves formatting (no quote escaping issues)
- Readable in scripts
- Safe for multi-line messages

### Method 2: Direct String (for simple one-liners)

```bash
git add [files]
git commit -m "feat(service): add payment instruction resolver

Ticket: PX-1234
```

## GPG Signing Requirements

**ALL commits MUST be GPG signed.**

### Automatic Signing

If user has `commit.gpgsign=true` in git config, commits are automatically signed.

### Verify GPG Signing

```bash
git log --show-signature -1
```

Look for `gpg: Good signature` in output.

## GPG Failure Handling

### On GPG Success

✅ Report success:
```
✅ Component: [component-name] - COMPLETE

Commit: [hash]
Tests: All passing
Files modified: [list]

Ready for integration testing.
```

### On GPG Failure

🚨 **HARD STOP** - Do NOT proceed

**Failures include:**
- GPG signing timeout
- GPG signing cancelled by user
- GPG key passphrase incorrect
- GPG agent not running

**Response:**
```
❌ Component: [component-name] - GPG SIGNING FAILED

Error: [gpg error message]

Status:
- Code implementation: COMPLETE ✅
- Tests passing: YES ✅
- Commit signed: NO ❌

Uncommitted changes preserved.
USER ACTION REQUIRED: Reply "retry [component-name]" when ready.
```

**What NOT to do:**
- ❌ NEVER use `--no-gpg-sign` flag
- ❌ NEVER retry automatically (user may need to start GPG agent)
- ❌ NEVER commit without signature
- ❌ NEVER proceed to next phase

**What to do:**
- ✅ Report failure immediately
- ✅ Preserve uncommitted changes (do not reset or stash)
- ✅ Wait for user "retry [component]" command
- ✅ Stop workflow (block phase transition)

### Recovery Commands

User can issue:
- `retry [component-name]` - Retry one failed component
- `retry all` - Retry all failed components
- `status` - Check workflow state

Orchestrator will respawn failed component agents with same work packages.

## Atomic Commit Requirements

Every commit MUST be:

1. **Individually shippable** - Complete feature/fix that's deployable alone
2. **Safely revertible** - Can revert without breaking system
3. **Include tests** - Production code + tests committed together
4. **Pass all tests** - Never commit failing tests (violates atomic rule)
5. **Follow forward dependencies** - May depend on previous commits, NOT future commits

### Good Atomic Commits

✅ One component implementation with tests:
```
feat(data): add repository layer for payment instructions

- Add PaymentInstructionRepository with Query methods
- Add comprehensive test coverage for queries
- All tests passing

Ticket: PX-1234
```

✅ Bug fix with regression test:
```
fix(api): prevent null pointer in order cancellation

Root cause: Missing null check for order.metadata field.
Added null check and regression test to prevent recurrence.

Ticket: PX-5678
```

### Bad Commits (Non-Atomic)

❌ Commit without tests:
```
feat(data): add repository layer

(No tests included - not shippable)
```

❌ Commit with failing tests:
```
feat(data): add repository layer

Tests currently failing, will fix in next commit.
(Violates atomic rule - breaks CI)
```

❌ Partial implementation:
```
feat(data): add repository layer (WIP)

TODO: Add error handling
TODO: Add validation
(Not complete - not shippable)
```

❌ Multiple unrelated changes:
```
feat(service): add repository layer, fix API bug, refactor service

(Too many concerns - not focused, hard to revert)
```

## Commit Staging

### Stage All Modified Files in Component

```bash
git add path/to/component/file.go
git add path/to/component/file_test.go
git add path/to/component/mock_*.go  # If mocks generated
git add path/to/component/.mockery.yaml  # If mockery config created
```

### Verify Staged Changes

```bash
git status
git diff --cached
```

**Check:**
- All component files staged
- No unrelated files staged
- Tests included
- Mocks included (if generated)

## Commit Verification

After committing, verify:

```bash
# Check commit was created
git log -1 --oneline

# Check commit is signed
git log --show-signature -1

# Check no unstaged changes remain
git status

# Verify tests still pass
go test ./path/to/component/...
```

## Multi-Component Workflows

In workflows with multiple components (Phase 3/4 execution):

- Each component gets **ONE atomic commit**
- Components may have dependencies (repository → service → API)
- Dependent components commit AFTER dependencies complete
- All component commits must be GPG signed before phase transition
