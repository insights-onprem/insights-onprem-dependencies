# Usage Guide - Insights On-Premise Dependencies

This guide provides step-by-step instructions for using the Insights On-Premise Dependencies project to build and deploy custom images for the Insights On-Premise platform.

## Quick Start

### 1. Prerequisites Setup

```bash
# Ensure you have a container runtime installed
# macOS with Homebrew (recommended):
brew install podman

# Start podman machine on macOS
podman machine init
podman machine start

# Or install Docker
brew install --cask docker
```

### 2. Clone Required Repositories

Set up the required directory structure:

```bash
# Create workspace directory
mkdir -p ~/dev/insights-onprem
cd ~/dev/insights-onprem

# Clone this dependencies repository
git clone git@github.com:insights-onprem/insights-onprem-dependencies.git

# Clone required source repositories
git clone git@github.com:insights-onprem/insights-ingress-go.git
git clone git@github.com:insights-onprem/sources-api-go.git

# Verify directory structure
ls -la
# Should show:
# insights-onprem-dependencies/
# insights-ingress-go/
# sources-api-go/
```

### 3. Build All Images

```bash
cd insights-onprem-dependencies

# Build all images with podman (preferred)
CONTAINER_CMD=podman make build

# Or with docker
make build

# Check built images
podman images | grep insights-onprem
```

### 4. Test Images

```bash
# Test all images
make test

# Test individual images
make test-redis
make test-ingress
make test-sources-api-go
```

### 5. Push to Registry (Optional)

```bash
# Login to quay.io
podman login quay.io

# Push all images
make push

# Or push individual images
make push-redis
make push-ingress
make push-sources-api-go
```

### 6. Use with ros-ocp-backend

```bash
# Update ros-ocp-backend docker-compose.yml to use custom images
# Replace image references:
# quay.io/cloudservices/redis-ephemeral:6 → quay.io/insights-onprem/redis-ephemeral:6
# quay.io/cloudservices/insights-ingress:latest → quay.io/insights-onprem/insights-ingress:latest
# quay.io/cloudservices/sources-api-go → quay.io/insights-onprem/sources-api-go:latest

# Start services with custom images
cd /path/to/ros-ocp-backend/scripts/
podman-compose up -d
```

## Detailed Usage

### Building Images

#### Build All Images

```bash
# Using Makefile (recommended)
make build

# With custom version
VERSION=v1.0.0 make build

# With custom registry
REGISTRY=my-registry.com/insights make build

# Using podman on macOS
CONTAINER_CMD=podman make build
```

#### Build Individual Images

```bash
# Redis ephemeral
make build-redis

# Insights Ingress (requires insights-ingress-go source)
make build-ingress

# Sources API Go (requires sources-api-go source)
make build-sources-api-go

# Sources API Go using enhanced build script
make build-sources-api-go-script
```

#### Using Build Scripts Directly

```bash
# Insights Ingress
cd insights-ingress
./build.sh

# Sources API Go
cd sources-api-go
./build.sh

# Sources API Go with push
cd sources-api-go
./build.sh push
```

### Environment Configuration

#### Build Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_CMD` | auto-detected | Container runtime (podman/docker) |
| `REGISTRY` | `quay.io/insights-onprem` | Target registry |
| `VERSION` | `latest` | Image version tag |
| `PLATFORM` | `linux/amd64` | Target platform for builds |

#### Examples

```bash
# Build with custom configuration
CONTAINER_CMD=podman \
REGISTRY=my-registry.com/insights \
VERSION=v2.0.0 \
make build

# Build for specific platform
PLATFORM=linux/arm64 make build-sources-api-go-script
```

### Testing Images

#### Automated Testing

```bash
# Test all images
make test

# Test specific images
make test-redis
make test-ingress  
make test-sources-api-go
```

#### Manual Testing

```bash
# Test Redis functionality
podman run -d --name test-redis \
  -p 6379:6379 \
  quay.io/insights-onprem/redis-ephemeral:6

# Test Redis operations
podman exec test-redis redis-cli ping
podman exec test-redis redis-cli set test "hello"
podman exec test-redis redis-cli get test

# Clean up
podman stop test-redis
podman rm test-redis

# Test Sources API Go
podman run --rm \
  -e SOURCES_ENV=prod \
  -e ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ \
  quay.io/insights-onprem/sources-api-go:latest --help
```

### Registry Operations

#### Login to Registry

```bash
# Login to quay.io
podman login quay.io

# Or with credentials
echo $REGISTRY_PASSWORD | podman login -u $REGISTRY_USER --password-stdin quay.io
```

#### Push Images

```bash
# Push all images
make push

# Push individual images
make push-redis
make push-ingress
make push-sources-api-go

# Push with custom registry
REGISTRY=my-registry.com/insights make push
```

### Integration with ros-ocp-backend

#### Direct Image Replacement

To use the locally built images, modify the original docker-compose.yml:

