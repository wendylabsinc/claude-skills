# REST API with Authentication using Hummingbird 2

Build a REST API using Hummingbird 2 that manages a collection of items with API key authentication. All source files should be placed in `/workspace/Sources/`.

## Requirements

### Item Model

```swift
struct Item: Codable, Sendable {
    let id: UUID
    var name: String
    var description: String
    var price: Double
}
```

### Custom Request Context

Create an `AppRequestContext` struct conforming to `RequestContext`:
- Include the standard `coreContext` property
- Add an optional `apiKey: String?` property for storing the authenticated API key
- Implement the required `init(source:)` initializer

### Routes

Implement the following endpoints:
- `GET /items` — List all items (returns JSON array)
- `POST /items` — Create a new item (accepts JSON body, returns created item)
- `GET /items/:id` — Get a single item by ID (returns 404 if not found)
- `DELETE /items/:id` — Delete an item by ID (returns 404 if not found)

### Authentication Middleware

Create a `APIKeyMiddleware` that:
- Reads the `X-API-Key` header from incoming requests
- Returns HTTP 401 Unauthorized if the header is missing or doesn't match the expected key
- Passes the request through if authentication succeeds

### Logging Middleware

Create a `LoggingMiddleware` that:
- Logs the HTTP method and path of each request
- Uses Swift's `Logging` library
- Passes the request through to the next handler

### Entry Point

Create a `main.swift` that:
1. Creates the `Router<AppRequestContext>`
2. Adds the logging middleware first, then the authentication middleware
3. Registers all routes
4. Starts the application on `0.0.0.0:8080`

## Constraints

- Use Hummingbird 2 (already in Package.swift)
- Use proper `RequestContext` conformance — don't mutate context without `inout`
- All route handlers should be async
- Use proper HTTP status codes (200, 201, 404, 401)
- Handle JSON decoding errors gracefully
- All types crossing concurrency boundaries must be `Sendable`
