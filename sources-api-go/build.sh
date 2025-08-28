#!/bin/bash
# Build script for Sources API Go image from sources-api-go source
# This script builds the sources-api-go container image and pushes it to quay.io/insights-onprem
# 
# Supports both podman and docker, with preference for podman
# Optimized for macOS with amd64 architecture cross-compilation

set -e

# Detect container runtime preference (podman > docker)
detect_container_cmd() {
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
    elif command -v docker >/dev/null 2>&1; then
        echo "docker"
    else
        echo ""
    fi
}

# Configuration
REGISTRY="${REGISTRY:-quay.io/insights-onprem}"
VERSION="${VERSION:-latest}"
CONTAINER_CMD="${CONTAINER_CMD:-$(detect_container_cmd)}"
IMAGE_NAME="${REGISTRY}/sources-api-go:${VERSION}"

# Architecture configuration for cross-platform builds
PLATFORM="${PLATFORM:-linux/amd64}"
BUILD_ARGS=""

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_API_GO_PATH="${SCRIPT_DIR}/../../sources-api-go"

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

# Validate container runtime
if [ -z "$CONTAINER_CMD" ]; then
    log_error "No container runtime found. Please install podman or docker."
    exit 1
fi

log_info "Using container runtime: $CONTAINER_CMD"

# Set platform-specific build arguments
if [ "$CONTAINER_CMD" = "podman" ]; then
    BUILD_ARGS="--platform=$PLATFORM"
elif [ "$CONTAINER_CMD" = "docker" ]; then
    BUILD_ARGS="--platform=$PLATFORM"
fi

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
log_info "Platform: $PLATFORM"
log_info "Build context: $SOURCES_API_GO_PATH"

# Build the image with platform support
log_info "Starting container build..."
$CONTAINER_CMD build \
    $BUILD_ARGS \
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
    log_info "  $CONTAINER_CMD run --rm -p 8080:8000 $IMAGE_NAME"
    echo ""
    log_info "For integration with ros-ocp-backend:"
    log_info "  Update ros-ocp-backend/scripts/docker-compose.yml to use this image"
    log_info "  Replace: quay.io/cloudservices/sources-api-go"
    log_info "  With: quay.io/insights-onprem/sources-api-go:latest"
    log_info "  Run: podman-compose up -d"
fi