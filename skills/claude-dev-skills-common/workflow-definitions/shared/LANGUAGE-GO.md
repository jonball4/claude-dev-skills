# Go Language-Specific Patterns

This document contains Go-specific implementations and patterns for TDD workflows.

## Testing

### Running Tests

```bash
# Run tests for a specific package
go test ./path/to/package/...

# Run tests with coverage
go test -cover ./path/to/package/...

# Run tests with verbose output
go test -v ./path/to/package/...
```

### Test File Naming

- Test files: `*_test.go`
- Mock files: `mock_*.go`

## Mock Generation

### Mockery

Go projects commonly use [mockery](https://github.com/vektra/mockery) for generating mocks.

#### Configuration

Create `.mockery.yaml` in your repository root:

```yaml
with-expecter: true
packages:
  github.com/yourorg/yourproject/internal/service:
    interfaces:
      YourInterface:
        config:
          mockname: MockYourInterface
```

#### Generating Mocks

```bash
# Generate all mocks
mockery

# Generate mocks for a specific interface
mockery --name YourInterface
```

#### Using Mocks in Tests

```go
import (
    "testing"
    "github.com/stretchr/testify/mock"
    "github.com/yourorg/yourproject/internal/mocks"
)

func TestYourFunction(t *testing.T) {
    mockService := mocks.NewMockYourInterface(t)
    mockService.EXPECT().YourMethod(mock.Anything).Return(nil)

    // Test code using mockService
}
```

## Package Structure

### Standard Layout

```
yourproject/
├── cmd/                    # Application entrypoints
├── internal/               # Private application code
│   ├── api/               # API/HTTP handlers
│   ├── service/           # Business logic
│   ├── repository/        # Data access
│   └── mocks/             # Generated mocks
├── pkg/                   # Public library code
├── go.mod
└── go.sum
```

## TDD Cycle for Go

### 1. SCAFFOLDING - Define Interfaces

```go
// internal/service/your_service.go
package service

type YourService interface {
    DoSomething(ctx context.Context, input string) (string, error)
}
```

### 2. MOCKS - Generate with Mockery

```bash
mockery --name YourService --output internal/mocks
```

### 3. RED - Write Failing Test

```go
// internal/service/your_service_test.go
package service_test

func TestDoSomething(t *testing.T) {
    svc := service.NewYourService(/* deps */)
    result, err := svc.DoSomething(context.Background(), "input")

    assert.NoError(t, err)
    assert.Equal(t, "expected", result)
}
```

### 4. GREEN - Implement to Pass

```go
// internal/service/your_service_impl.go
package service

type yourServiceImpl struct {
    // dependencies
}

func NewYourService(/* deps */) YourService {
    return &yourServiceImpl{/* ... */}
}

func (s *yourServiceImpl) DoSomething(ctx context.Context, input string) (string, error) {
    // Implementation
    return "expected", nil
}
```

### 5. COMMIT - Atomic Commit

Follow the COMMIT-PROTOCOL for atomic commits after each passing test.

## Common Patterns

### Error Handling

```go
if err != nil {
    return fmt.Errorf("context: %w", err)
}
```

### Context Propagation

Always pass `context.Context` as the first parameter to functions that perform I/O or may be long-running.

### Table-Driven Tests

```go
func TestYourFunction(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    string
        wantErr bool
    }{
        {"valid input", "test", "result", false},
        {"invalid input", "", "", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := YourFunction(tt.input)
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            assert.NoError(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

## Dependencies

### Common Testing Libraries

```bash
# Testify - assertions and mocking
go get github.com/stretchr/testify

# Mockery - mock generation
go install github.com/vektra/mockery/v2@latest
```
