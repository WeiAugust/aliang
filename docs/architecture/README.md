# Architecture Documentation

## System Overview

Aliang is a community content platform built with a modern microservices-inspired architecture, consisting of three main components:

1. **Backend API** (Go + Gin) - RESTful API server
2. **iOS Client** (Swift + SwiftUI) - Native mobile application
3. **Admin Panel** (React + TypeScript) - Web-based administration interface

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                             │
├─────────────────────────────────┬───────────────────────────────┤
│                                 │                               │
│  ┌─────────────────────┐       │    ┌─────────────────────┐   │
│  │   iOS App (Swift)   │       │    │  Admin Panel (React)│   │
│  │                     │       │    │                     │   │
│  │  - SwiftUI          │       │    │  - TypeScript       │   │
│  │  - URLSession       │       │    │  - Ant Design       │   │
│  │  - Keychain         │       │    │  - Axios            │   │
│  └──────────┬──────────┘       │    └──────────┬──────────┘   │
│             │                   │               │              │
└─────────────┼───────────────────┴───────────────┼──────────────┘
              │                                   │
              │         HTTPS (JWT Auth)          │
              │                                   │
┌─────────────┴───────────────────────────────────┴──────────────┐
│                      API Gateway Layer                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Nginx Reverse Proxy                    │  │
│  │  - SSL Termination                                        │  │
│  │  - Rate Limiting                                          │  │
│  │  - CORS Headers                                           │  │
│  │  - Static File Serving                                    │  │
│  └────────────────────────┬─────────────────────────────────┘  │
└───────────────────────────┼────────────────────────────────────┘
                            │
┌───────────────────────────┼────────────────────────────────────┐
│                    Application Layer                            │
│  ┌────────────────────────┴─────────────────────────────────┐  │
│  │              Backend API (Go + Gin)                       │  │
│  │                                                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │  │
│  │  │   Handler   │  │  Middleware │  │   Router    │     │  │
│  │  │   Layer     │  │   Layer     │  │   Layer     │     │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │  │
│  │         │                │                │             │  │
│  │  ┌──────┴────────────────┴────────────────┴──────┐     │  │
│  │  │              Service Layer                     │     │  │
│  │  │  - Auth Service                                │     │  │
│  │  │  - User Service                                │     │  │
│  │  │  - Post Service                                │     │  │
│  │  │  - Interaction Service                         │     │  │
│  │  │  - Search Service                              │     │  │
│  │  └──────────────────────┬─────────────────────────┘     │  │
│  │                         │                               │  │
│  │  ┌──────────────────────┴─────────────────────────┐    │  │
│  │  │           Repository Layer                      │    │  │
│  │  │  - User Repository                              │    │  │
│  │  │  - Post Repository                              │    │  │
│  │  │  - Comment Repository                           │    │  │
│  │  │  - Like Repository                              │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────────┘  │
└───────────────────────────┬────────────────────────────────────┘
                            │
┌───────────────────────────┼────────────────────────────────────┐
│                     Data Layer                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │  PostgreSQL 16 │  │    Redis 7     │  │     MinIO      │   │
│  │                │  │                │  │                │   │
│  │  - User Data   │  │  - Sessions    │  │  - Images      │   │
│  │  - Posts       │  │  - Feed Cache  │  │  - Videos      │   │
│  │  - Comments    │  │  - Rate Limit  │  │  - Avatars     │   │
│  │  - Likes       │  │                │  │                │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Component Descriptions

### Backend API (Go + Gin)

The backend is a RESTful API server built with Go and the Gin web framework.

**Responsibilities**:
- User authentication and authorization
- Content CRUD operations
- Social interactions (likes, comments)
- Search and discovery
- File upload and storage
- Admin operations

**Key Technologies**:
- **Gin**: HTTP web framework
- **pgx**: PostgreSQL driver
- **go-redis**: Redis client
- **minio-go**: Object storage client
- **jwt-go**: JWT authentication
- **golang-migrate**: Database migrations

**Architecture Layers**:

1. **Handler Layer**: HTTP request/response handling
2. **Middleware Layer**: Authentication, logging, CORS, rate limiting
3. **Service Layer**: Business logic
4. **Repository Layer**: Data access abstraction
5. **Model Layer**: Domain entities

### iOS Client (Swift + SwiftUI)

Native iOS application for end users.

**Responsibilities**:
- User authentication
- Content browsing and creation
- Social interactions
- Profile management
- Search and discovery

