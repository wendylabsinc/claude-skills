FROM swift-server-lint-eval-base

# Create workspace with pre-scaffolded Package.swift
RUN mkdir -p /workspace/Sources && \
    cat > /workspace/Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "concurrent-pipeline",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "concurrent-pipeline",
            path: "Sources"
        ),
    ]
)
EOF

WORKDIR /workspace
