import Foundation

@MainActor
public final class FeedViewModel: ObservableObject {
    @Published public private(set) var posts: [FeedPost] = []
    @Published public private(set) var selectedPost: FeedPost?
    @Published public private(set) var isLoading = false
    @Published public private(set) var isRefreshing = false
    @Published public private(set) var isLoadingMore = false
    @Published public private(set) var hasMore = true
    @Published public private(set) var errorMessage: String?

    private let service: FeedServiceProtocol
    private let pageSize: Int
    private var nextOffset = 0
    private var onPostPublished: (() -> Void)?

    public init(service: FeedServiceProtocol, pageSize: Int = 20) {
        self.service = service
        self.pageSize = max(1, pageSize)
    }

    public func setOnPostPublished(_ callback: @escaping () -> Void) {
        self.onPostPublished = callback
    }

    public func notifyPostPublished() {
        onPostPublished?()
    }

    public func onAppearLoadIfNeeded() async {
        guard posts.isEmpty else {
            return
        }

        await loadInitial()
    }

    public func loadInitial() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let page = try await service.fetchFeed(offset: 0, limit: pageSize)
            posts = page.items
            hasMore = page.hasMore
            nextOffset = page.items.count
        } catch {
            errorMessage = mapError(error)
        }
    }

    public func refresh() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }
        errorMessage = nil

        do {
            let page = try await service.fetchFeed(offset: 0, limit: pageSize)
            posts = page.items
            hasMore = page.hasMore
            nextOffset = page.items.count
        } catch {
            errorMessage = mapError(error)
        }
    }

    public func loadMoreIfNeeded(currentPost: FeedPost?) async {
        guard let currentPost else {
            return
        }

        guard hasMore, !isLoadingMore, !isLoading, !isRefreshing else {
            return
        }

        let threshold = max(0, posts.count - 4)
        guard let idx = posts.firstIndex(where: { $0.id == currentPost.id }), idx >= threshold else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await service.fetchFeed(offset: nextOffset, limit: pageSize)

            let existing = Set(posts.map(\.id))
            let newItems = page.items.filter { !existing.contains($0.id) }
            posts.append(contentsOf: newItems)

            nextOffset += page.items.count
            hasMore = page.hasMore
        } catch {
            errorMessage = mapError(error)
        }
    }

    public func openPostDetail(postID: Int64) async {
        errorMessage = nil
        do {
            selectedPost = try await service.fetchPostDetail(postID: postID)
        } catch {
            errorMessage = mapError(error)
        }
    }

    public func closePostDetail() {
        selectedPost = nil
    }

    public func applyInteractionState(_ state: PostInteractionState) {
        if let selectedPost, selectedPost.id == state.postID {
            self.selectedPost = updating(selectedPost, with: state)
        }

        guard let index = posts.firstIndex(where: { $0.id == state.postID }) else {
            return
        }

        posts[index] = updating(posts[index], with: state)
    }

    public func clearError() {
        errorMessage = nil
    }

    private func updating(_ post: FeedPost, with state: PostInteractionState) -> FeedPost {
        FeedPost(
            id: post.id,
            userID: post.userID,
            title: post.title,
            content: post.content,
            postType: post.postType,
            likeCount: state.likeCount,
            commentCount: state.commentCount,
            isLiked: state.isLiked,
            createdAt: post.createdAt,
            author: post.author,
            media: post.media
        )
    }

    private func mapError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Request failed"
        }

        if let localizedError = error as? LocalizedError,
           let message = localizedError.errorDescription {
            return message
        }

        return error.localizedDescription
    }
}
