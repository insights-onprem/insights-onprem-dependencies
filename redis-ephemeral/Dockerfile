# Redis Ephemeral Image for Insights On-Premise
# Based on Redis 6 with ephemeral storage configuration

FROM redis:6-alpine

# Metadata
LABEL maintainer="Insights On-Premise Team"
LABEL description="Redis ephemeral instance for Insights On-Premise platform"
LABEL version="6"
LABEL source="https://github.com/insights-onprem/insights-onprem-dependencies"

# Install additional packages if needed
RUN apk add --no-cache \
    bash \
    curl \
    && rm -rf /var/cache/apk/*

# Create redis user and group (already exists in base image, but ensuring consistency)
USER root

# Create necessary directories
RUN mkdir -p /usr/local/etc/redis \
    && chown redis:redis /usr/local/etc/redis

# Copy Redis configuration
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make entrypoint executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set proper ownership
RUN chown redis:redis /usr/local/etc/redis/redis.conf \
    && chown redis:redis /usr/local/bin/docker-entrypoint.sh

# Switch to redis user for security
USER redis

# Expose Redis port
EXPOSE 6379

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD redis-cli ping || exit 1

# Volume for ephemeral data (will be lost when container stops)
VOLUME ["/data"]

# Set working directory
WORKDIR /data

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

