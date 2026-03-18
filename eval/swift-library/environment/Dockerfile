FROM swift-server-lint-eval-base

# Create workspace with pre-scaffolded Package.swift
RUN mkdir -p /workspace/Sources/MetricsKit && \
    cat > /workspace/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MetricsKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MetricsKit", targets: ["MetricsKit"]),
    ],
    targets: [
        .target(
            name: "MetricsKit",
            path: "Sources/MetricsKit"
        ),
    ]
)
EOF

WORKDIR /workspace
