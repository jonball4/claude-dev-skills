# Test-Driven Development (TDD) Cycle

**MANDATORY:** All component implementations MUST follow this TDD cycle.

## Critical Order

Tests cannot compile without interfaces and types defined first. Follow this exact sequence:

```
Step 0: SCAFFOLDING (interfaces, types, signatures)
  ↓
Step 1: MOCKS (generate with mockery)
  ↓
Steps 2-7: RED → GREEN Loop
  ↓
Commit: ONE atomic commit (tests + impl + mocks)
```

## Step 0: Define Interfaces and Types (BEFORE ANY TESTS)

**YOU MUST DO THIS FIRST** so tests can compile.

### 0.1 Identify Correct File Location

From work package, determine where code belongs:
- LP settlement services → `service/trade/lpsettlement/`
- Order processing → `service/trade/order/`
- Repository layer → `repository/`

### 0.2 Define Interfaces

Create interfaces from INDEX.md contracts:

```go
// Example: Service interface
type InstructionResolverServiceI interface {
    ResolvePaymentInstruction(
        ctx context.Context,
        institutionID uuid.UUID,
        instrumentID uuid.NullUUID,
        direction model.LpPaymentInstructionDirection,
        overrideMethod model.LpPaymentInstructionMethod,
    ) (*model.LpSettlementPaymentInstruction, error)
}
```

### 0.3 Define Structs

Create structs that implement interfaces:

```go
// ✅ Correct: Store dependencies as INTERFACE types (not concrete types)
type instructionResolverService struct {
    repo repository.PaymentInstructionRepositoryI  // Interface, not *Repository
}
```

**Common Mistake:**
```go
// ❌ Wrong: Storing concrete type instead of interface
type instructionResolverService struct {
    repo *repository.PaymentInstructionRepository  // Should be interface
}
```

### 0.4 Define Constructors (TWO Constructors for FX Compatibility)

**Pattern: FX Constructor + Direct Constructor**

```go
// Constructor 1: For FX - accepts struct with dependencies
type InstructionResolverServiceDeps struct {
    Repo repository.PaymentInstructionRepositoryI
}

func NewInstructionResolverService(deps InstructionResolverServiceDeps) InstructionResolverServiceI {
    return newInstructionResolverService(deps.Repo)
}

// Constructor 2: Direct constructor - accepts interface
func newInstructionResolverService(repo repository.PaymentInstructionRepositoryI) *instructionResolverService {
    return &instructionResolverService{
        repo: repo,  // Store interface as-is
    }
}
```

**Why Two Constructors?**
- FX dependency injection requires struct-based constructors
- Direct constructor useful for tests and non-FX code
- Both must accept interfaces (not concrete types)

**Common Mistake:**
```go
// ❌ Wrong: Only one constructor (not FX compatible)
func NewInstructionResolverService(repo repository.PaymentInstructionRepositoryI) *instructionResolverService {
    return &instructionResolverService{repo: repo}
}
```

### 0.5 Define Method Signatures with Empty Implementations

```go
// ✅ Correct scaffolding - empty implementation
func (s *instructionResolverService) ResolvePaymentInstruction(
    ctx context.Context,
    institutionID uuid.UUID,
    instrumentID uuid.NullUUID,
    direction model.LpPaymentInstructionDirection,
    overrideMethod model.LpPaymentInstructionMethod,
) (*model.LpSettlementPaymentInstruction, error) {
    return nil, nil  // Empty implementation - tests will fail
}
```

**What's Allowed in Scaffolding:**
- ✅ Interfaces, structs, constructors
- ✅ Method signatures with empty bodies (return zero values/nil)
- ✅ Type aliases, constants, error variables
- 🚫 Business logic, actual implementations, error handling logic

**Common Mistake:**
```go
// ❌ Wrong: Has business logic (not scaffolding)
func (s *instructionResolverService) ResolvePaymentInstruction(...) (*model.LpSettlementPaymentInstruction, error) {
    if overrideMethod != model.LpPaymentInstructionMethodNull {
        // ... actual logic ...  // NO! This is implementation, not scaffolding
    }
}
```

