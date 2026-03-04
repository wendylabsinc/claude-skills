# Stage 1: Build swift-server-lint
FROM swift:6.2.3 AS builder

WORKDIR /build
COPY swift-server-lint/ ./swift-server-lint/

WORKDIR /build/swift-server-lint
RUN swift build -c release --static-swift-stdlib 2>&1 | tail -5

# Stage 2: Runtime image with linter installed
FROM swift:6.2.3

RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/swift-server-lint/.build/release/swift-server-lint /usr/local/bin/swift-server-lint

COPY eval/shared/grade.sh /tests/grade.sh
RUN chmod +x /tests/grade.sh

RUN mkdir -p /workspace /logs/verifier

WORKDIR /workspace
