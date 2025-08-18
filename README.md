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
├── README.md
├── docker-compose.override.yml      # Override for ros-ocp-backend
├── redis-ephemeral/
│   ├── Dockerfile
│   ├── README.md
│   ├── redis.conf
│   └── docker-entrypoint.sh
├── insights-ingress/
│   ├── Dockerfile
│   ├── README.md
│   └── build.sh
├── sources-api-go/
│   ├── Dockerfile
│   ├── README.md
│   └── build.sh
├── scripts/
│   ├── build-all.sh
│   ├── push-all.sh
│   └── test-images.sh
└── docs/
    ├── building-images.md
    ├── deployment-guide.md
    └── troubleshooting.md
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
./scripts/push-all.sh

# Test all images
./scripts/test-images.sh
```

### Building Individual Images

```bash
# Build Redis ephemeral image
cd redis-ephemeral
docker build -t quay.io/insights-onprem/redis-ephemeral:6 .

# Build Insights Ingress image
cd insights-ingress
./build.sh

# Build Sources API Go image
cd sources-api-go
./build.sh
```

## Usage with ROS OCP Backend

To use these images with the ros-ocp-backend project, copy the `docker-compose.override.yml` file to the ros-ocp-backend/scripts directory:

```bash
cp docker-compose.override.yml /path/to/ros-ocp-backend/scripts/
cd /path/to/ros-ocp-backend/scripts/
docker-compose up
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

- Docker or Podman
- Access to quay.io/insights-onprem organization
- Git (for cloning source repositories)

## Building Images

Each image directory contains:
- `Dockerfile`: Image build instructions
- `README.md`: Specific build and usage instructions
- Additional configuration files as needed

See individual image directories for detailed build instructions.

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
1. Check the troubleshooting guide in `docs/troubleshooting.md`
2. Review individual image README files
3. Open an issue in this repository

## License

This project is licensed under the same terms as the parent Insights On-Premise project.

