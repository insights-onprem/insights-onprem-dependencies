# Makefile for Insights On-Premise Dependencies
# Builds and pushes Docker images to quay.io/insights-onprem

# Configuration
REGISTRY ?= quay.io/insights-onprem
VERSION ?= latest
CONTAINER_CMD ?= docker

# Image names
REDIS_IMAGE = $(REGISTRY)/redis-ephemeral:6
INGRESS_IMAGE = $(REGISTRY)/insights-ingress:$(VERSION)
SOURCES_IMAGE = $(REGISTRY)/sources-api-go:$(VERSION)

# Build context paths
INSIGHTS_INGRESS_GO_PATH = ../insights-ingress-go
SOURCES_API_GO_PATH = ../sources-api-go
REDIS_PATH = ./redis-ephemeral
INGRESS_PATH = ./insights-ingress

# Default target
.PHONY: all
all: build

# Build all images
.PHONY: build
build: build-redis build-ingress build-sources-api-go
	@echo "All images built successfully"

# Build individual images
.PHONY: build-redis
build-redis:
	@echo "Building Redis ephemeral image..."
	$(CONTAINER_CMD) build -t $(REDIS_IMAGE) $(REDIS_PATH)
	@echo "Redis image built: $(REDIS_IMAGE)"

.PHONY: build-ingress
build-ingress:
	@echo "Building Insights Ingress image from insights-ingress-go source..."
	@if [ ! -d "$(INSIGHTS_INGRESS_GO_PATH)" ]; then \
		echo "ERROR: insights-ingress-go source not found at $(INSIGHTS_INGRESS_GO_PATH)"; \
		echo "Please ensure insights-ingress-go is cloned in the parent directory"; \
		exit 1; \
	fi
	$(CONTAINER_CMD) build -t $(INGRESS_IMAGE) -f $(INGRESS_PATH)/Dockerfile $(INSIGHTS_INGRESS_GO_PATH)
	@echo "Insights Ingress image built: $(INGRESS_IMAGE)"

.PHONY: build-sources-api-go
build-sources-api-go:
	@echo "Building Sources API Go image from sources-api-go source..."
	@if [ ! -d "$(SOURCES_API_GO_PATH)" ]; then \
		echo "ERROR: sources-api-go source not found at $(SOURCES_API_GO_PATH)"; \
		echo "Please ensure sources-api-go is cloned in the parent directory"; \
		exit 1; \
	fi
	$(CONTAINER_CMD) build -t $(SOURCES_IMAGE) $(SOURCES_API_GO_PATH)
	@echo "Sources API Go image built: $(SOURCES_IMAGE)"

.PHONY: build-sources-api-go-script
build-sources-api-go-script:
	@echo "Building Sources API Go image using build script..."
	cd sources-api-go && CONTAINER_CMD=$(CONTAINER_CMD) REGISTRY=$(REGISTRY) VERSION=$(VERSION) ./build.sh

# Push all images
.PHONY: push
push: push-redis push-ingress push-sources-api-go
	@echo "All images pushed successfully"

.PHONY: push-redis
push-redis:
	@echo "Pushing Redis ephemeral image..."
	$(CONTAINER_CMD) push $(REDIS_IMAGE)
	@echo "Redis image pushed: $(REDIS_IMAGE)"

.PHONY: push-ingress
push-ingress:
	@echo "Pushing Insights Ingress image..."
	$(CONTAINER_CMD) push $(INGRESS_IMAGE)
	@echo "Insights Ingress image pushed: $(INGRESS_IMAGE)"

.PHONY: push-sources-api-go
push-sources-api-go:
	@echo "Pushing Sources API Go image..."
	$(CONTAINER_CMD) push $(SOURCES_IMAGE)
	@echo "Sources API Go image pushed: $(SOURCES_IMAGE)"

# Build and push in one command
.PHONY: build-push
build-push: build push

# Test images locally
.PHONY: test
test: test-redis test-ingress test-sources-api-go

