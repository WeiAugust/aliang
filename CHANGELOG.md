# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and monorepo setup
- Backend API foundation (Go + Gin framework)
- iOS client foundation (SwiftUI)
- Admin web panel foundation (React + TypeScript)
- Docker Compose for local development
- CI/CD pipeline with GitHub Actions
- Comprehensive documentation
- **Media Upload functionality (2026-02-08)**
  - StorageService for MinIO integration
  - Image upload endpoint (POST /api/v1/upload/image)
  - Video upload endpoint (POST /api/v1/upload/video)
  - File type and size validation
  - Unique filename generation
  - Test suite and integration tests
  - Complete testing guide

## [1.0.0] - TBD

### Added
- User authentication via SMS verification (mock)
- JWT-based session management
- Post creation with text, images (up to 9), and video
- Chronological content feed with pagination
- Post detail view with full content
- Like and comment interactions
- User profile management
- Content search and hashtag browsing
- Admin panel for content moderation
- Admin panel for user management
- Analytics dashboard with statistics
- PostgreSQL database with migrations
- Redis caching layer
- MinIO object storage for media files
- RESTful API with OpenAPI documentation
- Automated testing (80%+ coverage)
- Docker containerization
- GitHub Actions CI/CD
- Deployment documentation

### Infrastructure
- PostgreSQL 16 for relational data
- Redis 7 for caching and sessions
- MinIO for object storage
- Nginx reverse proxy configuration
- Docker Compose for orchestration

### Documentation
- README with quick start guide
- API documentation (OpenAPI spec)
- Architecture documentation
- Deployment guide
- Contributing guidelines

[Unreleased]: https://github.com/WeiAugust/aliang/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/WeiAugust/aliang/releases/tag/v1.0.0
