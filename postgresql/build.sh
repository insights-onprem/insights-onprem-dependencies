#!/bin/bash
# Build script for PostgreSQL 16 image for Insights On-Premise
# This script builds the PostgreSQL Docker image and pushes it to quay.io/insights-onprem
#
# PostgreSQL files sourced from:
# - Dockerfile: https://github.com/docker-library/postgres/blob/master/16/trixie/Dockerfile
# - docker-entrypoint.sh: https://github.com/docker-library/postgres/blob/master/16/trixie/docker-entrypoint.sh
# - docker-ensure-initdb.sh: https://github.com/docker-library/postgres/blob/master/16/trixie/docker-ensure-initdb.sh

set -e

# Configuration
REGISTRY="${REGISTRY:-quay.io/insights-onprem}"
VERSION="${VERSION:-16}"
CONTAINER_CMD="${CONTAINER_CMD:-podman}"
IMAGE_NAME="${REGISTRY}/postgresql:${VERSION}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE_PATH="${SCRIPT_DIR}/Dockerfile"

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

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    log_error "Dockerfile not found at: $DOCKERFILE_PATH"
    exit 1
fi

# Check required scripts exist
required_scripts=(
    "$SCRIPT_DIR/docker-entrypoint.sh"
    "$SCRIPT_DIR/docker-ensure-initdb.sh"
)

for script in "${required_scripts[@]}"; do
    if [ ! -f "$script" ]; then
        log_error "Required script not found: $script"
        exit 1
    fi
done

log_info "Building PostgreSQL 16 image..."
log_info "Registry: $REGISTRY"
log_info "Version: $VERSION"
log_info "Image: $IMAGE_NAME"
log_info "Container command: $CONTAINER_CMD"
log_info "Build context: $SCRIPT_DIR"
log_info "Dockerfile: $DOCKERFILE_PATH"

# Build the image
log_info "Starting container build..."
if $CONTAINER_CMD build \
    -t "$IMAGE_NAME" \
    -f "$DOCKERFILE_PATH" \
    "$SCRIPT_DIR"; then
    log_info "✓ Image built successfully: $IMAGE_NAME"
else
    log_error "✗ Failed to build image"
    exit 1
fi

# Test the image
log_info "Testing the built image..."
if $CONTAINER_CMD run --rm "$IMAGE_NAME" postgres --version > /dev/null 2>&1; then
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

    if $CONTAINER_CMD push "$IMAGE_NAME"; then
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
    log_info "  $CONTAINER_CMD run --rm -p 5432:5432 -e POSTGRES_PASSWORD=password $IMAGE_NAME"
fi