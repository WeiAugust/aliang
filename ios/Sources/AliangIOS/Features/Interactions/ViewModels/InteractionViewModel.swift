import Foundation

@MainActor
public final class InteractionViewModel: ObservableObject {
    @Published public private(set) var state: PostInteractionState
    @Published public private(set) var comments: [InteractionComment]
    @Published public private(set) var isLoadingComments = false
    @Published public private(set) var isSubmittingComment = false
    @Published public private(set) var canLoadMoreComments = true
    @Published public private(set) var errorMessage: String?

    private let interactionService: InteractionServiceProtocol
    private let currentUserIDProvider: @Sendable () -> Int64
    private let pageSize: Int
    private var nextOffset: Int

    public init(
        interactionService: InteractionServiceProtocol,
        initialState: PostInteractionState,
        initialComments: [InteractionComment] = [],
        pageSize: Int = 20,
        currentUserIDProvider: @escaping @Sendable () -> Int64
    ) {
        self.interactionService = interactionService
        self.state = initialState
        self.comments = initialComments
        self.pageSize = max(1, pageSize)
        self.currentUserIDProvider = currentUserIDProvider
        self.nextOffset = initialComments.count
        self.canLoadMoreComments = initialComments.count.isMultiple(of: self.pageSize)
    }

    public func clearError() {
        errorMessage = nil
    }

    public func toggleLike() async {
        guard !state.isLikeUpdating else {
            return
        }

        clearError()
        let rollbackState = state

        state.isLikeUpdating = true
        if state.isLiked {
            state.isLiked = false
            state.likeCount = max(0, state.likeCount - 1)
        } else {
            state.isLiked = true
            state.likeCount += 1
        }

        do {
            let result = try await interactionService.toggleLike(postID: state.postID)
            state.isLiked = result.isLiked
            state.likeCount = max(0, result.likeCount ?? state.likeCount)
            state.isLikeUpdating = false
        } catch {
            state = rollbackState
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    public func loadInitialComments(forceRefresh: Bool = false) async {
        if forceRefresh {
            comments = []
            nextOffset = 0
            canLoadMoreComments = true
        }

        await loadMoreCommentsIfNeeded()
    }

    public func loadMoreCommentsIfNeeded() async {
        guard !isLoadingComments, canLoadMoreComments else {
            return
        }

        clearError()
        isLoadingComments = true
        defer { isLoadingComments = false }

        do {
            let page = try await interactionService.listComments(
                postID: state.postID,
                offset: nextOffset,
                limit: pageSize
            )

            if nextOffset == 0 {
                comments = page.items
            } else {
                comments.append(contentsOf: page.items)
            }

            nextOffset += page.items.count
            canLoadMoreComments = page.hasMore
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    public func submitComment(content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = InteractionFeatureError.emptyComment.errorDescription
            return
        }

        guard !isSubmittingComment else {
            return
        }

        clearError()
        isSubmittingComment = true
        defer { isSubmittingComment = false }

        let rollbackComments = comments
        let rollbackCount = state.commentCount
        let pendingID = nextPendingCommentID()

        comments.insert(
            InteractionComment(
                id: pendingID,
                postID: state.postID,
                userID: currentUserIDProvider(),
                content: trimmed,
                createdAt: Date(),
                isPending: true
            ),
            at: 0
        )
        state.commentCount += 1

        do {
            let created = try await interactionService.createComment(postID: state.postID, content: trimmed)

            if let index = comments.firstIndex(where: { $0.id == pendingID }) {
                comments[index] = created
            } else {
                comments.insert(created, at: 0)
            }
        } catch {
            comments = rollbackComments
            state.commentCount = rollbackCount
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func nextPendingCommentID() -> Int64 {
        -Int64(Date().timeIntervalSince1970 * 1000)
    }
}
