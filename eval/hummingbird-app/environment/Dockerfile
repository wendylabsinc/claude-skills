FROM swift-server-lint-eval-base

# Create workspace with pre-scaffolded Package.swift
RUN mkdir -p /workspace/Sources && \
    cat > /workspace/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "hummingbird-app",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "hummingbird-app",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
            ],
            path: "Sources"
        ),
    ]
)
EOF

# Pre-fetch dependencies
WORKDIR /workspace
RUN swift package resolve
