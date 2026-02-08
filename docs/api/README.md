# API Documentation

## Overview

The Aliang API is a RESTful API that provides endpoints for user authentication, content management, and social interactions.

**Base URL**: `http://localhost:8080/api/v1`

**Authentication**: JWT Bearer token in the `Authorization` header

## Response Format

All API responses follow a consistent envelope format:

### Success Response

```json
{
  "success": true,
  "data": {
    // Response data
  },
  "message": "Success message"
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid authentication token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 422 | Invalid request data |
| `INTERNAL_ERROR` | 500 | Internal server error |

## Rate Limiting

- **Rate Limit**: 100 requests per minute per IP address
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests per window
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Unix timestamp when the rate limit resets

## Pagination

List endpoints support cursor-based pagination:

**Query Parameters**:
- `cursor`: Pagination cursor (optional, omit for first page)
- `limit`: Number of items per page (default: 20, max: 100)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "eyJpZCI6MTIzfQ==",
    "has_more": true
  }
}
```

## Authentication

### Send SMS Verification Code

Send a verification code to the user's phone number (mock implementation).

**Endpoint**: `POST /auth/sms/send`

**Request Body**:
```json
{
  "phone": "13800138000"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "code": "123456",
    "expires_at": "2024-01-01T12:05:00Z"
  },
  "message": "Verification code sent"
}
```

**Notes**:
- In development mode, the verification code is always `123456`
- Code expires after 5 minutes

### Login with SMS Code

Verify the SMS code and login/register the user.

**Endpoint**: `POST /auth/sms/verify`

**Request Body**:
```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "1",
      "phone": "13800138000",
      "nickname": "User_1",
      "avatar": "",
      "created_at": "2024-01-01T12:00:00Z"
    }
  }
}
```

**Notes**:
- If the user doesn't exist, a new account is created automatically
- Token expires after 24 hours

### Admin Login

Login as an administrator with username and password.

**Endpoint**: `POST /admin/auth/login`

**Request Body**:
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "admin": {
      "id": "1",
      "username": "admin",
      "role": "admin"
    }
  }
}
```

## Users

### Get Current User Profile

Get the authenticated user's profile.

**Endpoint**: `GET /users/me`

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "phone": "13800138000",
    "nickname": "User_1",
    "avatar": "https://example.com/avatar.jpg",
    "bio": "Hello, I'm a user!",
    "post_count": 10,
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

### Update User Profile

Update the authenticated user's profile.

**Endpoint**: `PUT /users/me`

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "nickname": "New Nickname",
  "bio": "Updated bio",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "nickname": "New Nickname",
    "bio": "Updated bio",
    "avatar": "https://example.com/new-avatar.jpg"
  }
}
```

### Get User Profile

Get a user's public profile.

**Endpoint**: `GET /users/:id`

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "nickname": "User_1",
    "avatar": "https://example.com/avatar.jpg",
    "bio": "Hello!",
    "post_count": 10,
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

## Posts

### Create Post

Create a new post with text and media.

**Endpoint**: `POST /posts`

**Headers**: `Authorization: Bearer <token>`

**Request Body** (multipart/form-data):
```
title: "My First Post"
content: "This is my first post! #hello #world"
images[]: <file1>
images[]: <file2>
video: <file>
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "user_id": "1",
    "title": "My First Post",
    "content": "This is my first post! #hello #world",
    "media": [
      {
        "type": "image",
        "url": "https://example.com/image1.jpg",
        "thumbnail_url": "https://example.com/thumb1.jpg"
      }
    ],
    "hashtags": ["hello", "world"],
    "like_count": 0,
    "comment_count": 0,
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

**Notes**:
- Maximum 9 images OR 1 video per post
- Images: max 10MB each, formats: JPEG, PNG, WebP
- Video: max 100MB, format: MP4

### Get Post Feed

Get a paginated list of posts.

**Endpoint**: `GET /posts`

**Query Parameters**:
- `cursor`: Pagination cursor (optional)
- `limit`: Items per page (default: 20, max: 100)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "1",
        "user": {
          "id": "1",
          "nickname": "User_1",
          "avatar": "https://example.com/avatar.jpg"
        },
        "title": "My First Post",
        "content": "This is my first post!",
        "media": [...],
        "like_count": 10,
        "comment_count": 5,
        "is_liked": false,
        "created_at": "2024-01-01T12:00:00Z"
      }
    ],
    "next_cursor": "eyJpZCI6MX0=",
    "has_more": true
  }
}
```

### Get Post Detail

Get detailed information about a specific post.

**Endpoint**: `GET /posts/:id`

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "user": {
      "id": "1",
      "nickname": "User_1",
      "avatar": "https://example.com/avatar.jpg"
    },
    "title": "My First Post",
    "content": "This is my first post! #hello #world",
    "media": [...],
    "hashtags": ["hello", "world"],
    "like_count": 10,
    "comment_count": 5,
    "is_liked": false,
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

### Delete Post

Delete a post (owner only).

**Endpoint**: `DELETE /posts/:id`

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "success": true,
  "message": "Post deleted successfully"
}
```

## Interactions

### Like Post

Like or unlike a post (toggle).

**Endpoint**: `POST /posts/:id/like`

**Headers**: `Authorization: Bearer <token>`

**Response**:
```json
{
  "success": true,
  "data": {
    "is_liked": true,
    "like_count": 11
  }
}
```

### Get Comments

Get comments for a post.

**Endpoint**: `GET /posts/:id/comments`

**Query Parameters**:
- `cursor`: Pagination cursor (optional)
- `limit`: Items per page (default: 20, max: 100)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "1",
        "user": {
          "id": "2",
          "nickname": "User_2",
          "avatar": "https://example.com/avatar2.jpg"
        },
        "content": "Great post!",
        "created_at": "2024-01-01T12:05:00Z"
      }
    ],
    "next_cursor": "eyJpZCI6MX0=",
    "has_more": false
  }
}
```

