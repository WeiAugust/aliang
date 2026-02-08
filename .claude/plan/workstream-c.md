# Workstream C: iOS Feature Completion Implementation Plan

**Created:** 2026-02-08
**Session ID:** multi-execute-workstream-c
**Task Type:** Frontend (iOS/SwiftUI)

## Overview

Complete Workstream C features for iOS client:
- C1: Integrate composer entry into app flow
- C2: Implement profile page
- C3: Implement search + hashtag flows
- C4: Complete media publish E2E

## Dependencies

- Track A/B/C/E must be complete (verified per STATUS.md)
- Backend API endpoints available and tested
- Authentication flow working

---

## Implementation Sequence

### Phase 1: C1 - Composer Entry Integration
**Priority:** P0
**Prerequisites:** None (can start immediately)

#### Steps:
1. Add "+" compose button to FeedView toolbar
2. Navigate to ComposerView on tap
3. Pass composerService through navigation
4. Handle publish completion callback
5. Refresh FeedView or append new post locally

#### Key Files:
- `ios/Sources/AliangIOS/Features/Feed/Views/FeedView.swift` - Add composer button
- `ios/Sources/AliangIOS/Features/Feed/ViewModels/FeedViewModel.swift` - Add refresh capability
- `ios/Sources/AliangIOS/Features/Composer/Views/ComposerView.swift` - May need minor updates

#### Backend APIs:
- POST `/api/v1/posts` - Create post

#### Deliverables:
- Compose button visible in FeedView toolbar
- Tap opens ComposerView with media picker
- After publish, navigate back and refresh feed

---

### Phase 2: C2 - Profile Page
**Priority:** P0
**Prerequisites:** C1 (optional, can parallelize)

#### Steps:
1. Create ProfileModels.swift with User, UserPost structures
2. Create ProfileRequests.swift with APIRequest implementations:
   - GET `/api/v1/users/me` - Current user profile
   - GET `/api/v1/users/{id}` - User by ID
   - PATCH `/api/v1/users/me` - Update profile (optional)