**Key Technologies**:
- **SwiftUI**: Declarative UI framework
- **URLSession**: HTTP networking
- **Keychain**: Secure token storage
- **Combine**: Reactive programming
- **AVKit**: Video playback

**Architecture Pattern**: MVVM (Model-View-ViewModel)

### Admin Panel (React + TypeScript)

Web-based administration interface.

**Responsibilities**:
- Content moderation
- User management
- Analytics and statistics
- System configuration

**Key Technologies**:
- **React 18**: UI library
- **TypeScript**: Type safety
- **Vite**: Build tool
- **Ant Design**: UI component library
- **Axios**: HTTP client
- **Zustand**: State management
- **React Router**: Client-side routing

## Data Flow

### User Authentication Flow

```
┌─────────┐                ┌─────────┐                ┌──────────┐
│  Client │                │ Backend │                │   Redis  │
└────┬────┘                └────┬────┘                └────┬─────┘
     │                          │                          │
     │  POST /auth/sms/send     │                          │
     ├─────────────────────────>│                          │
     │                          │                          │
     │                          │  Generate & Store Code   │
     │                          ├─────────────────────────>│
     │                          │                          │
     │  { code: "123456" }      │                          │
     │<─────────────────────────┤                          │
     │                          │                          │
     │  POST /auth/sms/verify   │                          │
     ├─────────────────────────>│                          │
     │                          │                          │
     │                          │  Verify Code             │
     │                          ├─────────────────────────>│
     │                          │                          │
     │                          │  Code Valid              │
     │                          │<─────────────────────────┤
     │                          │                          │
     │  { token: "jwt..." }     │                          │
     │<─────────────────────────┤                          │
     │                          │                          │
     │  Store in Keychain       │                          │
     │                          │                          │
```

### Post Creation Flow

```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌──────────┐
│  Client │     │ Backend │     │  MinIO   │     │PostgreSQL│
└────┬────┘     └────┬────┘     └────┬─────┘     └────┬─────┘
     │               │               │                │
     │  Upload Image │               │                │
     ├──────────────>│               │                │
     │               │  Store Image  │                │
     │               ├──────────────>│                │
     │               │               │                │
     │               │  Image URL    │                │
     │               │<──────────────┤                │
     │               │               │                │
     │  Create Post  │               │                │
     ├──────────────>│               │                │
     │               │  Insert Post  │                │
     │               ├───────────────────────────────>│
     │               │               │                │
     │               │  Post Created │                │
     │               │<───────────────────────────────┤
     │               │               │                │
     │  Post Data    │               │                │
     │<──────────────┤               │                │
     │               │               │                │
```

### Interaction Flow (Like + Comment)

1. iOS feed and detail both call `POST /api/v1/posts/:id/like` for like toggling.
2. Client performs optimistic state update (heart + count) and rolls back on failure.
3. Backend `InteractionHandler.ToggleLike` updates `likes` and returns authoritative `is_liked` + `like_count`.
4. iOS propagates the updated interaction state to both feed list and detail screen to keep counts and status synchronized.
5. Comment icon focuses the composer, then submit calls `POST /api/v1/posts/:id/comments`; backend writes `comments` and increments post `comment_count`.

### Search Flow (Elasticsearch-First, Fuzzy)

1. During publish, `PostService.Create` writes post data to PostgreSQL and indexes title/content to Elasticsearch via `SearchEngine.IndexPost`.
2. Search page calls `GET /api/v1/search?q=...` with pagination.
3. Backend `SearchService.SearchPosts` queries ES first (`multi_match` on title/content with `fuzziness: AUTO`) and gets ranked post IDs.
4. Service loads full posts by IDs from PostgreSQL and filters out non-public/deleted records before returning.
5. If ES is unavailable, service falls back to PostgreSQL full-text + `ILIKE` search to keep functionality available.

### Feed Loading Flow

```
┌─────────┐     ┌─────────┐     ┌──────────┐     ┌──────────┐
│  Client │     │ Backend │     │  Redis   │     │PostgreSQL│
└────┬────┘     └────┬────┘     └────┬─────┘     └────┬─────┘
     │               │               │                │
     │  GET /posts   │               │                │
     ├──────────────>│               │                │
     │               │  Check Cache  │                │
     │               ├──────────────>│                │
     │               │               │                │
     │               │  Cache Miss   │                │
     │               │<──────────────┤                │
     │               │               │                │
     │               │  Query Posts  │                │
     │               ├───────────────────────────────>│
     │               │               │                │
     │               │  Posts Data   │                │
     │               │<───────────────────────────────┤
     │               │               │                │
     │               │  Cache Result │                │
     │               ├──────────────>│                │
     │               │               │                │
     │  Posts Array  │               │                │
     │<──────────────┤               │                │
     │               │               │                │
```