### Add Comment

Add a comment to a post.

**Endpoint**: `POST /posts/:id/comments`

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "content": "Great post!"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "user": {
      "id": "1",
      "nickname": "User_1",
      "avatar": "https://example.com/avatar.jpg"
    },
    "content": "Great post!",
    "created_at": "2024-01-01T12:05:00Z"
  }
}
```

## Search

### Search Posts

Search posts by keyword.

**Endpoint**: `GET /search`

**Query Parameters**:
- `q`: Search query (required)
- `cursor`: Pagination cursor (optional)
- `limit`: Items per page (default: 20, max: 100)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "eyJpZCI6MX0=",
    "has_more": true
  }
}
```

### Get Trending Hashtags

Get trending hashtags.

**Endpoint**: `GET /hashtags/trending`

**Query Parameters**:
- `limit`: Number of hashtags (default: 10, max: 50)

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "name": "hello",
      "post_count": 100
    },
    {
      "name": "world",
      "post_count": 80
    }
  ]
}
```

### Get Posts by Hashtag

Get posts with a specific hashtag.

**Endpoint**: `GET /hashtags/:name/posts`

**Query Parameters**:
- `cursor`: Pagination cursor (optional)
- `limit`: Items per page (default: 20, max: 100)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "eyJpZCI6MX0=",
    "has_more": true
  }
}
```

## Admin Endpoints

All admin endpoints require an admin JWT token.

### Get Dashboard Statistics

Get overall statistics for the dashboard.

**Endpoint**: `GET /admin/stats`

**Headers**: `Authorization: Bearer <admin-token>`

**Response**:
```json
{
  "success": true,
  "data": {
    "total_users": 1234,
    "total_posts": 5678,
    "total_likes": 12345,
    "total_comments": 6789,
    "daily_active_users": 456,
    "daily_new_posts": 123
  }
}
```

### List All Posts

Get a paginated list of all posts with filters.

**Endpoint**: `GET /admin/posts`

**Headers**: `Authorization: Bearer <admin-token>`

**Query Parameters**:
- `cursor`: Pagination cursor (optional)
- `limit`: Items per page (default: 20, max: 100)
- `visibility`: Filter by visibility (`public`, `self_only`)
- `status`: Filter by status (`normal`, `recommended`, `not_recommended`)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [...],
    "next_cursor": "eyJpZCI6MX0=",
    "has_more": true
  }
}
```

### Update Post Visibility

Change a post's visibility.

**Endpoint**: `PUT /admin/posts/:id/visibility`

**Headers**: `Authorization: Bearer <admin-token>`

**Request Body**:
```json
{
  "visibility": "self_only"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Post visibility updated"
}
```

### Update Post Status

Mark a post as recommended or not recommended.

**Endpoint**: `PUT /admin/posts/:id/status`

**Headers**: `Authorization: Bearer <admin-token>`

**Request Body**:
```json
{
  "status": "recommended"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Post status updated"
}
```

### Delete Post (Admin)

Delete any post as an administrator.

**Endpoint**: `DELETE /admin/posts/:id`

**Headers**: `Authorization: Bearer <admin-token>`

**Response**:
```json
{
  "success": true,
  "message": "Post deleted successfully"
}
```

### List All Users

Get a paginated list of all users.

**Endpoint**: `GET /admin/users`

**Headers**: `Authorization: Bearer <admin-token>`

**Query Parameters**:
- `cursor`: Pagination cursor (optional)
- `limit`: Items per page (default: 20, max: 100)
- `q`: Search query (optional)

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "1",
        "phone": "138****1234",
        "nickname": "User_1",
        "post_count": 10,
        "status": "active",
        "created_at": "2024-01-01T12:00:00Z"
      }
    ],
    "next_cursor": "eyJpZCI6MX0=",
    "has_more": true
  }
}
```

### Get User Detail (Admin)

Get detailed information about a user.

**Endpoint**: `GET /admin/users/:id`

**Headers**: `Authorization: Bearer <admin-token>`

**Response**:
```json
{
  "success": true,
  "data": {
    "id": "1",
    "phone": "13800138000",
    "nickname": "User_1",
    "avatar": "https://example.com/avatar.jpg",
    "bio": "Hello!",
    "post_count": 10,
    "status": "active",
    "created_at": "2024-01-01T12:00:00Z",
    "recent_posts": [...]
  }
}
```

## File Upload

### Upload Image

Upload an image file.

**Endpoint**: `POST /upload/image`

**Headers**: `Authorization: Bearer <token>`

**Request Body** (multipart/form-data):
```
file: <image-file>
```

**Response**:
```json
{
  "success": true,
  "data": {
    "url": "https://example.com/uploads/image.jpg",
    "thumbnail_url": "https://example.com/uploads/thumb.jpg"
  }
}
```

### Upload Video

Upload a video file.

**Endpoint**: `POST /upload/video`

**Headers**: `Authorization: Bearer <token>`

**Request Body** (multipart/form-data):
```
file: <video-file>
```

**Response**:
```json
{
  "success": true,
  "data": {
    "url": "https://example.com/uploads/video.mp4",
    "thumbnail_url": "https://example.com/uploads/video-thumb.jpg"
  }
}
```
