.PHONY: help dev test build clean migrate-up migrate-down lint docs

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Start all services in development mode
	docker-compose up -d
	@echo "Services started:"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - Redis: localhost:6379"
	@echo "  - MinIO: localhost:9000"
	@echo ""
	@echo "To start backend: cd backend && make dev"
	@echo "To start admin: cd admin && npm run dev"

test: ## Run all tests
	@echo "Running backend tests..."
	cd backend && go test -race -coverprofile=coverage.out ./...
	@echo ""
	@echo "Running admin panel tests..."
	cd admin && npm test

test-backend: ## Run backend tests only
	cd backend && go test -race -coverprofile=coverage.out ./...
	cd backend && go tool cover -func=coverage.out

test-admin: ## Run admin panel tests only
	cd admin && npm test -- --coverage

build: ## Build all Docker images
	docker-compose build

migrate-up: ## Run database migrations
	cd backend && go run cmd/migrate/main.go up

migrate-down: ## Rollback last migration
	cd backend && go run cmd/migrate/main.go down

lint: ## Run all linters
	@echo "Linting backend..."
	cd backend && go vet ./...
	cd backend && staticcheck ./...
	@echo ""
	@echo "Linting admin panel..."
	cd admin && npm run lint

clean: ## Stop all containers and clean build artifacts
	docker-compose down -v
	cd backend && rm -rf tmp/ dist/ coverage.out
	cd admin && rm -rf dist/ node_modules/.vite

docs: ## Serve API documentation locally
	@echo "Serving API documentation at http://localhost:8081"
	npx @redocly/cli preview-docs docs/api/openapi.yaml

release: ## Create a new release (usage: make release VERSION=1.0.0)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make release VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "Creating release $(VERSION)..."
	git tag -a v$(VERSION) -m "Release v$(VERSION)"
	git push origin v$(VERSION)
	@echo "Release v$(VERSION) created and pushed"
