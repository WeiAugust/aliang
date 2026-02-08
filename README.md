# Aliang - Community Content System

[![CI](https://github.com/WeiAugust/aliang/workflows/CI/badge.svg)](https://github.com/WeiAugust/aliang/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-grade community content platform inspired by Xiaohongshu and Instagram, featuring an iOS mobile app, web admin panel, and RESTful backend API.

## Overview

Aliang is a full-stack social content platform that enables users to:
- Share posts with text, images (up to 9), and videos
- Discover content through a chronological feed
- Interact via likes and comments
- Search content and explore hashtags
- Manage their profile and posts

Administrators can moderate content, manage users, and view analytics through a dedicated web dashboard.

## Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Backend** | Go 1.22+ (Gin) | RESTful API server |
| **Database** | PostgreSQL 16 | Relational data storage |
| **Cache** | Redis 7 | Session & feed caching |
| **Storage** | MinIO | Object storage (images/videos) |
| **iOS App** | Swift 5.9+ (SwiftUI) | Native iOS client (iOS 17+) |
| **Admin Panel** | React 18 + TypeScript + Vite | Web-based admin dashboard |
| **Infrastructure** | Docker + Docker Compose | Containerized deployment |
| **CI/CD** | GitHub Actions | Automated testing & releases |

## Project Structure

```
aliang/
├── backend/           # Go backend API
│   ├── cmd/api/       # Application entrypoint
│   ├── internal/      # Private application code
│   ├── migrations/    # SQL migration files
│   └── pkg/           # Public shared packages
├── ios/               # iOS SwiftUI app
├── admin/             # React admin panel
├── docs/              # Documentation
│   ├── api/           # API documentation
│   ├── architecture/  # Architecture diagrams
│   └── deployment/    # Deployment guides
└── docker-compose.yml # Local development environment
```

## Quick Start

### Prerequisites

- Docker 24+ and Docker Compose v2
- Go 1.22+ (for backend development)
- Node.js 20+ (for admin panel development)
- Xcode 15+ (for iOS development)

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/WeiAugust/aliang.git
   cd aliang
   ```

2. **Start infrastructure services**
   ```bash
   docker-compose up -d
   ```
   This starts PostgreSQL, Redis, and MinIO.

3. **Run database migrations**
   ```bash
   cd backend
   make migrate-up
   ```

4. **Start the backend API**
   ```bash
   cd backend
   make dev
   ```
   Backend runs on `http://localhost:8080`

5. **Start the admin panel**
   ```bash
   cd admin
   npm install
   npm run dev
   ```
   Admin panel runs on `http://localhost:3000`

6. **Run the iOS app**
   ```bash
   cd ios
   open CommunityApp.xcodeproj
   ```
   Build and run in Xcode simulator.

## Test Accounts

### Admin Panel
- **URL**: `http://localhost:3000`
- **Username**: `admin`
- **Password**: `admin123`

### iOS App (Mock SMS)
- **Phone**: `13800138000`
- **Verification Code**: `123456`

## API Documentation

- **Base URL**: `http://localhost:8080/api/v1`
- **OpenAPI Spec**: [docs/api/openapi.yaml](docs/api/openapi.yaml)
- **Interactive Docs**: Run `make docs` to serve Swagger UI

## Development

### Backend
```bash
cd backend
make test          # Run tests
make lint          # Run linters
make build         # Build binary
```

### Admin Panel
```bash
cd admin
npm test           # Run tests
npm run lint       # Run ESLint
npm run build      # Build for production
```

### iOS App
```bash
cd ios
xcodebuild test -scheme CommunityApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Deployment

See [docs/deployment/README.md](docs/deployment/README.md) for detailed deployment instructions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.