3. Create ProfileService.swift with service methods
4. Create ProfileViewModel.swift with @MainActor ObservableObject
5. Create ProfileView.swift with:
   - User header (avatar, nickname, stats)
   - Posts tab (grid or list of user's posts)
   - Edit profile button (optional)
6. Add ProfileView to app navigation (tab bar or menu)

#### Key Files (Create):
- `ios/Sources/AliangIOS/Features/Profile/Models/ProfileModels.swift`
- `ios/Sources/AliangIOS/Features/Profile/Networking/ProfileRequests.swift`
- `ios/Sources/AliangIOS/Features/Profile/Services/ProfileService.swift`
- `ios/Sources/AliangIOS/Features/Profile/ViewModels/ProfileViewModel.swift`
- `ios/Sources/AliangIOS/Features/Profile/Views/ProfileView.swift`

#### Backend APIs:
- GET `/api/v1/users/me`
- GET `/api/v1/users/{id}`
- PATCH `/api/v1/users/me`
- GET `/api/v1/users/{id}/posts`

#### Deliverables:
- ProfileView accessible from navigation
- Shows user info: avatar, nickname, stats
- Displays user's posts in paginated list
- Pull-to-refresh support

---

### Phase 3: C3 - Search + Hashtag Flows
**Priority:** P0
**Prerequisites:** C2 (can share pattern, can parallelize)

#### Steps:
1. Create SearchModels.swift with SearchResult, TrendingHashtag structures
2. Create SearchRequests.swift with APIRequest implementations:
   - GET `/api/v1/search?q=query` - Search posts
   - GET `/api/v1/hashtags/trending` - Trending hashtags
   - GET `/api/v1/hashtags/{name}/posts` - Posts by hashtag
3. Create SearchService.swift with service methods
4. Create SearchViewModel.swift with @MainActor ObservableObject
5. Create SearchView.swift with:
   - Search bar at top
   - Trending hashtags section
   - Search results list
   - Hashtag detail view (reusable component)
6. Add search bar to FeedView or create Search tab

#### Key Files (Create):
- `ios/Sources/AliangIOS/Features/Search/Models/SearchModels.swift`
- `ios/Sources/AliangIOS/Features/Search/Networking/SearchRequests.swift`
- `ios/Sources/AliangIOS/Features/Search/Services/SearchService.swift`
- `ios/Sources/AliangIOS/Features/Search/ViewModels/SearchViewModel.swift`
- `ios/Sources/AliangIOS/Features/Search/Views/SearchView.swift`
- `ios/Sources/AliangIOS/Features/Search/Views/HashtagDetailView.swift`

#### Backend APIs:
- GET `/api/v1/search?q=query`
- GET `/api/v1/hashtags/trending`
- GET `/api/v1/hashtags/{name}/posts`

#### Deliverables:
- SearchView accessible from navigation
- Search bar returns matching posts
- Trending hashtags displayed
- Tap hashtag to see posts with that hashtag

---

### Phase 4: C4 - Media Publish E2E Completion
**Priority:** P0
**Prerequisites:** C1 (must complete C1 first)

#### Steps:
1. Verify C1 integration works end-to-end
2. Test media upload flow: Image/Video picker -> Upload -> Create post
3. Verify new post appears in FeedView after publish
4. Test hashtag extraction (backend feature)
5. Handle edge cases: upload failure, network timeout
6. Add proper error handling with user feedback

#### Verification Steps:
1. Open app -> Login (if needed)
2. Tap "+" button -> ComposerView
3. Select media (image/video) -> Upload
4. Add content with hashtags -> Publish
5. Verify post appears in feed with correct media
6. Tap post -> Verify post detail view

---

## Architecture Patterns to Follow

### Service Protocol Pattern
```swift
protocol ProfileServiceProtocol {
    func fetchUser(id: Int64?) async throws -> User
    func fetchUserPosts(userID: Int64, page: Int, limit: Int) async throws -> [Post]
}

struct ProfileService: ProfileServiceProtocol { ... }
```

### APIRequest Pattern
```swift
struct GetUserRequest: APIRequest {
    let userID: Int64?

    var path: String { userID == nil ? "/api/v1/users/me" : "/api/v1/users/\(userID!)" }
    var method: HTTPMethod { .get }
}
```

### ViewModel Pattern
```swift
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: Error?

    func loadUser() async { ... }
}
```

---

## Dependencies.swift Updates

Add to `ios/Sources/AliangIOS/App/Dependencies.swift`:

```swift
// New services to add
let profileService: ProfileService
let searchService: SearchService
```

---

## Navigation Flow

```
AliangAppView
├── AuthView (conditional on !session.isAuthenticated)
└── MainTabView
    ├── FeedView (tab 0)
    │   └── ComposerView (push from toolbar)
    ├── SearchView (tab 1)
    │   └── HashtagDetailView (push)
    └── ProfileView (tab 2)
```

---

## Progress Tracking

| Feature | Status | Notes |
|---------|--------|-------|
| C1: Composer Entry | ✅ Complete | "+" compose button, fullScreenCover, refresh after publish |
| C2: Profile Page | ✅ Complete | UserProfile, ProfileService, ProfileViewModel, ProfileView |
| C3: Search/Hashtag | ✅ Complete | SearchView, SearchService, SearchViewModel, HashtagDetailView |
| C4: Media E2E | ⚠️ Pending | Depends on backend A1 (media_ids unification) |

---

## Rollback Plan

- All features behind feature flags (AppConfig)
- Existing FeedView unchanged if C1 disabled
- Backend APIs are independent of iOS features

---

## Testing Requirements

- Unit tests for ViewModels
- Integration tests for API services
- Manual E2E verification for C4
- No regressions in existing features (Feed, Auth, Interactions)
