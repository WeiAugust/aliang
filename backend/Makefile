.PHONY: help dev build test lint migrate-up migrate-down clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Start backend in development mode
	@if [ ! -f .env ]; then cp .env.example .env; fi
	go run cmd/api/main.go

build: ## Build backend binary
	go build -ldflags="-s -w" -o bin/api cmd/api/main.go

test: ## Run tests with coverage
	go test -race -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out

test-verbose: ## Run tests with verbose output
	go test -v -race -coverprofile=coverage.out ./...

lint: ## Run linters
	go vet ./...
	go fmt ./...
	staticcheck ./...

migrate-up: ## Run database migrations
	go run cmd/migrate/main.go up

migrate-down: ## Rollback last migration
	go run cmd/migrate/main.go down

migrate-create: ## Create a new migration (usage: make migrate-create NAME=create_users_table)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make migrate-create NAME=create_users_table"; \
		exit 1; \
	fi
	migrate create -ext sql -dir migrations -seq $(NAME)

clean: ## Clean build artifacts
	rm -rf bin/ tmp/ coverage.out

deps: ## Download dependencies
	go mod download
	go mod tidy

docker-build: ## Build Docker image
	docker build -t aliang-backend:latest .

docker-run: ## Run Docker container
	docker run -p 8080:8080 --env-file .env aliang-backend:latest
