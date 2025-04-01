# CLAUDE.md - VDAnimation Development Guide

## Build Commands
```bash
swift build                     # Build the package
swift test                      # Run all tests
swift test --filter <TestName>  # Run a specific test
```

## Code Style Guidelines

### Architecture
- Protocol-oriented design with type erasure
- Builder pattern with result builders for animations
- Prefer structs over classes when possible

### Formatting & Naming
- Use 4-space indentation
- Follow Swift naming conventions (PascalCase for types, camelCase for methods/properties)
- Group extensions by functionality
- Line breaks after function declarations and between logical sections

### Types & Error Handling
- Use generics for type-safe animations
- Prefer optionals over forced unwrapping
- Use clear documentation for public APIs
- Wrap side effects in optional closures

### Imports
- Foundation imports first, followed by UI frameworks
- Keep imports minimal and necessary

### Testing
- Test basic motions, compositions, edge cases
- Verify interpolated values at various time points (0.0, 0.5, 1.0)
- Test complex compositions and timing calculations