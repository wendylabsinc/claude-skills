FROM swift-server-lint-eval-base

# Create workspace with pre-scaffolded Package.swift
RUN mkdir -p /workspace/Sources && \
    cat > /workspace/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "postgres-api",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
    ],
    targets: [
        .executableTarget(
            name: "postgres-api",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ],
            path: "Sources"
        ),
    ]
)
EOF

# Pre-fetch dependencies
WORKDIR /workspace
RUN swift package resolve