```yaml
# In ros-ocp-backend/scripts/docker-compose.yml
# Replace these image references:

# FROM:
redis:
  image: quay.io/cloudservices/redis-ephemeral:6

# TO:
redis:
  image: quay.io/insights-onprem/redis-ephemeral:6

# Similarly for other services:
# quay.io/cloudservices/insights-ingress:latest → quay.io/insights-onprem/insights-ingress:latest
# quay.io/cloudservices/sources-api-go → quay.io/insights-onprem/sources-api-go:latest
```

## macOS Development

### Cross-Platform Building

All build scripts are optimized for macOS development:

```bash
# Automatic platform detection (builds linux/amd64 on Apple Silicon)
cd sources-api-go
./build.sh

# Explicit platform specification
PLATFORM=linux/amd64 ./build.sh

# Using podman on macOS
CONTAINER_CMD=podman ./build.sh
```

### Podman Setup on macOS

```bash
# Install podman
brew install podman

# Initialize and start podman machine
podman machine init
podman machine start

# Verify podman is working
podman info

# Set default container command
export CONTAINER_CMD=podman
```

## Troubleshooting

### Common Build Issues

#### Source Repository Missing

```
ERROR: sources-api-go source not found at: ../../sources-api-go
```

**Solution**: Ensure source repositories are cloned in the parent directory:
```bash
cd ..
git clone git@github.com:insights-onprem/sources-api-go.git
git clone git@github.com:insights-onprem/insights-ingress-go.git
```

#### Container Runtime Issues

```
ERROR: No container runtime found
```

**Solution**: Install and configure container runtime:
```bash
# macOS with podman
brew install podman
podman machine init && podman machine start

# Or use docker
brew install --cask docker
```

#### Build Platform Warnings

```
WARNING: image platform (linux/amd64) does not match the expected platform
```

**Solution**: This is expected on Apple Silicon. The build will work correctly for deployment on x86_64 Linux systems.

### Common Runtime Issues

#### Sources API Go Encryption Errors

```
panic: encryption_key.dev file does not exist
```

**Solution**: Set the required environment variables in your docker-compose.yml:
```yaml
environment:
  - ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ
  - SOURCES_ENV=prod
```

#### Database Connection Issues

```
failed to connect to database: hostname resolving error
```

**Solution**: Ensure all services are running:
```bash
podman-compose ps
podman-compose logs db-sources
```

### Registry Issues

#### Authentication Failures

```
Error: unable to retrieve auth token: invalid username/password
```

**Solution**: Login to the registry:
```bash
podman login quay.io
# Enter your username and password
```

#### Push Failures

```
Error: failed to push image: access denied
```

**Solution**: Ensure you have push access to the quay.io/insights-onprem organization.

## Advanced Usage

### Custom Registry Deployment

```bash
# Build for private registry
REGISTRY=my-registry.com/insights make build

# Push to private registry
REGISTRY=my-registry.com/insights make push

# Update docker-compose.yml for custom registry
sed -i 's|quay.io/insights-onprem|my-registry.com/insights|g' /path/to/ros-ocp-backend/scripts/docker-compose.yml
```

### Version Management

```bash
# Build with semantic version
VERSION=v1.2.3 make build

# Tag and push specific version
VERSION=v1.2.3 make build push

# Use version in ros-ocp-backend
# Edit docker-compose.yml to use specific tags
```

### Development Workflow

```bash
# 1. Make changes to source repositories
cd ../sources-api-go
# ... make changes ...

# 2. Build and test locally
cd ../insights-onprem-dependencies
make build-sources-api-go
make test-sources-api-go

# 3. Test integration
# Update ros-ocp-backend/scripts/docker-compose.yml with new image
cd /path/to/ros-ocp-backend/scripts/
podman-compose up -d

# 4. Push to registry when ready
make push-sources-api-go
```

## Best Practices

### Image Management
- Use semantic versioning for production releases
- Keep latest tag for development builds
- Test images thoroughly before pushing to registry
- Regularly update base images for security

### Development
- Always test locally before pushing
- Use podman on macOS for better performance
- Keep source repositories up to date
- Use the Makefile for consistent builds

### Deployment
- Update docker-compose.yml files to reference local images
- Monitor container resource usage
- Implement proper health checks
- Use specific version tags in production

## Available Make Targets

```bash
# Building
make build                    # Build all images
make build-redis              # Build Redis image
make build-ingress            # Build Insights Ingress image
make build-sources-api-go     # Build Sources API Go image (direct)
make build-sources-api-go-script # Build Sources API Go (using script)

# Testing
make test                     # Test all images
make test-redis               # Test Redis image
make test-ingress             # Test Insights Ingress image  
make test-sources-api-go      # Test Sources API Go image

# Registry operations
make push                     # Push all images
make push-redis               # Push Redis image
make push-ingress             # Push Insights Ingress image
make push-sources-api-go      # Push Sources API Go image

# Utilities
make build-push               # Build and push all images
make clean                    # Remove local images
make login                    # Login to registry
make help                     # Show available targets
```

This guide covers the essential usage patterns for building, testing, and deploying images with the Insights On-Premise Dependencies project.