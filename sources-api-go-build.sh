#!/bin/bash
# Build script for Sources API Go image from sources-api-go source
# This script builds the sources-api-go Docker image and pushes it to quay.io/insights-onprem

set -e

# Configuration
REGISTRY="${REGISTRY:-quay.io/insights-onprem}"
VERSION="${VERSION:-latest}"
CONTAINER_CMD="${CONTAINER_CMD:-docker}"
IMAGE_NAME="${REGISTRY}/sources-api-go:${VERSION}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_API_GO_PATH="${SCRIPT_DIR}/../sources-api-go"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if sources-api-go source exists
if [ ! -d "$SOURCES_API_GO_PATH" ]; then
    log_error "sources-api-go source not found at: $SOURCES_API_GO_PATH"
    log_error "Please ensure sources-api-go is cloned in the parent directory"
    log_error "Expected structure:"
    log_error "  insights-onprem/"
    log_error "  ├── sources-api-go/"
    log_error "  └── insights-onprem-dependencies/"
    exit 1
fi

# Check if required Go source files exist
required_files=(
    "$SOURCES_API_GO_PATH/go.mod"
    "$SOURCES_API_GO_PATH/go.sum"
    "$SOURCES_API_GO_PATH/main.go"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Required file not found: $file"
        exit 1
    fi
done

# Check if Dockerfile exists in sources-api-go
if [ ! -f "$SOURCES_API_GO_PATH/Dockerfile" ]; then
    log_error "Dockerfile not found at: $SOURCES_API_GO_PATH/Dockerfile"
    exit 1
fi

log_info "Building sources-api-go image..."
log_info "Registry: $REGISTRY"
log_info "Version: $VERSION"
log_info "Image: $IMAGE_NAME"
log_info "Container command: $CONTAINER_CMD"
log_info "Build context: $SOURCES_API_GO_PATH"

# Build the image
log_info "Starting Docker build..."
$CONTAINER_CMD build \
    -t "$IMAGE_NAME" \
    "$SOURCES_API_GO_PATH"

if [ $? -eq 0 ]; then
    log_info "✓ Image built successfully: $IMAGE_NAME"
else
    log_error "✗ Failed to build image"
    exit 1
fi

# Test the image
log_info "Testing the built image..."
if $CONTAINER_CMD run --rm "$IMAGE_NAME" --help > /dev/null 2>&1; then
    log_info "✓ Image test passed"
else
    log_warn "⚠ Image test failed (this may be expected)"
fi

# Push if requested
if [ "$1" = "push" ] || [ "$PUSH" = "true" ]; then
    log_info "Pushing image to registry..."
    
    # Check if logged in
    if ! $CONTAINER_CMD info > /dev/null 2>&1; then
        log_error "Container runtime not available"
        exit 1
    fi
    
    $CONTAINER_CMD push "$IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        log_info "✓ Image pushed successfully: $IMAGE_NAME"
    else
        log_error "✗ Failed to push image"
        exit 1
    fi
fi

log_info "Build completed successfully!"
log_info "Image: $IMAGE_NAME"

# Show usage information
if [ "$1" != "push" ] && [ "$PUSH" != "true" ]; then
    echo ""
    log_info "To push the image, run:"
    log_info "  $0 push"
    log_info "Or set PUSH=true environment variable"
    echo ""
    log_info "To run the image:"
    log_info "  $CONTAINER_CMD run --rm -p 8080:8080 $IMAGE_NAME"
fi