# Public Library API Design — MetricsKit

Design a public Swift library called `MetricsKit` that provides a metrics collection API. All source files should be placed in `/workspace/Sources/MetricsKit/`.

## Requirements

### MetricsCollector Protocol

Define a public protocol:

```swift
public protocol MetricsCollector<Metric>: Sendable {
    associatedtype Metric: Sendable
    func record(_ metric: Metric)
    func reset()
}
```

### Counter

Create a public `Counter` struct conforming to `MetricsCollector`:
- Thread-safe using an actor or atomic operations
- `Metric` type is `Int`
- Additional method: `increment(by: Int = 1)`
- The `record(_ metric:)` method adds to the current count
- Provide a `value` property to read the current count

### Gauge

Create a public `Gauge` struct conforming to `MetricsCollector`:
- Thread-safe using an actor or atomic operations
- `Metric` type is `Double`
- Additional methods: `increment(by: Double = 1.0)`, `decrement(by: Double = 1.0)`
- The `record(_ metric:)` method sets the current value
- Provide a `value` property to read the current value

### MetricsRegistry

Create a public `MetricsRegistry` actor:
- Stores named collectors: `register<C: MetricsCollector>(_ collector: C, named: String)`
- Retrieves collectors by name: `collector<C: MetricsCollector>(named: String, as: C.Type) -> C?`
- Lists all registered names: `var registeredNames: [String]`
- Unregister: `unregister(named: String)`

### Performance Considerations

- Mark hot-path methods with `@inlinable` and annotate internal dependencies with `@usableFromInline`
- Use concrete types (generics) instead of `any MetricsCollector` in performance-critical paths
- Avoid existential types (`any Protocol`) in hot paths

### Access Control

- Public API: `MetricsCollector`, `Counter`, `Gauge`, `MetricsRegistry`
- Internal: Implementation details, storage types
- Use `@usableFromInline internal` for types referenced by `@inlinable` methods

### Cross-Platform

- Must compile on both macOS and Linux
- Do not use Foundation types — use Swift standard library only
- Use `#if canImport(Glibc)` / `#if canImport(Darwin)` if platform-specific code is needed

## Constraints

- No external dependencies
- Do not import Foundation
- All public types must be `Sendable`
- Do not expose internal types through public `@inlinable` methods without `@usableFromInline`
- Do not use `public import` — use `internal import` or regular `import`
