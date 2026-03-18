# Custom TCP Protocol Handler

Implement a simple key-value store protocol over TCP using SwiftNIO. All source files should be placed in `/workspace/Sources/`.

## Protocol Format

Messages are length-prefixed binary frames:

```
+----------------+------------------+
| Length (4 bytes, big-endian UInt32) |
+----------------+------------------+
| Payload (UTF-8 string)             |
+------------------------------------+
```

Commands are newline-separated within the payload:
- `SET <key> <value>` — Store a value
- `GET <key>` — Retrieve a value
- `DELETE <key>` — Remove a value

Responses:
- `OK` — Successful SET/DELETE
- `VALUE <value>` — Successful GET
- `NOT_FOUND` — Key doesn't exist
- `ERROR <message>` — Invalid command

## Requirements

### MessageDecoder

Create a `MessageDecoder` conforming to `ByteToMessageDecoder`:
- Read the 4-byte length prefix
- Wait for enough bytes, then decode the UTF-8 payload
- Handle partial reads correctly

### MessageEncoder

Create a `MessageEncoder` conforming to `MessageToByteEncoder`:
- Write the 4-byte length prefix followed by the UTF-8 payload

### KVStoreHandler

Create a `KVStoreHandler` conforming to `ChannelInboundHandler`:
- Parse incoming commands (GET/SET/DELETE)
- Store key-value pairs in a dictionary
- Send appropriate responses
- Handle errors and close connections gracefully

### Server Setup

Create a `main.swift` that:
1. Creates a `MultiThreadedEventLoopGroup`
2. Sets up a `ServerBootstrap` with the channel pipeline: `MessageDecoder` → `KVStoreHandler` → `MessageEncoder`
3. Binds to `localhost:8080`
4. Waits for the server to close

## Constraints

- Use only `swift-nio` (already in Package.swift)
- Never call `.wait()` inside a `ChannelHandler` or on an `EventLoop`
- Never use `Thread.sleep` or other blocking calls in handlers
- Handle `ByteBuffer` reads without leaking memory
- Ensure proper `EventLoopGroup` shutdown
- All handler types must be `Sendable` where required
