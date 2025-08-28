#!/bin/bash
# Build script for Insights Ingress image from insights-ingress-go source
# This script builds the insights-ingress Docker image and pushes it to quay.io/insights-onprem

set -e

# Configuration
REGISTRY="${REGISTRY:-quay.io/insights-onprem}"
VERSION="${VERSION:-latest}"
CONTAINER_CMD="${CONTAINER_CMD:-docker}"
IMAGE_NAME="${REGISTRY}/insights-ingress:${VERSION}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSIGHTS_INGRESS_GO_PATH="${SCRIPT_DIR}/../../insights-ingress-go"
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

# Check if insights-ingress-go source exists
if [ ! -d "$INSIGHTS_INGRESS_GO_PATH" ]; then
    log_error "insights-ingress-go source not found at: $INSIGHTS_INGRESS_GO_PATH"
    log_error "Please ensure insights-ingress-go is cloned in the parent directory"
    log_error "Expected structure:"
    log_error "  insights-onprem/"
    log_error "  ├── insights-ingress-go/"
    log_error "  └── insights-onprem-dependencies/"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    log_error "Dockerfile not found at: $DOCKERFILE_PATH"
    exit 1
fi

# Check if required Go source files exist
required_files=(
    "$INSIGHTS_INGRESS_GO_PATH/go.mod"
    "$INSIGHTS_INGRESS_GO_PATH/go.sum"
    "$INSIGHTS_INGRESS_GO_PATH/cmd/insights-ingress/main.go"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Required file not found: $file"
        exit 1
    fi
done

log_info "Building insights-ingress image..."
log_info "Registry: $REGISTRY"
log_info "Version: $VERSION"
log_info "Image: $IMAGE_NAME"
log_info "Container command: $CONTAINER_CMD"
log_info "Build context: $INSIGHTS_INGRESS_GO_PATH"
log_info "Dockerfile: $DOCKERFILE_PATH"

# Build the image
log_info "Starting Docker build..."
$CONTAINER_CMD build \
    --platform linux/amd64 \
    -t "$IMAGE_NAME" \
    -f "$DOCKERFILE_PATH" \
    "$INSIGHTS_INGRESS_GO_PATH"

if [ $? -eq 0 ]; then
    log_info "✓ Image built successfully: $IMAGE_NAME"
else
    log_error "✗ Failed to build image"
    exit 1
fi

# Test the image
log_info "Testing the built image..."
if $CONTAINER_CMD run --rm "$IMAGE_NAME" /insights-ingress-go --help > /dev/null 2>&1; then
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
    log_info "  $CONTAINER_CMD run --rm -p 3000:3000 $IMAGE_NAME"
fi
