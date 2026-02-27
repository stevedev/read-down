#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESOURCES_DIR="$PROJECT_DIR/ReadDown/Resources"
JS_DIR="$RESOURCES_DIR/js"

MARKED_VERSION="15.0.6"
MERMAID_VERSION="11.4.1"
HLJS_VERSION="11.11.1"

echo "==> Setting up ReadDown dependencies..."

if ! command -v xcodegen &> /dev/null; then
    echo "==> Installing XcodeGen via Homebrew..."
    brew install xcodegen
else
    echo "==> XcodeGen already installed."
fi

echo "==> Downloading marked.js v${MARKED_VERSION}..."
curl --silent --location \
    "https://cdn.jsdelivr.net/npm/marked@${MARKED_VERSION}/marked.min.js" \
    --output "$JS_DIR/marked.min.js"

echo "==> Downloading mermaid.js v${MERMAID_VERSION}..."
curl --silent --location \
    "https://cdn.jsdelivr.net/npm/mermaid@${MERMAID_VERSION}/dist/mermaid.min.js" \
    --output "$JS_DIR/mermaid.min.js"

echo "==> Downloading highlight.js v${HLJS_VERSION}..."
curl --silent --location \
    "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${HLJS_VERSION}/build/highlight.min.js" \
    --output "$JS_DIR/highlight.min.js"

echo "==> Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate

echo ""
echo "==> Setup complete!"
echo "    Open ReadDown.xcodeproj in Xcode, or run: make build"
