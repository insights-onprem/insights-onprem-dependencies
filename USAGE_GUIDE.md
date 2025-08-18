# Usage Guide - Insights On-Premise Dependencies

This guide provides step-by-step instructions for using the Insights On-Premise Dependencies project to replace external image dependencies.

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd insights-onprem-dependencies

# Set up development environment
make dev-setup
```

### 2. Build All Images

```bash
# Build all images
make build

# Or use the script directly
./scripts/build-all.sh
```

### 3. Test Images

```bash
# Test all images
make test

# Or test individual images
make test-redis
make test-ingress
make test-sources
```

### 4. Push to Registry

```bash
# Set registry credentials
export REGISTRY_USER="your-username"
export REGISTRY_PASSWORD="your-password"

# Push all images
make push
```

### 5. Update ros-ocp-backend

```bash
# Copy override file to ros-ocp-backend
cp docker-compose.override.yml /path/to/ros-ocp-backend/scripts/

# Use the updated images
cd /path/to/ros-ocp-backend/scripts/
docker-compose up
```

## Detailed Usage

### Building Images

#### Build All Images
```bash
# Using Makefile (recommended)
make build

# Using script directly
./scripts/build-all.sh

# With specific version
VERSION=1.0.0 make build
```

#### Build Individual Images
```bash
# Redis ephemeral
make build-redis
# or
./scripts/build-all.sh redis

# Insights Ingress
make build-ingress
# or
./scripts/build-all.sh ingress

# Sources API Go
make build-sources
# or
./scripts/build-all.sh sources
```

#### Custom Build Options
```bash
# Build with custom registry
REGISTRY=my-registry.com/insights make build

# Build with specific version
VERSION=2.1.0 make build

# Build using Podman instead of Docker
CONTAINER_CMD=podman make build
```

### Testing Images

#### Comprehensive Testing
```bash
# Test all images
make test

# Test with cleanup
make test clean
```

#### Individual Image Testing
```bash
# Test Redis functionality
make test-redis

# Test Ingress endpoints
make test-ingress

# Test Sources API
make test-sources

# Test security aspects
make test-security
```

#### Manual Testing
```bash
# Start Redis container for manual testing
podman run -d --name manual-redis \
  -p 6379:6379 \
  -e REDIS_MAXMEMORY=512mb \
  quay.io/insights-onprem/redis-ephemeral:6

# Test Redis operations
redis-cli ping
redis-cli set test "hello world"
redis-cli get test

# Clean up
podman stop manual-redis
podman rm manual-redis
```

### Pushing Images

#### Push All Images
```bash
# Set credentials via environment
export REGISTRY_USER="username"
export REGISTRY_PASSWORD="password"
make push

# Or use script directly
./scripts/push-all.sh
```

#### Push Individual Images
```bash
# Push only Redis images
make push-redis

# Push only Ingress image
make push-ingress

# Push only Sources API image
make push-sources
```

#### Verify Pushed Images
```bash
# Verify all images are accessible
make verify

# Or use script
./scripts/push-all.sh --verify
```

### Using with ROS OCP Backend

#### Method 1: podman Compose Override (Recommended)
```bash
# Copy override file
cp docker-compose.override.yml /path/to/ros-ocp-backend/scripts/

# Navigate to ros-ocp-backend
cd /path/to/ros-ocp-backend/scripts/

# Start services (override will be automatically applied)
podman-compose up
```

#### Method 2: Modify Original docker-compose.yml
```bash
# Edit ros-ocp-backend/scripts/docker-compose.yml
# Replace these lines:

# FROM:
# redis:
#   image: quay.io/cloudservices/redis-ephemeral:6

# TO:
# redis:
#   image: quay.io/insights-onprem/redis-ephemeral:6

