#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-/workspace}"
REWARD_DIR="/logs/verifier"
REWARD_FILE="$REWARD_DIR/reward.txt"
REWARD_JSON="$REWARD_DIR/reward.json"

mkdir -p "$REWARD_DIR"

cd "$WORKSPACE"

# Step 1: Try to build
BUILD_OUTPUT=$(swift build 2>&1) || {
    echo "0.0" > "$REWARD_FILE"
    cat > "$REWARD_JSON" <<ENDJSON
{
  "compiles": false,
  "errors": 0,
  "warnings": 0,
  "infos": 0,
  "score": 0.0,
  "build_output": $(echo "$BUILD_OUTPUT" | tail -50 | jq -Rs .),
  "diagnostics": []
}
ENDJSON
    echo "Build failed. Score: 0.0"
    exit 0
}

echo "Build succeeded."

# Step 2: Run swift-server-lint
LINT_OUTPUT=$(swift-server-lint --format json --all-rules "$WORKSPACE" 2>/dev/null) || true

# Step 3: Parse diagnostics
ERRORS=$(echo "$LINT_OUTPUT" | jq '[.diagnostics[] | select(.severity == "error")] | length')
WARNINGS=$(echo "$LINT_OUTPUT" | jq '[.diagnostics[] | select(.severity == "warning")] | length')
INFOS=$(echo "$LINT_OUTPUT" | jq '[.diagnostics[] | select(.severity == "info")] | length')

# Step 4: Calculate score: 1.0 - 0.15*errors - 0.05*warnings, floor 0.0
SCORE=$(awk "BEGIN { s = 1.0 - ($ERRORS * 0.15) - ($WARNINGS * 0.05); if (s < 0) s = 0; printf \"%.4f\", s }")

# Step 5: Write reward
echo "$SCORE" > "$REWARD_FILE"

# Step 6: Write detailed breakdown
DIAGNOSTICS=$(echo "$LINT_OUTPUT" | jq '.diagnostics')
cat > "$REWARD_JSON" <<ENDJSON
{
  "compiles": true,
  "errors": $ERRORS,
  "warnings": $WARNINGS,
  "infos": $INFOS,
  "score": $SCORE,
  "diagnostics": $DIAGNOSTICS
}
ENDJSON

echo "Lint results: $ERRORS errors, $WARNINGS warnings, $INFOS infos"
echo "Score: $SCORE"
