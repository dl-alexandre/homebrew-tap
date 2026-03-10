# Agent Guidelines for CLI-Tools

This file provides guidelines for AI agents working in the CLI-Tools monorepo.

## Repository Structure

This is a **monorepo** containing multiple Go CLI projects as submodules and embedded repositories:

- **Submodules**: Skills, X-CLI, homebrew-tap (linked via .gitmodules)
- **Embedded repos**: App-StoreKit-CLI, Apple-Business-Connect-CLI, Google-Drive-CLI, etc.
- **Agent skills**: .agents/skills/monorepo-cli/ for superrepo management

## Build Commands

Each CLI project has a Makefile with standardized targets:

```bash
# Build for current platform
make build

# Run all tests
make test

# Run single test (example)
go test -v -run TestFunctionName ./...

# Run tests in specific package
go test -v ./internal/xapi/

# Run with race detection
go test -v -race -run TestFunctionName ./...

# Run tests matching pattern
go test -v -run "TestAPI.*" ./...

# Run linter
make lint

# Format code
make format

# Run all checks (format, vet, lint, test)
make check

# Build for all platforms
make build-all

# Clean build artifacts
make clean
```

## Code Style Guidelines

### General Principles
- Follow existing patterns in the codebase
- Look at neighboring files for conventions
- When in doubt, check X-CLI as the reference implementation

### Imports
```go
import (
    // Standard library
    "context"
    "fmt"
    "os"
    
    // Third-party
    "github.com/alecthomas/kong"
    "github.com/spf13/viper"
    
    // Internal (grouped by path depth)
    "github.com/dl-alexandre/X-CLI/internal/auth"
    "github.com/dl-alexandre/X-CLI/internal/config"
    "github.com/dl-alexandre/X-CLI/internal/model"
)
```

### Formatting
- Use `gofmt -w -s .` for formatting
- Use `goimports -w .` for import organization
- Run `make format` to apply both

### Types and Naming
- Use `PascalCase` for exported types/functions
- Use `camelCase` for unexported types/functions
- Use `ALL_CAPS` for constants
- Error types end in `Error` (e.g., `NotFoundError`)

### Error Handling
```go
// Wrap errors with context
if err != nil {
    return fmt.Errorf("failed to load config: %w", err)
}

// Check specific error types
if errors.Is(err, os.ErrNotExist) {
    // handle not found
}
```

### Package Structure
```
cmd/x/main.go              # Entry point with Kong CLI
internal/
  auth/                    # Authentication logic
  cache/                   # Caching utilities
  cli/                     # CLI command definitions
  config/                  # Configuration management
  model/                   # Data models/structs
  output/                  # Output formatting
  xapi/                    # API client implementation
```

### CLI Pattern (Kong)
```go
type CLI struct {
    Globals
    
    Command1 command1Cmd `cmd:"" help:"Description"`
}

type command1Cmd struct {
    Flag string `help:"Flag description"`
}

func (c *command1Cmd) Run(g *Globals) error {
    // Implementation
}
```

## Linting and Quality

### Pre-commit Checks
The pre-commit hook runs:
1. `gofmt` check
2. `goimports` check
3. `go vet ./...`
4. `golangci-lint run ./...`
5. `gosec -quiet ./...` (security scan)
6. `go test -short ./...`

**Critical**: Address lint errors before committing. Run `make lint` to check.

### Security
- Run `make security` for gosec security scan
- Never commit secrets or API keys
- Use environment variables or keychain for credentials

## Testing Guidelines

### Don't Test What the Type System Already Checks

**AVOID tests that verify:**
- Constants equal their literal values
- Simple constructors return non-nil
- Assigned fields have assigned values
- Empty/nil collections are empty
- Basic type properties

**DO test:**
- Error handling paths and edge cases
- Business logic and algorithms
- API interactions and response handling
- State mutations and side effects
- Complex conditional logic
- Integration between components

### Test Pattern
```go
func TestBusinessLogic(t *testing.T) {
    // Arrange
    input := complexInput()
    
    // Act
    result, err := BusinessLogic(input)
    
    // Assert
    if err != nil {
        t.Errorf("unexpected error: %v", err)
    }
    if result.ExpectedField != expectedValue {
        t.Errorf("got %v, want %v", result.ExpectedField, expectedValue)
    }
}
```

## Monorepo Management

### Submodule Operations
```bash
# Check all submodule status
./.agents/skills/monorepo-cli/scripts/check-status.sh

# Check if submodules are synced
./.agents/skills/monorepo-cli/scripts/sync-check.sh

# Update all submodules
git submodule update --init --recursive
git submodule update --remote --merge

# See only projects with issues
./.agents/skills/monorepo-cli/scripts/monorepo-status.sh --issues
```

### Working in Embedded Repos
Each embedded repo is its own git repository:
```bash
cd Google-Drive-CLI
# Work normally - commit, push from within
git status
git add .
git commit -m "message"
git push
```

### Monorepo Guidelines

**NO FORKS OR ARCHIVED**: This monorepo contains only original, active CLI projects. Forked repositories and archived projects should NOT be added as submodules. If you need to track a fork, document it in comments but keep it separate.

**Adding New CLI Projects**:
```bash
# Only add original, active projects (never forks or archived)
git submodule add https://github.com/dl-alexandre/PROJECT-NAME.git PROJECT-NAME
# Update README.md and .agents skills accordingly
git add README.md .gitmodules
```

## Go Version

All projects use **Go 1.24.0** (specified in go.mod)

## Common Gotchas

1. **Import cycles**: Keep internal package dependencies acyclic
2. **Pre-commit hook**: May fail on lint errors - fix before committing
3. **Submodule changes**: Remember to commit in both submodule and superrepo
4. **Race detection**: Tests run with `-race` flag by default
5. **Short tests**: Pre-commit uses `-short` flag; integration tests need `-tags=integration`
