import Foundation
import SwiftUI

@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public private(set) var profile: UserProfile?
    @Published public private(set) var posts: [FeedPost] = []
    @Published public private(set) var isLoadingProfile = false
    @Published public private(set) var isLoadingPosts = false
    @Published public private(set) var isUpdatingProfile = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var hasMorePosts = true

    private let service: ProfileServiceProtocol
    private let userID: Int64?
    private let pageSize: Int

    public init(
        service: ProfileServiceProtocol,
        userID: Int64? = nil,
        pageSize: Int = 20
    ) {
        self.service = service
        self.userID = userID
        self.pageSize = pageSize
    }

    public var isMyProfile: Bool {
        guard let userID = userID else { return true }
        return false
    }

    public func loadProfile() async {
        guard !isLoadingProfile else { return }
        isLoadingProfile = true
        errorMessage = nil

        do {
            if let userID = userID {
                profile = try await service.fetchUserProfile(userID: userID)
            } else {
                profile = try await service.fetchMyProfile()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingProfile = false
    }

    public func loadPosts(refresh: Bool = false) async {
        guard !isLoadingPosts else { return }

        if refresh {
            posts = []
            hasMorePosts = true
        }

        guard hasMorePosts else { return }

        isLoadingPosts = true
        errorMessage = nil

        do {
            let targetUserID = userID ?? profile?.id ?? 0
            let result = try await service.fetchUserPosts(
                userID: targetUserID,
                offset: posts.count,
                limit: pageSize
            )
            posts.append(contentsOf: result.items)
            hasMorePosts = result.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingPosts = false
    }

    public func refresh() async {
        await loadProfile()
        await loadPosts(refresh: true)
    }

    public func loadMoreIfNeeded(currentPost: FeedPost) async {
        guard let lastPost = posts.last,
              lastPost.id == currentPost.id,
              hasMorePosts,
              !isLoadingPosts else {
            return
        }
        await loadPosts()
    }

    public func updateProfile(nickname: String?, avatarURL: String?, bio: String?) async -> Bool {
        guard !isUpdatingProfile else { return false }
        isUpdatingProfile = true
        errorMessage = nil

        do {
            profile = try await service.updateProfile(
                nickname: nickname,
                avatarURL: avatarURL,
                bio: bio
            )
            isUpdatingProfile = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isUpdatingProfile = false
            return false
        }
    }

    public func clearError() {
        errorMessage = nil
    }
}
