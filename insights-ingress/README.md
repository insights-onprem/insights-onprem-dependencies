# Insights Ingress - On-Premise Build

This directory contains the Docker build configuration for the Insights Ingress service, built from the `insights-ingress-go` source code for on-premise deployments.

## Overview

This builds the Insights Ingress service from source using the `insights-ingress-go` codebase, creating a container image suitable for on-premise deployments under the `quay.io/insights-onprem` organization.

## Prerequisites

1. **Source Code**: The `insights-ingress-go` repository must be cloned in the parent directory:
   ```
   insights-onprem/
   ├── insights-ingress-go/          # Required source code
   └── insights-onprem-dependencies/ # This repository
   ```

2. **Container Runtime**: Docker or Podman installed and running

3. **Registry Access**: Authentication to `quay.io/insights-onprem` registry

## Building the Image

### Using Makefile (Recommended)

From the `insights-onprem-dependencies` root directory:

```bash
# Build the insights-ingress image
make build-ingress

# Build and push to registry
make push-ingress

# Build with custom version
VERSION=1.2.0 make build-ingress
```

### Using Build Script

```bash
# Build only
./insights-ingress/build.sh

# Build and push
./insights-ingress/build.sh push

# Or set environment variable
PUSH=true ./insights-ingress/build.sh
```

### Manual Docker Build

```bash
# From insights-onprem-dependencies directory
docker build -t quay.io/insights-onprem/insights-ingress:latest \
  -f insights-ingress/Dockerfile \
  ../insights-ingress-go
```

## Configuration Options

### Environment Variables

- `REGISTRY`: Target registry (default: `quay.io/insights-onprem`)
- `VERSION`: Image version tag (default: `latest`)
- `CONTAINER_CMD`: Container command to use (default: `docker`)
- `PUSH`: Set to `true` to automatically push after build

### Examples

```bash
# Build with custom registry
REGISTRY=my-registry.com/insights make build-ingress

# Build with Podman
CONTAINER_CMD=podman make build-ingress

# Build specific version and push
VERSION=1.2.0 PUSH=true ./insights-ingress/build.sh
```

## Image Details

### Base Images
- **Builder Stage**: `registry.access.redhat.com/ubi9/go-toolset:latest`
- **Runtime Stage**: `registry.access.redhat.com/ubi9/ubi-minimal:latest`

### Go Version
- Uses Go 1.24.4 with auto-upgrade capability
- Specified via `GOTOOLCHAIN=go1.24.4+auto`

### Security
- Runs as non-root user (UID 1001)
- Minimal runtime image for reduced attack surface
- Only includes necessary runtime dependencies

### Ports
- Exposes port 3000 (default ingress service port)

## Testing the Image

### Quick Test
```bash
# Test if the binary works
docker run --rm quay.io/insights-onprem/insights-ingress:latest /insights-ingress-go --help
```

### Integration Test
```bash
# Run with dependencies (requires kafka, minio, etc.)
docker run --rm -p 3000:3000 \
  -e INGRESS_KAFKA_BROKERS=localhost:9092 \
  -e INGRESS_MINIOENDPOINT=localhost:9000 \
  quay.io/insights-onprem/insights-ingress:latest
```

### Using Makefile Test
```bash
make test-ingress
```

## Troubleshooting

### Common Issues

1. **Source Not Found**
   ```
   ERROR: insights-ingress-go source not found
   ```
   - Ensure `insights-ingress-go` is cloned in the parent directory
   - Check the directory structure matches the expected layout

2. **Build Failures**
   ```
   go: cannot find main module
   ```
   - Verify `go.mod` and `go.sum` exist in insights-ingress-go
   - Ensure the build context is correct

3. **Push Failures**
   ```
   unauthorized: authentication required
   ```
   - Login to the registry: `make login`
   - Verify REGISTRY_USER and REGISTRY_PASSWORD are set

### Debug Build

```bash
# Enable verbose output
CONTAINER_CMD="docker build --progress=plain" make build-ingress

# Check build context
docker build --dry-run -f insights-ingress/Dockerfile ../insights-ingress-go
```

## Integration

### Docker Compose

The built image is designed to work with the provided `docker-compose.override.yml`:

```yaml
services:
  ingress:
    image: quay.io/insights-onprem/insights-ingress:latest
```

### Kubernetes/OpenShift

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insights-ingress
spec:
  template:
    spec:
      containers:
      - name: insights-ingress
        image: quay.io/insights-onprem/insights-ingress:latest
        ports:
        - containerPort: 3000
```

## Development

### Local Development

For local development of the ingress service, refer to the `insights-ingress-go` repository documentation for running from source with development dependencies.

### Contributing

1. Make changes to the Dockerfile or build scripts
2. Test the build process: `make build-ingress`
3. Test the resulting image functionality
4. Update documentation as needed
