# Concurrent Data Processing Pipeline

Build a concurrent data processing pipeline using Swift's structured concurrency. All source files should be placed in `/workspace/Sources/`.

## Requirements

### Stage Protocol

Define a `Stage` protocol:

```swift
protocol Stage<Input, Output>: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    func process(_ input: Input) async throws -> Output
}
```

### Built-in Stages

Implement at least three concrete stages:
- `MapStage<I: Sendable, O: Sendable>` — Transforms input using a `@Sendable` closure
- `FilterStage<T: Sendable>` — Filters items based on a `@Sendable` predicate (throws on filtered-out items)
- `BatchStage<T: Sendable>` — Collects items into arrays of a specified batch size

### Pipeline Actor

Create a `Pipeline` actor that:
- Manages an ordered list of processing stages
- Provides a `process(_ items: [Item]) async throws -> [Result]` method
- Uses a `TaskGroup` to process items concurrently
- Accepts a `maxConcurrency` parameter to limit concurrent processing
- Collects results **in the original input order** despite concurrent execution
- Handles cancellation: stages should check `Task.isCancelled`

### Error Handling

- Define a `PipelineError` enum with cases for stage failures and cancellation
- If a stage throws, propagate the error but don't crash the entire pipeline — collect errors per item
- Use `Result<Output, Error>` to represent per-item outcomes

### Entry Point

Create a `main.swift` that demonstrates:
1. Building a pipeline with several stages
2. Processing a batch of items concurrently
3. Printing results and any errors

## Constraints

- No external dependencies — use only the Swift standard library
- All types that cross concurrency boundaries must be properly `Sendable`
- Use structured concurrency (`TaskGroup`) — do not use detached tasks
- Do not read actor state before an `await` and assume it's unchanged after
- Handle task cancellation explicitly with `Task.isCancelled` or `try Task.checkCancellation()`
