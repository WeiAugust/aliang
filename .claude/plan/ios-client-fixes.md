# iOS Client Fixes - Implementation Plan

## Issues to Fix

1. Like interaction and count problems
2. Cannot comment
3. Search cannot find published posts
4. Profile post count wrong
5. Default avatar for users

---

## Fix 1: Like Interaction and Count

### Root Cause
- **Backend** `interaction_handler.go:72-77`: `ToggleLike` returns only `is_liked`, missing `like_count`
- **Backend** `post_handler.go:122-128`: `GetPosts` (feed) doesn't include per-user `is_liked` state
- **iOS**: `ToggleLikeResponse.likeCount` is optional, falls back to optimistic count (works but not ideal)

### Changes

**Backend `interaction_handler.go`** - Return `like_count` after toggle:
- After `ToggleLike`, query the post's current `like_count` from DB
- Add `like_count` to the response JSON alongside `is_liked`
- Need to add `GetByID` to the `interactionPostRepo` interface or add a `GetLikeCount` method

**Backend `post_handler.go`** - Add `is_liked` to feed posts:
- `GetPosts` handler needs to check if the current user has liked each post
- Extract user ID from JWT (optional auth - don't fail if not present)
- For each post, check `likeRepo.Exists(ctx, userID, postID)`
- Add `is_liked` field to each post in the response
- Same for `GetPost` single post endpoint

**Backend `interaction_handler.go`** - Need access to post repo for like count:
- Extend `interactionServiceAPI` interface to include a method that returns both `isLiked` and `likeCount`
- Or: add a `GetPostLikeCount` method to the interaction service

---

## Fix 2: Cannot Comment

### Root Cause
- **Backend** `interaction_handler.go:181-190`: `CreateComment` returns `comment.CreatedAt` which is set by GORM's `default:CURRENT_TIMESTAMP` at DB level
- GORM's `Create()` should populate `CreatedAt` after insert via `RETURNING` clause
- The actual issue: the iOS `CommentPayload` decoder uses `created_at` CodingKey with the default `iso8601` date decoding strategy on `HTTPClient`, but the backend returns Go's `time.Time` JSON format which is RFC3339 (compatible with ISO8601)
- **Real issue found**: The `Comment` model has `json:"created_at"` tag, and GORM populates `CreatedAt` after `Create()`. The response should work. Need to verify if there's a date format mismatch or if the issue is that `comment.ID` is 0 (GORM should auto-fill after Create).

### Changes

**Backend `interaction_handler.go`** - Ensure comment is fully populated after creation:
- After `CreateComment`, reload the comment from DB to ensure all fields are populated
- Or verify GORM returns the auto-generated fields (ID, CreatedAt) after Create

**No iOS changes needed** - The iOS code looks correct for comment creation.

---

## Fix 3: Search Cannot Find Published Posts

### Root Cause
- **Backend** `post_repository.go:118-130`: Search uses `to_tsvector('english', content) @@ plainto_tsquery('english', ?)`
- Only searches `content` field, NOT `title`
- Uses `english` language config - won't tokenize Chinese text properly

### Changes

**Backend `post_repository.go`** - Fix search query:
- Search both `title` and `content`: `to_tsvector('simple', title || ' ' || content) @@ plainto_tsquery('simple', ?)`
- Use `simple` tokenizer instead of `english` for better CJK support
- Add fallback LIKE search: `OR title ILIKE '%query%' OR content ILIKE '%query%'`
- This ensures both English and Chinese text can be found

**Backend migration** (optional):
- Add GIN index on `to_tsvector('simple', title || ' ' || content)` for performance
- Existing index only covers `content` with `english` config

---

## Fix 4: Profile Post Count Wrong

### Root Cause
- **Backend** `user_handler.go:54`: `ListByUserID(ctx, userID, 0, 1)` returns max 1 post
- `postCount = len(posts)` is always 0 or 1
- Same bug at `user_handler.go:177` for `GetUser`

### Changes

**Backend `user_handler.go`** - Use proper count query:
- Replace `ListByUserID(ctx, userID, 0, 1)` + `len(posts)` with `GetStatsByUserID`
- `GetStatsByUserID` already exists in `UserService` and does proper `COUNT(*)` aggregation
- Need to inject `UserService` (already available via `h.userService`) or add a count method to post service

**Specific changes**:
- In `GetMe`: Replace lines 53-55 with call to `h.userService.GetStatsByUserID(ctx, userID)`
- In `GetUser`: Replace lines 176-178 with call to `h.userService.GetStatsByUserID(ctx, id)`
- Use the `postCount` from the stats result

---

## Fix 5: Default Avatar

### Root Cause
- `AppAvatarView` already shows a placeholder (gray gradient + person.fill icon) when URL is nil
- Need a more visually distinctive default avatar with brand colors

### Changes

**iOS `AppTheme.swift`** - Enhance `AppAvatarView` placeholder:
- Use the brand gradient (`appBrandGradient`) as background instead of gray shimmer
- Use white person icon for better contrast
- This gives users a colorful, recognizable default avatar

---

## Implementation Order

1. Create feature branch `fix/ios-client-issues`
2. **Backend fixes** (all in Go):
   - Fix 4: Profile post count (simplest, highest confidence)
   - Fix 3: Search query (straightforward SQL change)
   - Fix 1: Like count in toggle response + is_liked in feed
   - Fix 2: Verify comment creation (may already work)
3. **iOS fixes**:
   - Fix 5: Default avatar enhancement
   - Fix 1: Verify like state sync works with backend changes
4. Build and test
5. Merge to main and push

## Files to Modify

### Backend
- `backend/internal/handler/user_handler.go` - Fix post count (Fix 4)
- `backend/internal/handler/interaction_handler.go` - Return like_count (Fix 1)
- `backend/internal/handler/post_handler.go` - Add is_liked to feed (Fix 1)
- `backend/internal/repository/post_repository.go` - Fix search query (Fix 3)
- `backend/internal/service/interaction_service.go` - Add GetPostLikeCount (Fix 1)

### iOS
- `ios/Sources/AliangIOS/Core/UI/AppTheme.swift` - Default avatar (Fix 5)
