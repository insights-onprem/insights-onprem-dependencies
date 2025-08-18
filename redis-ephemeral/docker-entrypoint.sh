#!/bin/bash
# Redis Ephemeral Docker Entrypoint Script
# Handles initialization and configuration for ephemeral Redis instance

set -e

# Default values
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_MAXMEMORY=${REDIS_MAXMEMORY:-256mb}
REDIS_MAXMEMORY_POLICY=${REDIS_MAXMEMORY_POLICY:-allkeys-lru}
REDIS_PASSWORD=${REDIS_PASSWORD:-}
REDIS_DATABASES=${REDIS_DATABASES:-16}

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Function to check if Redis is running
redis_ready() {
    redis-cli -p "$REDIS_PORT" ping >/dev/null 2>&1
}

# Function to wait for Redis to be ready
wait_for_redis() {
    local timeout=30
    local count=0
    
    while ! redis_ready; do
        count=$((count + 1))
        if [ $count -gt $timeout ]; then
            log "ERROR: Redis failed to start within $timeout seconds"
            exit 1
        fi
        log "Waiting for Redis to be ready... ($count/$timeout)"
        sleep 1
    done
    
    log "Redis is ready!"
}

# Function to apply runtime configuration
apply_runtime_config() {
    log "Applying runtime configuration..."
    
    # Set maxmemory if specified
    if [ -n "$REDIS_MAXMEMORY" ]; then
        log "Setting maxmemory to $REDIS_MAXMEMORY"
        redis-cli -p "$REDIS_PORT" CONFIG SET maxmemory "$REDIS_MAXMEMORY" >/dev/null 2>&1 || true
    fi
    
    # Set maxmemory policy if specified
    if [ -n "$REDIS_MAXMEMORY_POLICY" ]; then
        log "Setting maxmemory-policy to $REDIS_MAXMEMORY_POLICY"
        redis-cli -p "$REDIS_PORT" CONFIG SET maxmemory-policy "$REDIS_MAXMEMORY_POLICY" >/dev/null 2>&1 || true
    fi
    
    # Set password if specified
    if [ -n "$REDIS_PASSWORD" ]; then
        log "Setting Redis password"
        redis-cli -p "$REDIS_PORT" CONFIG SET requirepass "$REDIS_PASSWORD" >/dev/null 2>&1 || true
    fi
    
    # Set number of databases if specified
    if [ -n "$REDIS_DATABASES" ] && [ "$REDIS_DATABASES" != "16" ]; then
        log "Setting databases to $REDIS_DATABASES (requires restart)"
        # This requires a restart, so we'll update the config file
        sed -i "s/databases 16/databases $REDIS_DATABASES/" /usr/local/etc/redis/redis.conf
    fi
}

# Function to display startup information
show_startup_info() {
    log "Starting Redis Ephemeral for Insights On-Premise"
    log "Configuration:"
    log "  Port: $REDIS_PORT"
    log "  Max Memory: $REDIS_MAXMEMORY"
    log "  Max Memory Policy: $REDIS_MAXMEMORY_POLICY"
    log "  Databases: $REDIS_DATABASES"
    log "  Password: $([ -n "$REDIS_PASSWORD" ] && echo "Set" || echo "Not set")"
    log "  Data Directory: /data (ephemeral)"
    log "  Config File: /usr/local/etc/redis/redis.conf"
}

# Function to handle shutdown
shutdown_handler() {
    log "Received shutdown signal, stopping Redis gracefully..."
    redis-cli -p "$REDIS_PORT" SHUTDOWN_EPHEMERAL NOSAVE >/dev/null 2>&1 || true
    exit 0
}

# Set up signal handlers
trap shutdown_handler SIGTERM SIGINT

# Main execution
main() {
    show_startup_info
    
    # Check if we're running as the redis user
    if [ "$(id -u)" = "0" ]; then
        log "WARNING: Running as root. Consider running as redis user for better security."
    fi
    
    # Ensure data directory exists and has proper permissions
    if [ ! -d "/data" ]; then
        mkdir -p /data
    fi
    
    # If no arguments provided, start Redis with default config
    if [ $# -eq 0 ]; then
        log "Starting Redis server with configuration file..."
        exec redis-server /usr/local/etc/redis/redis.conf &
        REDIS_PID=$!
        
        # Wait a moment for Redis to start
        sleep 2
        
        # Apply runtime configuration
        if redis_ready; then
            apply_runtime_config
        fi
        
        # Wait for Redis process
        wait $REDIS_PID
        
    # If redis-server is the first argument, handle it specially
    elif [ "$1" = "redis-server" ]; then
        log "Starting Redis server with provided arguments..."
        exec "$@" &
        REDIS_PID=$!
        
        # Wait a moment for Redis to start
        sleep 2
        
        # Apply runtime configuration if using default config
        if [ "$2" = "/usr/local/etc/redis/redis.conf" ] && redis_ready; then
            apply_runtime_config
        fi
        
        # Wait for Redis process
        wait $REDIS_PID
        
    # If redis-cli is the first argument, just execute it
    elif [ "$1" = "redis-cli" ]; then
        exec "$@"
        
    # For any other command, just execute it
    else
        log "Executing custom command: $*"
        exec "$@"
    fi
}

# Execute main function
main "$@"