## Technology Choices

### Why Go for Backend?

1. **Performance**: Compiled language with excellent concurrency support
2. **Simplicity**: Easy to learn, maintain, and deploy
3. **Standard Library**: Rich standard library for HTTP, JSON, etc.
4. **Deployment**: Single binary deployment, no runtime dependencies
5. **Ecosystem**: Mature ecosystem for web development

### Why PostgreSQL?

1. **Relational Data**: Posts, users, and relationships fit relational model
2. **Full-Text Search**: Built-in full-text search with `tsvector`
3. **JSONB**: Flexible schema for metadata
4. **Reliability**: ACID compliance and data integrity
5. **Performance**: Excellent query performance with proper indexing

### Why Redis?

1. **Caching**: Fast in-memory caching for feed data
2. **Session Storage**: JWT token blacklist and session management
3. **Rate Limiting**: Token bucket algorithm for rate limiting
4. **Performance**: Sub-millisecond latency

### Why MinIO?

1. **S3 Compatible**: Standard S3 API for object storage
2. **Self-Hosted**: No vendor lock-in, full control
3. **Cost**: Free and open-source
4. **Performance**: High-throughput object storage

### Why SwiftUI for iOS?

1. **Native**: Best performance and user experience on iOS
2. **Modern**: Declarative UI with less boilerplate
3. **Apple Ecosystem**: First-class support for iOS features
4. **Future-Proof**: Apple's recommended approach

### Why React for Admin Panel?

1. **Ecosystem**: Rich ecosystem of libraries and tools
2. **TypeScript**: Type safety for large codebases
3. **Component Model**: Reusable UI components
4. **Developer Experience**: Fast development with hot reload

## Security Considerations

### Authentication

- JWT tokens with 24-hour expiration
- Secure token storage (Keychain on iOS, localStorage on web)
- Token refresh mechanism
- Admin role separation

### Authorization

- Middleware-based authorization checks
- Resource ownership validation
- Admin-only endpoints protected

### Data Protection

- HTTPS/TLS for all communications
- Password hashing (bcrypt for admin accounts)
- SQL injection prevention (parameterized queries)
- XSS prevention (input sanitization)
- CSRF protection (SameSite cookies)

### Rate Limiting

- IP-based rate limiting (100 req/min)
- Token-based rate limiting for authenticated users
- Exponential backoff for failed login attempts

## Scalability Considerations

### Horizontal Scaling

- Stateless backend API (can run multiple instances)
- Load balancer (Nginx) for traffic distribution
- Database connection pooling
- Redis for shared session state

### Caching Strategy

- Feed caching (5-minute TTL)
- User profile caching (10-minute TTL)
- CDN for static assets and media files

### Database Optimization

- Indexes on frequently queried columns
- Cursor-based pagination for large datasets
- Read replicas for read-heavy workloads
- Connection pooling

### Media Storage

- Object storage (MinIO/S3) for scalability
- Image thumbnails for faster loading
- Video transcoding for multiple qualities
- CDN for media delivery

## Monitoring and Observability

### Logging

- Structured logging with Zap
- Request ID correlation
- Error tracking and alerting

### Metrics

- API response times
- Database query performance
- Cache hit/miss rates
- Error rates

### Health Checks

- `/health` endpoint for liveness
- `/ready` endpoint for readiness
- Database connection health
- Redis connection health

## Deployment Architecture

### Development

- Docker Compose for local development
- Hot reload for backend and admin panel
- Mock services (SMS, payment)

### Production

- Docker containers on cloud VMs
- Nginx reverse proxy
- PostgreSQL with automated backups
- Redis with persistence
- MinIO with replication

## Future Enhancements

1. **Real-time Features**: WebSocket for live notifications
2. **Recommendation Engine**: ML-based content recommendations
3. **Video Processing**: Automatic transcoding and thumbnails
4. **Analytics**: Advanced analytics and insights
5. **Internationalization**: Multi-language support
6. **Android App**: Native Android client