# Similarly for other images:
# quay.io/cloudservices/insights-ingress:latest -> quay.io/insights-onprem/insights-ingress:latest
# quay.io/cloudservices/sources-api-go -> quay.io/insights-onprem/sources-api-go:latest
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REGISTRY` | `quay.io/insights-onprem` | Container registry |
| `VERSION` | `latest` | Image version tag |
| `REGISTRY_USER` | - | Registry username |
| `REGISTRY_PASSWORD` | - | Registry password |
| `CONTAINER_CMD` | auto-detect | Container runtime (docker/podman) |

### Redis Configuration

Redis can be customized via environment variables:

```bash
# Start with custom configuration
podman run -d \
  -e REDIS_MAXMEMORY=1gb \
  -e REDIS_MAXMEMORY_POLICY=allkeys-lfu \
  -e REDIS_PASSWORD=mypassword \
  quay.io/insights-onprem/redis-ephemeral:6
```

Available Redis environment variables:
- `REDIS_PORT` (default: 6379)
- `REDIS_MAXMEMORY` (default: 256mb)
- `REDIS_MAXMEMORY_POLICY` (default: allkeys-lru)
- `REDIS_PASSWORD` (default: none)
- `REDIS_DATABASES` (default: 16)

## Workflows

### Development Workflow

```bash
# 1. Make changes to Dockerfiles or configurations
# 2. Build affected images
make build-redis  # or specific image

# 3. Test changes
make test-redis

# 4. If tests pass, build all
make build

# 5. Test all
make test

# 6. Push to registry
make push
```

### CI/CD Workflow

```bash
# Build and test (CI)
make ci-build

# Deploy (CD)
make ci-deploy
```

### Complete Image Workflow

```bash
# Complete workflow for Redis
make redis-workflow

# Complete workflow for Ingress
make ingress-workflow

# Complete workflow for Sources API
make sources-workflow
```

### Production Deployment

```bash
# 1. Build with version tag
VERSION=1.2.0 make build

# 2. Test thoroughly
make test
make test-security

# 3. Tag with version
make tag-version VERSION=1.2.0

# 4. Push versioned images
VERSION=1.2.0 make push

# 5. Update deployment configurations
# 6. Deploy to production
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check Docker/Podman status
docker info
# or
podman info

# Clean up and retry
make clean
make build
```

#### Test Failures
```bash
# Check test logs
make logs-test

# Run individual tests
make test-redis

# Clean up test resources
make clean
```

#### Push Failures
```bash
# Check authentication
podman login quay.io

# Verify image exists locally
make info

# Try pushing individual image
make push-redis
```

#### Runtime Issues
```bash
# Check container logs
podman logs container-name

# Access container shell
make shell-redis

# Check health
podman exec container-name redis-cli ping
```

### Getting Help

```bash
# Show available targets
make help

# Show build information
make info

# Show documentation
make docs
```

## Advanced Usage

### Custom Registry

```bash
# Build for custom registry
REGISTRY=my-registry.com/myorg make build

# Push to custom registry
REGISTRY=my-registry.com/myorg make push
```

### Multi-Architecture Builds

```bash
# Enable Docker buildx
podman buildx create --use

# Build for multiple platforms
podman buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t quay.io/insights-onprem/redis-ephemeral:6 \
  redis-ephemeral/
```

## Integration Examples

### Docker Compose with Custom Configuration

```yaml
version: "3.8"
services:
  redis:
    image: quay.io/insights-onprem/redis-ephemeral:6
    ports:
      - "6379:6379"
    environment:
      - REDIS_MAXMEMORY=1gb
      - REDIS_MAXMEMORY_POLICY=allkeys-lru
      - REDIS_PASSWORD=secure_password
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "secure_password", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-ephemeral
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-ephemeral
  template:
    metadata:
      labels:
        app: redis-ephemeral
    spec:
      containers:
      - name: redis
        image: quay.io/insights-onprem/redis-ephemeral:6
        ports:
        - containerPort: 6379
        env:
        - name: REDIS_MAXMEMORY
          value: "512mb"
        livenessProbe:
          exec:
            command:
            - redis-cli
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
```

## Best Practices

### Image Management
- Use specific version tags for production
- Keep latest tag for development
- Regularly update base images
- Scan for security vulnerabilities

### Testing
- Always test after building
- Use automated testing in CI/CD
- Test with realistic data volumes
- Verify health checks work

This guide covers the essential usage patterns for the Insights On-Premise Dependencies project. For more detailed information, refer to the individual component documentation and the building-images.md guide.

