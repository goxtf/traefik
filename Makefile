# Traefik Makefile
# Provides common development tasks for building, testing, and linting

.PHONY: all build test lint fmt clean docker-build help

# Go parameters
GOCMD     := go
GOBUILD   := $(GOCMD) build
GOTEST    := $(GOCMD) test
GOFMT     := gofmt
GOVET     := $(GOCMD) vet
GOLINT    := golangci-lint

# Build parameters
BINARY_NAME := traefik
BIN_DIR     := dist
MAIN_PKG    := ./cmd/traefik

# Version info injected at build time
VERSION     ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "dev")
COMMIT      ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE        ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LD_FLAGS := -ldflags "-s -w \
  -X github.com/traefik/traefik/v3/pkg/version.Version=$(VERSION) \
  -X github.com/traefik/traefik/v3/pkg/version.Commit=$(COMMIT) \
  -X github.com/traefik/traefik/v3/pkg/version.Date=$(DATE)"

# Docker parameters
DOCKER_IMAGE := traefik
DOCKER_TAG   ?= latest

## all: Build the binary (default target)
all: build

## build: Compile the traefik binary into dist/
build:
	@echo ">>> Building $(BINARY_NAME) $(VERSION) ($(COMMIT))"
	@mkdir -p $(BIN_DIR)
	$(GOBUILD) $(LD_FLAGS) -o $(BIN_DIR)/$(BINARY_NAME) $(MAIN_PKG)

## test: Run unit tests with race detection
test:
	@echo ">>> Running tests"
	$(GOTEST) -race -cover ./...

## test-integration: Run integration tests (requires Docker)
test-integration:
	@echo ">>> Running integration tests"
	$(GOTEST) -tags integration -timeout 10m ./integration/...

## lint: Run golangci-lint
lint:
	@echo ">>> Linting"
	$(GOLINT) run ./...

## fmt: Format Go source files
fmt:
	@echo ">>> Formatting"
	$(GOFMT) -s -w $(shell find . -name '*.go' -not -path './vendor/*')

## vet: Run go vet
vet:
	$(GOVET) ./...

## clean: Remove build artifacts
clean:
	@echo ">>> Cleaning"
	@rm -rf $(BIN_DIR)

## docker-build: Build the Docker image
docker-build:
	@echo ">>> Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)"
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

## generate: Run go generate
generate:
	$(GOCMD) generate ./...

## tidy: Tidy go modules
tidy:
	$(GOCMD) mod tidy

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'