.PHONY: test-redis
test-redis:
	@echo "Testing Redis image..."
	$(CONTAINER_CMD) run --rm -d --name test-redis $(REDIS_IMAGE) > /dev/null
	@sleep 5
	@if $(CONTAINER_CMD) exec test-redis redis-cli ping | grep -q PONG; then \
		echo "✓ Redis test passed"; \
	else \
		echo "✗ Redis test failed"; \
		exit 1; \
	fi
	@$(CONTAINER_CMD) stop test-redis > /dev/null

.PHONY: test-ingress
test-ingress:
	@echo "Testing Insights Ingress image..."
	$(CONTAINER_CMD) run --rm -d --name test-ingress -p 3001:3000 $(INGRESS_IMAGE) > /dev/null
	@sleep 10
	@if curl -f http://localhost:3001/api/ingress/v1/version > /dev/null 2>&1; then \
		echo "✓ Insights Ingress test passed"; \
	else \
		echo "✗ Insights Ingress test failed (this may be expected if dependencies are not running)"; \
	fi
	@$(CONTAINER_CMD) stop test-ingress > /dev/null

.PHONY: test-sources-api-go
test-sources-api-go:
	@echo "Testing Sources API Go image..."
	$(CONTAINER_CMD) run --rm -d --name test-sources-api-go -p 8080:8080 $(SOURCES_IMAGE) > /dev/null
	@sleep 10
	@if curl -f http://localhost:8080/api/sources/v1.0/openapi.json > /dev/null 2>&1; then \
		echo "✓ Sources API Go test passed"; \
	else \
		echo "✗ Sources API Go test failed (this may be expected if dependencies are not running)"; \
	fi
	@$(CONTAINER_CMD) stop test-sources-api-go > /dev/null

# Clean up local images
.PHONY: clean
clean:
	@echo "Cleaning up local images..."
	-$(CONTAINER_CMD) rmi $(REDIS_IMAGE) 2>/dev/null || true
	-$(CONTAINER_CMD) rmi $(INGRESS_IMAGE) 2>/dev/null || true
	-$(CONTAINER_CMD) rmi $(SOURCES_IMAGE) 2>/dev/null || true
	@echo "Local images cleaned"

# Login to registry
.PHONY: login
login:
	@echo "Logging into $(REGISTRY)..."
	@if [ -z "$(REGISTRY_USER)" ] || [ -z "$(REGISTRY_PASSWORD)" ]; then \
		echo "ERROR: REGISTRY_USER and REGISTRY_PASSWORD environment variables must be set"; \
		echo "Usage: REGISTRY_USER=username REGISTRY_PASSWORD=password make login"; \
		exit 1; \
	fi
	@echo "$(REGISTRY_PASSWORD)" | $(CONTAINER_CMD) login $(REGISTRY) -u "$(REGISTRY_USER)" --password-stdin
	@echo "Successfully logged into $(REGISTRY)"

# Show help
.PHONY: help
help:
	@echo "Insights On-Premise Dependencies Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build                 - Build all images"
	@echo "  build-redis           - Build Redis ephemeral image"
	@echo "  build-ingress         - Build Insights Ingress image"
	@echo "  build-sources-api-go  - Build Sources API Go image"
	@echo "  build-sources-api-go-script - Build Sources API Go using build script"
	@echo "  push                  - Push all images to registry"
	@echo "  push-redis            - Push Redis image to registry"
	@echo "  push-ingress          - Push Insights Ingress image to registry"
	@echo "  push-sources-api-go   - Push Sources API Go image to registry"
	@echo "  build-push            - Build and push all images"
	@echo "  test                  - Test all images"
	@echo "  test-redis            - Test Redis image"
	@echo "  test-ingress          - Test Insights Ingress image"
	@echo "  test-sources-api-go   - Test Sources API Go image"
	@echo "  clean                 - Remove local images"
	@echo "  login                 - Login to registry"
	@echo "  help                  - Show this help"
	@echo ""
	@echo "Configuration:"
	@echo "  REGISTRY       - Registry to push to (default: quay.io/insights-onprem)"
	@echo "  VERSION        - Image version tag (default: latest)"
	@echo "  CONTAINER_CMD  - Container command (default: docker)"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  REGISTRY_USER=myuser REGISTRY_PASSWORD=mypass make login"
	@echo "  VERSION=1.0.0 make build-push"
	@echo "  CONTAINER_CMD=podman make build"
