# Redis Ephemeral Image

This directory contains the Dockerfile and configuration for building the Redis ephemeral image used by the Insights On-Premise platform.

## Overview

The Redis ephemeral image provides a Redis 6 instance configured for ephemeral storage, meaning data is not persisted between container restarts. This is ideal for development, testing, and caching scenarios where data persistence is not required.

## Features

- **Redis 6**: Latest stable Redis 6 with Alpine Linux base
- **Ephemeral Storage**: No data persistence (data lost on container restart)
- **Security Hardened**: Dangerous commands disabled, non-root execution
- **Optimized Configuration**: Memory management and performance tuning
- **Health Checks**: Built-in health check endpoint
- **Configurable**: Runtime configuration via environment variables

## Building the Image

### Prerequisites

- Docker or Podman
- Access to Docker Hub (for base image)

### Build Command

```bash
# Build the image
docker build -t quay.io/insights-onprem/redis-ephemeral:6 .

# Build with specific tag
docker build -t quay.io/insights-onprem/redis-ephemeral:6.2.7 .

# Build and push
docker build -t quay.io/insights-onprem/redis-ephemeral:6 .
docker push quay.io/insights-onprem/redis-ephemeral:6
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_PORT` | `6379` | Redis server port |
| `REDIS_MAXMEMORY` | `256mb` | Maximum memory usage |
| `REDIS_MAXMEMORY_POLICY` | `allkeys-lru` | Memory eviction policy |
| `REDIS_PASSWORD` | _(none)_ | Redis authentication password |
| `REDIS_DATABASES` | `16` | Number of databases |

### Memory Policies

Available memory eviction policies:
- `allkeys-lru`: Remove any key according to LRU algorithm
- `allkeys-lfu`: Remove any key according to LFU algorithm
- `volatile-lru`: Remove keys with expire set according to LRU
- `volatile-lfu`: Remove keys with expire set according to LFU
- `allkeys-random`: Remove random keys
- `volatile-random`: Remove random keys with expire set
- `volatile-ttl`: Remove keys with expire set and shorter TTL
- `noeviction`: Don't evict anything, return errors on write

## Usage

### Basic Usage

```bash
# Run with default configuration
docker run -d \
  --name redis-ephemeral \
  -p 6379:6379 \
  quay.io/insights-onprem/redis-ephemeral:6

# Run with custom memory limit
docker run -d \
  --name redis-ephemeral \
  -p 6379:6379 \
  -e REDIS_MAXMEMORY=512mb \
  quay.io/insights-onprem/redis-ephemeral:6

# Run with password authentication
docker run -d \
  --name redis-ephemeral \
  -p 6379:6379 \
  -e REDIS_PASSWORD=mypassword \
  quay.io/insights-onprem/redis-ephemeral:6
```

### Docker Compose

```yaml
services:
  redis:
    image: quay.io/insights-onprem/redis-ephemeral:6
    ports:
      - "6379:6379"
    environment:
      - REDIS_MAXMEMORY=512mb
      - REDIS_MAXMEMORY_POLICY=allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 5s
```

### With Authentication

```yaml
services:
  redis:
    image: quay.io/insights-onprem/redis-ephemeral:6
    ports:
      - "6379:6379"
    environment:
      - REDIS_PASSWORD=secure_password
      - REDIS_MAXMEMORY=1gb
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "secure_password", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3
```

## Testing the Image

### Basic Functionality Test

```bash
# Start the container
docker run -d --name test-redis -p 6379:6379 quay.io/insights-onprem/redis-ephemeral:6

# Test Redis connectivity
redis-cli ping
# Expected output: PONG

# Test basic operations
redis-cli set test_key "hello world"
redis-cli get test_key
# Expected output: "hello world"

# Test health check
docker exec test-redis redis-cli ping
# Expected output: PONG

# Clean up
docker stop test-redis
docker rm test-redis
```

### Performance Test

```bash
# Start container with higher memory limit
docker run -d --name perf-redis -p 6379:6379 \
  -e REDIS_MAXMEMORY=1gb \
  quay.io/insights-onprem/redis-ephemeral:6

# Run Redis benchmark
redis-benchmark -h localhost -p 6379 -t set,get -n 10000 -q

# Clean up
docker stop perf-redis
docker rm perf-redis
```

## Security Considerations

### Disabled Commands

The following Redis commands are disabled for security:
- `FLUSHDB`: Renamed to empty string (disabled)
- `FLUSHALL`: Renamed to empty string (disabled)
- `CONFIG`: Renamed to empty string (disabled)
- `DEBUG`: Renamed to empty string (disabled)
- `EVAL`: Renamed to empty string (disabled)
- `SHUTDOWN`: Renamed to `SHUTDOWN_EPHEMERAL`

### Network Security

- Redis binds to all interfaces (`0.0.0.0`) for container networking
- Use Docker network isolation in production
- Consider using authentication (`REDIS_PASSWORD`) for additional security

### File System Security

- Container runs as `redis` user (non-root)
- Data directory `/data` is owned by `redis` user
- Configuration files have restricted permissions

## Troubleshooting

### Common Issues

1. **Container fails to start**
   ```bash
   # Check logs
   docker logs redis-ephemeral
   
   # Check if port is already in use
   netstat -tlnp | grep 6379
   ```

2. **Connection refused**
   ```bash
   # Verify container is running
   docker ps | grep redis-ephemeral
   
   # Check if Redis is ready
   docker exec redis-ephemeral redis-cli ping
   ```

3. **Memory issues**
   ```bash
   # Check Redis memory usage
   docker exec redis-ephemeral redis-cli info memory
   
   # Adjust REDIS_MAXMEMORY environment variable
   ```

4. **Performance issues**
   ```bash
   # Check Redis stats
   docker exec redis-ephemeral redis-cli info stats
   
   # Monitor slow queries
   docker exec redis-ephemeral redis-cli slowlog get 10
   ```

### Debugging

```bash
# Access Redis CLI
docker exec -it redis-ephemeral redis-cli

# View configuration
docker exec redis-ephemeral redis-cli config get "*"

# Monitor Redis commands
docker exec redis-ephemeral redis-cli monitor

# Check Redis info
docker exec redis-ephemeral redis-cli info
```

## Files

- `Dockerfile`: Multi-stage build configuration
- `redis.conf`: Redis server configuration optimized for ephemeral usage
- `docker-entrypoint.sh`: Custom entrypoint script with runtime configuration
- `README.md`: This documentation file

## Contributing

1. Make changes to the configuration or Dockerfile
2. Test the changes locally
3. Update documentation as needed
4. Submit a pull request

## Support

For issues specific to this image:
1. Check the troubleshooting section above
2. Review Redis logs: `docker logs <container_name>`
3. Open an issue in the insights-onprem-dependencies repository
