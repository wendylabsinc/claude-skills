# User CRUD with PostgreSQL

Build a Swift server application that manages users in PostgreSQL using `postgres-nio`. All source files should be placed in `/workspace/Sources/`.

## Requirements

### User Model

Create a `User` struct that is both `Codable` and `Sendable`:

```swift
struct User: Codable, Sendable {
    let id: UUID
    var username: String
    var email: String
    var createdAt: Date
}
```

### UserRepository

Create a `UserRepository` actor that wraps a `PostgresClient` and provides CRUD operations:

- `createUser(username:email:) async throws -> User` — Insert a new user and return it
- `getUser(id:) async throws -> User?` — Fetch a user by ID
- `updateUser(id:username:email:) async throws -> User` — Update a user's fields
- `deleteUser(id:) async throws -> Bool` — Delete a user, returning whether it existed
- `listUsers(limit:offset:) async throws -> [User]` — List users with pagination

### Database Requirements

- Use **parameterized queries** for all database operations (never interpolate values into SQL strings)
- Use `PostgresClient` for connection lifecycle management
- Handle database errors appropriately with custom error types
- Create the users table if it doesn't exist on startup

### Entry Point

Create a `main.swift` that:
1. Configures a `PostgresClient`
2. Creates the users table
3. Demonstrates basic CRUD operations (create a user, read it back, update it, delete it)

## Constraints

- Use only `postgres-nio` for database access (already in Package.swift)
- Do not use Foundation where possible — prefer Swift standard library types
- All types that cross concurrency boundaries must be `Sendable`
- Handle errors with proper Swift error types, not force-unwraps or force-tries
