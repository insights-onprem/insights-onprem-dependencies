# Sources API Go Build

This directory contains the build configuration for the Sources API Go service, which provides REST API endpoints for managing sources and their configurations in the Insights On-Premise platform.

## Overview

The Sources API Go service is built from the [insights-onprem/sources-api-go](https://github.com/insights-onprem/sources-api-go) repository and packaged as a container image for deployment in the on-premise environment.

**Built Image**: `quay.io/insights-onprem/sources-api-go:latest`

## Prerequisites

### Source Code Setup

The sources-api-go source repository must be cloned as a sibling directory to this project:

```bash
# Expected directory structure:
insights-onprem/
├── sources-api-go/                  # Source repository (required)
└── insights-onprem-dependencies/    # This repository
    └── sources-api-go/              # This directory
        ├── README.md                # This file
        └── build.sh                 # Build script
```

### Clone the Source Repository

```bash
cd /path/to/insights-onprem
git clone git@github.com:insights-onprem/sources-api-go.git
```

### Configure Git Remotes

For development, configure the source repository with your fork:

```bash
cd sources-api-go
git remote set-url origin git@github.com:masayag/sources-api-go.git
git remote add upstream git@github.com:insights-onprem/sources-api-go.git
```

Verify the remote configuration:
```bash
git remote -v
# Should show:
# origin    git@github.com:masayag/sources-api-go.git (fetch/push)
# upstream  git@github.com:insights-onprem/sources-api-go.git (fetch/push)
```

## Building

### Using the Build Script (Recommended)

The build script automatically detects and prefers podman over docker:

```bash
# Build the image
./build.sh

# Build and push to registry
./build.sh push

# Build with custom version
VERSION=v1.0.0 ./build.sh

# Build with custom registry
REGISTRY=my-registry.com/my-org ./build.sh
```

### Using Make (from project root)

```bash
# From insights-onprem-dependencies/ root directory
make build-sources-api-go

# Or build all images
make build
```

### Manual Build

```bash
# Using podman (preferred)
podman build --platform=linux/amd64 -t quay.io/insights-onprem/sources-api-go:latest ../../sources-api-go

# Using docker
docker build --platform=linux/amd64 -t quay.io/insights-onprem/sources-api-go:latest ../../sources-api-go
```

## macOS Cross-Platform Building

The build script is optimized for macOS development with automatic amd64 architecture targeting:

- **Platform**: `linux/amd64` (configurable via `PLATFORM` environment variable)
- **Container Runtime**: Prefers `podman` over `docker`
- **Cross-compilation**: Handles Apple Silicon → x86_64 Linux builds

### macOS Build Example

```bash
# Default build (automatically sets linux/amd64)
./build.sh

# Explicit platform specification
PLATFORM=linux/amd64 ./build.sh

# Build with podman on macOS
CONTAINER_CMD=podman ./build.sh
```

## Configuration

### Environment Variables

The build script supports the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `REGISTRY` | `quay.io/insights-onprem` | Target registry |
| `VERSION` | `latest` | Image version tag |
| `CONTAINER_CMD` | auto-detected | Container runtime (`podman` preferred) |
| `PLATFORM` | `linux/amd64` | Target platform architecture |
| `PUSH` | `false` | Auto-push after build |

### Runtime Environment Variables

The Sources API Go service requires these environment variables when running:

#### Core Configuration
- `SOURCES_ENV=prod` - Sets production mode (required for encryption)
- `ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ` - Base64 encoded encryption key

#### Database Configuration
- `DATABASE_HOST` - PostgreSQL hostname
- `DATABASE_PORT=5432` - PostgreSQL port
- `DATABASE_USER=postgres` - Database username
- `DATABASE_PASSWORD` - Database password
- `DATABASE_NAME=sources_api_development` - Database name

#### Cache Configuration
- `REDIS_CACHE_HOST` - Redis hostname
- `REDIS_CACHE_PORT=6379` - Redis port

#### Message Queue Configuration
- `QUEUE_HOST` - Kafka hostname
- `QUEUE_PORT=29092` - Kafka port

#### Optional Configuration
- `LOG_LEVEL=DEBUG` - Logging verbosity
- `BYPASS_RBAC=true` - Bypass RBAC (development only)

## Docker Compose Integration

### Override Configuration

This project includes `docker-compose.override.yml` in the root directory for seamless integration with ros-ocp-backend:

```yaml
services:
  sources-api-go:
    image: quay.io/insights-onprem/sources-api-go:latest
    environment:
      - ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ
      - SOURCES_ENV=prod

  sources-db-setup:
    image: quay.io/insights-onprem/sources-api-go:latest
    environment:
      - ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ
      - SOURCES_ENV=prod
```

### Usage with ros-ocp-backend

1. **Copy the override file**:
   ```bash
   cp ../docker-compose.override.yml /path/to/ros-ocp-backend/scripts/
   ```

2. **Start services**:
   ```bash
   cd /path/to/ros-ocp-backend/scripts/
   podman-compose up -d
   ```

The override automatically replaces `quay.io/cloudservices/sources-api-go` with the locally built `quay.io/insights-onprem/sources-api-go:latest`.

## Image Details

### Multi-Stage Build
- **Build Stage**: `registry.access.redhat.com/ubi9/ubi:latest` with Go compiler
- **Runtime Stage**: `registry.access.redhat.com/ubi9/ubi-minimal:latest` (minimal footprint)

### Image Contents
```
/app/
├── sources-api-go       # Main application binary (stripped)
├── encryption_key.dev   # Fallback encryption key file
└── licenses/
    └── LICENSE          # License information
```

### Image Properties
- **Size**: ~147 MB (optimized)
- **User**: Non-root (UID 1001)
- **Ports**: 8000 (API), 9394 (metrics)
- **Architecture**: linux/amd64

## Development and Testing

### Local Development

For local development without containers:

```bash
cd ../../sources-api-go
go mod download
go run . --help
```

### Container Testing

Test the built image:

```bash
# Basic functionality test
podman run --rm quay.io/insights-onprem/sources-api-go:latest --help

# Test with minimal environment
podman run --rm \
  -e SOURCES_ENV=prod \
  -e ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ \
  quay.io/insights-onprem/sources-api-go:latest --help

# Integration test (requires running dependencies)
podman run --rm \
  -e SOURCES_ENV=prod \
  -e ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ \
  -e DATABASE_HOST=localhost \
  -e DATABASE_USER=postgres \
  -e DATABASE_PASSWORD=postgres \
  -p 8080:8000 \
  quay.io/insights-onprem/sources-api-go:latest
```

## Registry Operations

### Push to Registry

```bash
# Push latest
./build.sh push

# Push specific version
VERSION=v1.0.0 ./build.sh push

# Manual push
podman push quay.io/insights-onprem/sources-api-go:latest
```

### Registry Authentication

Ensure you're logged into the registry:

```bash
# Login to quay.io
podman login quay.io

# Or use credentials
echo $REGISTRY_PASSWORD | podman login -u $REGISTRY_USER --password-stdin quay.io
```

## Troubleshooting

### Common Build Issues

#### Source Repository Missing
```
ERROR: sources-api-go source not found at: ../../sources-api-go
```
**Solution**: Clone the sources-api-go repository in the parent directory.

#### Container Runtime Not Found
```
ERROR: No container runtime found. Please install podman or docker.
```
**Solution**: Install podman or docker:
```bash
# macOS with Homebrew
brew install podman

# Start podman machine on macOS
podman machine init
podman machine start
```

#### Platform Build Issues
```
WARNING: image platform (linux/amd64) does not match the expected platform
```
**Solution**: This warning is expected when building on Apple Silicon for x86_64. The build will work correctly.

### Common Runtime Issues

#### Encryption Key Errors
```
panic: encryption_key.dev file does not exist
```
**Solution**: Ensure both environment variables are set:
```bash
SOURCES_ENV=prod ENCRYPTION_KEY=YWFhYWFhYWFhYWFhYWFhYQ
```

#### Database Connection Errors
```
failed to connect to database: hostname resolving error
```
**Solution**: Verify database service is running and accessible.

### Validation

Verify your setup:

```bash
# Check source repository
ls -la ../../sources-api-go/

# Check required files
ls -la ../../sources-api-go/{go.mod,main.go,Dockerfile}

# Test build
./build.sh

# Verify image
podman images | grep sources-api-go
```

## Related Documentation

- [Main Project README](../README.md) - Overall project documentation  
- [Usage Guide](../USAGE_GUIDE.md) - Detailed usage instructions
- [Insights Ingress](../insights-ingress/README.md) - Ingress service build
- [Redis Ephemeral](../redis-ephemeral/README.md) - Redis service build
- [Sources API Go Repository](https://github.com/insights-onprem/sources-api-go) - Source code