### 0.6 Verify Compilation

```bash
go build ./...
```

**Must succeed.** If compilation fails, fix scaffolding errors before proceeding.

## Step 1: Generate Mocks (if needed for testing)

**CRITICAL: NEVER write or edit mocks by hand. ALWAYS use mockery.**

### 1.1 Create Mockery Config

If your tests need mocks of interfaces, create `.mockery.yaml` in the package directory:

```yaml
# File: service/trade/lpsettlement/.mockery.yaml
inpackage: true
filename: "mock_{{.InterfaceName}}.go"
packages:
  github.com/lumina-tech/lumina/packages/server/service/trade/lpsettlement:
    interfaces:
      InstructionResolverServiceI:
```

**Config Explanation:**
- `inpackage: true` - Mocks stored in same package as interface
- `filename: "mock_{{.InterfaceName}}.go"` - Auto-generate filename (e.g., `mock_InstructionResolverServiceI.go`)
- `packages` - List interfaces to mock (scope to only what you need)

### 1.2 Generate Mocks

```bash
cd service/trade/lpsettlement && mockery
```

**Output:** `mock_InstructionResolverServiceI.go`

### 1.3 Verify Mock Generation

```bash
ls -la mock_*.go
```

### Mockery Rules

- ✅ Use mockery with config file to generate/regenerate mocks
- ✅ Commit `.mockery.yaml` config file
- ✅ Commit generated mock files
- ✅ Only mock interfaces you actually need for tests
- 🚫 NEVER hand-write mock implementations
- 🚫 NEVER manually edit generated mock files
- 🚫 NEVER run mockery without config (generates mocks for entire directory)
- 🚫 NEVER use broad scopes like `cd packages/lumina-server-shared && mockery`

## Steps 2-7: RED → GREEN Loop

For each test scenario in your work package:

### Step 2: 🔴 RED - Write Test

Write test in `*_test.go` file:

```go
func TestResolvePaymentInstruction_WithOverride(t *testing.T) {
    // Arrange
    mockRepo := repository.NewMockPaymentInstructionRepositoryI(t)
    service := newInstructionResolverService(mockRepo)

    // Act
    result, err := service.ResolvePaymentInstruction(
        context.Background(),
        testInstitutionID,
        uuid.NullUUID{},
        model.LpPaymentInstructionDirectionCredit,
        model.LpPaymentInstructionMethodWire,
    )

    // Assert
    require.NoError(t, err)
    assert.Equal(t, model.LpPaymentInstructionMethodWire, result.Method)
}
```

### Step 3: Run Test (Must FAIL)

```bash
go test -v ./service/trade/lpsettlement/...
```

**Expected:** Test compiles and FAILS (empty implementation returns nil)

**If test passes at this stage, you skipped RED phase.**

### Step 4: 🟢 GREEN - Add Implementation

Add actual implementation to make test pass:

```go
func (s *instructionResolverService) ResolvePaymentInstruction(
    ctx context.Context,
    institutionID uuid.UUID,
    instrumentID uuid.NullUUID,
    direction model.LpPaymentInstructionDirection,
    overrideMethod model.LpPaymentInstructionMethod,
) (*model.LpSettlementPaymentInstruction, error) {
    // Now add actual business logic
    if overrideMethod != model.LpPaymentInstructionMethodNull {
        return &model.LpSettlementPaymentInstruction{
            Method: overrideMethod,
        }, nil
    }
    // ... rest of implementation ...
}
```

### Step 5: Run Test (Must PASS)

```bash
go test -v ./service/trade/lpsettlement/...
```

**Expected:** Test compiles and PASSES

### Step 6: Repeat for Next Test Scenario

Go back to Step 2 for next test scenario in work package.

### Step 7: Commit (After ALL Tests Pass)

**ONE atomic commit** containing:
- Tests (`*_test.go`)
- Implementation code
- Generated mocks (if created)
- Mockery config (`.mockery.yaml` if created)

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
