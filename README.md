# Insights On-Premise Dependencies

This project provides Docker images and build instructions for all dependencies required by the Insights On-Premise platform. All images are built and hosted under the `quay.io/insights-onprem` organization.

## Overview

This project replaces external dependencies from `quay.io/cloudservices` with locally built and maintained images under `quay.io/insights-onprem`. This ensures:

- **Control**: Full control over image versions and security updates
- **Reliability**: No dependency on external image availability
- **Customization**: Ability to customize images for on-premise requirements
- **Security**: Better security posture with known image contents

## Images Provided

| Image | Original Source | Purpose |
|-------|----------------|---------|
| `quay.io/insights-onprem/redis-ephemeral:6` | `quay.io/cloudservices/redis-ephemeral:6` | Redis cache for applications |
| `quay.io/insights-onprem/insights-ingress:latest` | `quay.io/cloudservices/insights-ingress:latest` | Ingress service for file uploads |
| `quay.io/insights-onprem/sources-api-go:latest` | `quay.io/cloudservices/sources-api-go` | Sources API service |

## Directory Structure

```
insights-onprem-dependencies/
├── Makefile                         # Main build automation
├── README.md                        # This file
├── USAGE_GUIDE.md                   # Detailed usage instructions
├── redis-ephemeral/                 # Redis ephemeral image build
│   ├── Dockerfile
│   ├── README.md
│   ├── redis.conf
│   └── docker-entrypoint.sh
├── insights-ingress/                # Insights Ingress image build
│   ├── Dockerfile
│   ├── README.md
│   └── build.sh
└── sources-api-go/                  # Sources API Go image build
    ├── README.md
    └── build.sh
```

### Source Dependencies

This project builds from source repositories that must be cloned in the parent directory:

```
insights-onprem/
├── insights-ingress-go/             # Required: Source for insights-ingress
├── sources-api-go/                  # Required: Source for sources-api-go
└── insights-onprem-dependencies/    # This repository
```

## Quick Start

### Prerequisites

1. Ensure `insights-ingress-go` is cloned in the parent directory:
   ```
   insights-onprem/
   ├── insights-ingress-go/          # Clone this first
   └── insights-onprem-dependencies/ # This repository
   ```

2. Install Docker or Podman

3. Login to quay.io registry:
   ```bash
   # Set your registry credentials
   export REGISTRY_USER="your-username"
   export REGISTRY_PASSWORD="your-password"
   
   # Login to registry
   make login
   ```

### Building All Images

```bash
# Build all images locally
make build

# Build and push all images to quay.io/insights-onprem
make build-push

# Build with custom version
VERSION=1.0.0 make build

# Build using Podman instead of Docker
CONTAINER_CMD=podman make build

# Push all images to registry
make push

# Test all images
make test
```

### Building Individual Images

```bash
# Build Redis ephemeral image
make build-redis

# Build Insights Ingress image
make build-ingress
# Or use the build script directly
cd insights-ingress && ./build.sh

# Build Sources API Go image
make build-sources-api-go
# Or use the build script directly
cd sources-api-go && ./build.sh
```

## Image Details

### Redis Ephemeral

- **Base Image**: `redis:6-alpine`
- **Features**: Ephemeral storage, optimized configuration
- **Ports**: 6379
- **Volume**: None (ephemeral)

### Insights Ingress

- **Base Image**: Built from insights-ingress-go source
- **Features**: File upload handling, Kafka integration
- **Ports**: 3000 (web), 8080 (metrics)

### Sources API Go

- **Base Image**: Built from sources-api-go source
- **Features**: Sources management API
- **Ports**: 8000

## Prerequisites

- **Container Runtime**: Docker or Podman (podman preferred)
- **Registry Access**: Access to quay.io/insights-onprem organization
- **Git**: For cloning source repositories
- **Source Repositories**: insights-ingress-go and sources-api-go cloned in parent directory

## Building Images

Use the Makefile for automated building:

```bash
# Build all images
make build

# Build specific images
make build-redis
make build-ingress  
make build-sources-api-go

# Get help
make help
```

Each image directory contains:
- `Dockerfile` or build script: Image build instructions
- `README.md`: Specific build and usage instructions
- Additional configuration files as needed

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test the images
5. Submit a pull request

## Security

All images are built with security best practices:
- Non-root user execution where possible
- Minimal base images
- Regular security updates
- Vulnerability scanning

## Support

For issues and questions:
1. Review individual image README files
2. Check the USAGE_GUIDE.md for detailed instructions
3. Open an issue in this repository

## License

This project is licensed under the same terms as the parent Insights On-Premise project.

