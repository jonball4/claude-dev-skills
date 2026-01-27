---
name: phase5-review
type: agent-task
agent-type: general-purpose
priority: 1
labels: [review, quality-gates]
---

## Agent Mission: Integration Review

You are performing integration review for ticket $TICKET_ID: $TICKET_TITLE

## Your Context

Read:
1. `~/.claude/work/$TICKET_ID/plans/INDEX.md` - Plan overview and components
2. Git log - Review commits made during execution

## Your Objective

Validate that all components integrate correctly and meet quality standards.

## Required Tasks

### 1. Invoke Code Review Skill

**CRITICAL: This phase MUST use the superpowers:requesting-code-review skill.**

The orchestrator will invoke:
```javascript
Skill({
  skill: "superpowers:requesting-code-review",
  args: "$TICKET_ID"
})
```

**The /requesting-code-review skill will:**
- Spawn a dedicated Review agent with fresh context (no implementation pollution)
- Review all bugfix commits against root cause analysis and solution design
- Verify adherence to coding standards from CLAUDE.md and AGENTS.md
- Check test coverage and quality (especially regression tests)
- Validate error handling and edge cases
- Ensure the fix doesn't introduce regressions
- Verify bug is actually fixed (runs reproduction steps from root-cause-analysis.md)
- Write review-results.md artifact
- Return APPROVED or NEEDS_FIXES status

**You are NOT the review agent. You are the orchestration layer.**

Your job is to:
1. Wait for the /requesting-code-review skill to complete (orchestrator invokes it)
2. Read the review-results.md artifact it creates
3. Run integration tests and regression tests
4. Document overall review status

### 2. Run Integration Tests and Regression Tests

After code review skill completes, run comprehensive tests:

```bash
# Run full test suite
go test ./...

# Run with coverage
go test -coverprofile=coverage.out ./...

# Check specific packages if feature is localized
go test -v ./service/trade/...
```

### 4. Validate Quality

- ✅ Code review completed with fresh agent
- ✅ All critical review issues addressed
- ✅ All tests passing
- ✅ No compilation errors
- ✅ Integration between components works
- ✅ Coverage meets standards
- ✅ Lint checks pass (if applicable)

### 5. Cross-Component Validation

Check that:
- Fix follows contracts from solution design
- No interface mismatches
- Dependencies resolve correctly
- Error handling consistent across components
- No regressions introduced

## Deliverable

Write results to: `~/.claude/work/$TICKET_ID/review-results.md`

```markdown
# Review Results: $TICKET_ID

## Code Review (Fresh Agent)

**Review Agent ID:** [agent-id from /review]
**Review Completed:** [timestamp]

### Issues Identified by Reviewer
1. [Issue 1]: [description] - Status: ✅ Fixed / ⚠️ Accepted as tech debt
2. [Issue 2]: [description] - Status: ✅ Fixed / ⚠️ Accepted as tech debt

### Review Summary
- Total issues found: [count]
- Critical issues: [count] - All resolved: ✅ / ❌
- Suggestions implemented: [count]
- Accepted technical debt: [list with justification]
- Regression risk assessment: [Low/Medium/High]

## Test Execution

### Full Test Suite
```
[test output summary]
```

Status: ✅ PASS / ❌ FAIL

### Coverage
- Overall: [X]%
- Modified packages: [Y]%

### Integration Points Validated
1. [Component A] → [Component B]: ✅
2. [Component C] → [External Service]: ✅

## Quality Checks

- ✅ Code review completed (fresh agent)
- ✅ All critical review issues resolved
- ✅ All tests passing
- ✅ No compilation errors
- ✅ Lint checks passed
- ✅ Contract compliance verified
- ✅ No regressions introduced

## Issues Found

[List any remaining issues, or "None"]

## Recommendation

✅ APPROVED for handoff / ❌ NEEDS FIXES

**Reasoning:** [Brief justification based on review + test results + regression analysis]
```

## If Issues Found

**Report failures clearly:**
```
❌ REVIEW FAILED - Integration issues detected

Failed tests:
- TestOrderCreationFlow: Timeout waiting for Kafka message
- TestOrderCancellation: Service layer panic

Root cause: [analysis]
Affected components: [list]

Cannot proceed to Handoff until fixed.
Review details: ~/.claude/work/$TICKET_ID/review-results.md
```

## Success Criteria

- ✅ All integration tests passing
- ✅ Cross-component validation complete
- ✅ Quality standards met
- ✅ review-results.md written
- ✅ Ready for handoff or issues documented
