#!/bin/bash

# Quick Start Script for Aliang Project
# This script helps you get started with the project

set -e

echo "=========================================="
echo "🚀 Aliang Project Quick Start"
echo "=========================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "   Install: https://docs.docker.com/get-docker/"
    exit 1
fi
echo "✅ Docker installed: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed"
    echo "   Install: https://docs.docker.com/compose/install/"
    exit 1
fi
echo "✅ Docker Compose installed: $(docker-compose --version)"

# Check Go
if ! command -v go &> /dev/null; then
    echo "⚠️  Go is not installed"
    echo "   Install: brew install go"
    echo "   Or visit: https://golang.org/doc/install"
    echo ""
    echo "   You can still start the infrastructure services,"
    echo "   but you won't be able to run the backend API."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Go installed: $(go version)"
fi

echo ""
echo "=========================================="
echo "🐳 Starting Infrastructure Services"
echo "=========================================="
echo ""

# Start Docker services
echo "Starting PostgreSQL, Redis, and MinIO..."
docker-compose up -d

echo ""
echo "Waiting for services to be healthy..."
sleep 5

# Check service health
echo ""
echo "Checking service health..."
docker-compose ps

echo ""
echo "=========================================="
echo "✅ Infrastructure Services Started"
echo "=========================================="
echo ""
echo "Services running:"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - MinIO: localhost:9000 (API), localhost:9001 (Console)"
echo ""
echo "MinIO Console: http://localhost:9001"
echo "  Username: minioadmin"
echo "  Password: minioadmin123"
echo ""

# Check if Go is available
if command -v go &> /dev/null; then
    echo "=========================================="
    echo "🔧 Backend Setup"
    echo "=========================================="
    echo ""

    cd backend

    # Check if .env exists
    if [ ! -f .env ]; then
        echo "Creating .env file from template..."
        cp .env.example .env
        echo "✅ .env file created"
    else
        echo "✅ .env file already exists"
    fi

    echo ""
    echo "Installing Go dependencies..."
    go mod download
    echo "✅ Dependencies installed"

    echo ""
    echo "=========================================="
    echo "🚀 Starting Backend API"
    echo "=========================================="
    echo ""
    echo "Starting backend server..."
    echo "Backend will run on: http://localhost:8080"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""

    # Run the backend
    go run cmd/api/main.go
else
    echo "=========================================="
    echo "⚠️  Backend Not Started"
    echo "=========================================="
    echo ""
    echo "Go is not installed. To start the backend:"
    echo ""
    echo "1. Install Go:"
    echo "   brew install go"
    echo ""
    echo "2. Install dependencies:"
    echo "   cd backend"
    echo "   go mod download"
    echo ""
    echo "3. Start the backend:"
    echo "   go run cmd/api/main.go"
    echo ""
    echo "=========================================="
    echo "📚 Next Steps"
    echo "=========================================="
    echo ""
    echo "1. Install Go (if not installed)"
    echo "2. Start backend: cd backend && go run cmd/api/main.go"
    echo "3. Test API: curl http://localhost:8080/health"
    echo "4. Start admin panel: cd admin && npm install && npm run dev"
    echo "5. Run tests: ./test_upload.sh"
    echo ""
    echo "Documentation:"
    echo "  - CURRENT_STATUS.md - Project status"
    echo "  - NEXT_STEPS.md - Getting started guide"
    echo "  - MEDIA_UPLOAD_TESTING.md - Testing guide"
    echo ""
fi
