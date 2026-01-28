# Test-Driven Development (TDD) Cycle

**MANDATORY:** All component implementations MUST follow this TDD cycle.

## Critical Order

Tests cannot compile without interfaces and types defined first. Follow this exact sequence:

```
Step 0: SCAFFOLDING (interfaces, types, signatures)
  ↓
Step 1: MOCKS (generate using your language's mocking tools)
  ↓
Steps 2-7: RED → GREEN Loop
  ↓
Commit: ONE atomic commit (tests + impl + mocks)
```

## Language-Specific Patterns

For language-specific testing patterns and mock generation, see:
- [Go Language Guide](./LANGUAGE-GO.md) - mockery, go test, Go-specific patterns

For other languages, adapt these TDD principles to your language's testing conventions.

## Step 0: Define Interfaces and Types (BEFORE ANY TESTS)

**YOU MUST DO THIS FIRST** so tests can compile.

### 0.1 Identify Correct File Location

From work package, determine where code belongs based on your project's architecture.

### 0.2 Define Interfaces

Create interfaces from INDEX.md contracts. Use your language's interface/protocol/trait syntax.

### 0.3 Define Implementations

Create classes/structs that implement interfaces.

**Best Practice:** Store dependencies as interface types (not concrete types) to enable testing with mocks.

### 0.4 Define Constructors

Create constructors that accept dependencies. Follow your project's dependency injection patterns.

### 0.5 Define Method Signatures with Empty Implementations

Create method signatures with empty/stub implementations that return zero values or throw NotImplementedError.

**What's Allowed in Scaffolding:**
- ✅ Interfaces, classes/structs, constructors
- ✅ Method signatures with empty bodies (return zero values/null/throw not implemented)
- ✅ Type aliases, constants, error types
- 🚫 Business logic, actual implementations, error handling logic

### 0.6 Verify Compilation

Run your language's build/compile command to ensure scaffolding compiles successfully before writing tests.

## Step 1: Generate Mocks (if needed for testing)

**CRITICAL: Use your language's standard mocking tools. NEVER write mocks by hand.**

### 1.1 Generate Mocks

Use your language's mocking framework to generate mocks for interfaces/protocols:
- **Go:** mockery (see [LANGUAGE-GO.md](./LANGUAGE-GO.md))
- **TypeScript/JavaScript:** jest.mock, vitest.mock
- **Python:** unittest.mock, pytest-mock
- **Java:** Mockito
- **C#:** Moq, NSubstitute

### 1.2 Mock Generation Best Practices

- ✅ Use automated mock generation tools
- ✅ Commit mock configuration files
- ✅ Commit generated mock files (if your tooling generates files)
- ✅ Only mock interfaces you actually need for tests
- 🚫 NEVER hand-write mock implementations
- 🚫 NEVER manually edit generated mock files

## Steps 2-7: RED → GREEN Loop

For each test scenario in your work package:

### Step 2: 🔴 RED - Write Test

Write test in your test file. Use Arrange-Act-Assert pattern:

```
Arrange - Set up test dependencies and mocks
Act - Call the method under test
Assert - Verify the result matches expectations
```

### Step 3: Run Test (Must FAIL)

Run your test command:
- Go: `go test -v ./path/to/package/...`
- JavaScript: `npm test` or `jest`
- Python: `pytest` or `python -m unittest`

**Expected:** Test compiles and FAILS (empty implementation returns wrong result)

**If test passes at this stage, you skipped RED phase.**

### Step 4: 🟢 GREEN - Add Implementation

Add actual implementation to make test pass. Write the minimal code needed to pass the test.

### Step 5: Run Test (Must PASS)

Run your test command again.

**Expected:** Test compiles and PASSES

### Step 6: Repeat for Next Test Scenario

Go back to Step 2 for next test scenario in work package.

### Step 7: Verify Test Coverage

Check test coverage meets your project's minimum threshold (configured in `~/.claude/config.json`):

```json
{
  "quality": {
    "testCoverage": {
      "minimum": 80
    }
  }
}
```

Run coverage analysis using your language's coverage tools:
- Go: `go test -cover`
- JavaScript: `jest --coverage`
- Python: `pytest --cov`

### Step 8: Commit (After ALL Tests Pass)

**ONE atomic commit** containing:
- Tests
- Implementation code
- Generated mocks (if created)
- Mock configuration files (if created)

See [COMMIT-PROTOCOL.md](COMMIT-PROTOCOL.md) for commit format and GPG signing requirements.

## TDD Benefits

1. **Tests compile first** - Scaffolding ensures tests can reference types/interfaces
2. **RED phase validates** - Failing test confirms empty implementation returns wrong result
3. **GREEN phase implements** - Minimal code added to make test pass
4. **Atomic commits** - Tests + implementation committed together (never commit failing tests)
5. **Documentation** - Tests serve as usage examples for interfaces

## Common Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Writing tests before scaffolding | Tests won't compile | Do Step 0 first |
| Skipping RED phase | Test might not validate anything | Verify test fails with empty impl |
| Hand-writing mocks | Inconsistent, error-prone | Always use mockery |
| Committing failing tests | Breaks CI, violates atomic commit rule | Only commit when all tests pass |
| Implementing before testing | Not true TDD | Write test first (RED), then implement (GREEN) |
| Storing concrete types in structs | Breaks mockability | Always store interfaces |
| Single constructor only | Not FX compatible | Provide both FX and direct constructors |
