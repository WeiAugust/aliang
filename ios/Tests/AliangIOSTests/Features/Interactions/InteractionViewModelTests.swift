import Foundation
import XCTest

@testable import AliangIOS

@MainActor
final class InteractionViewModelTests: XCTestCase {
    func testToggleLikeRollback() async {
        let service = InteractionServiceMock()
        await service.setToggleLikeResult(.failure(InteractionFeatureError.server(message: "toggle failed")))

        let viewModel = InteractionViewModel(
            interactionService: service,
            initialState: PostInteractionState(postID: 1, isLiked: false, likeCount: 5, commentCount: 2),
            currentUserIDProvider: { 10 }
        )

        await viewModel.toggleLike()

        XCTAssertEqual(viewModel.state.isLiked, false)
        XCTAssertEqual(viewModel.state.likeCount, 5)
        XCTAssertEqual(viewModel.state.isLikeUpdating, false)
        XCTAssertEqual(viewModel.errorMessage, "toggle failed")
    }

    func testToggleLikeSuccess() async {
        let service = InteractionServiceMock()
        await service.setToggleLikeResult(.success(ToggleLikeResponse(isLiked: true, likeCount: 7)))

        let viewModel = InteractionViewModel(
            interactionService: service,
            initialState: PostInteractionState(postID: 1, isLiked: false, likeCount: 5, commentCount: 2),
            currentUserIDProvider: { 10 }
        )

        await viewModel.toggleLike()

        XCTAssertEqual(viewModel.state.isLiked, true)
        XCTAssertEqual(viewModel.state.likeCount, 7)
        XCTAssertNil(viewModel.errorMessage)

        let calls = await service.toggleLikeCalls
        XCTAssertEqual(calls, [1])
    }

    func testCommentPagination() async {
        let service = InteractionServiceMock()
        let now = Date()

        await service.setCommentPages([
            .success(
                CommentPage(
                    items: [
                        InteractionComment(id: 1, postID: 1, userID: 2, content: "c1", createdAt: now),
                        InteractionComment(id: 2, postID: 1, userID: 3, content: "c2", createdAt: now),
                    ],
                    hasMore: true
                )
            ),
            .success(
                CommentPage(
                    items: [
                        InteractionComment(id: 3, postID: 1, userID: 4, content: "c3", createdAt: now),
                    ],
                    hasMore: false
                )
            ),
        ])

        let viewModel = InteractionViewModel(
            interactionService: service,
            initialState: PostInteractionState(postID: 1, isLiked: false, likeCount: 0, commentCount: 0),
            pageSize: 2,
            currentUserIDProvider: { 10 }
        )

        await viewModel.loadInitialComments()
        XCTAssertEqual(viewModel.comments.map(\.id), [1, 2])
        XCTAssertEqual(viewModel.canLoadMoreComments, true)

        await viewModel.loadMoreCommentsIfNeeded()
        XCTAssertEqual(viewModel.comments.map(\.id), [1, 2, 3])
        XCTAssertEqual(viewModel.canLoadMoreComments, false)

        let calls = await service.listCommentsCalls
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].offset, 0)
        XCTAssertEqual(calls[1].offset, 2)
    }
}

private actor InteractionServiceMock: InteractionServiceProtocol {
    private(set) var toggleLikeCalls: [Int64] = []
    private(set) var listCommentsCalls: [(postID: Int64, offset: Int, limit: Int)] = []

    private var toggleLikeResult: Result<ToggleLikeResponse, Error> = .success(ToggleLikeResponse(isLiked: true, likeCount: 1))
    private var commentPages: [Result<CommentPage, Error>] = []

    func setToggleLikeResult(_ value: Result<ToggleLikeResponse, Error>) {
        toggleLikeResult = value
    }

    func setCommentPages(_ pages: [Result<CommentPage, Error>]) {
        commentPages = pages
    }

    func toggleLike(postID: Int64) async throws -> ToggleLikeResponse {
        toggleLikeCalls.append(postID)
        return try toggleLikeResult.get()
    }

    func listComments(postID: Int64, offset: Int, limit: Int) async throws -> CommentPage {
        listCommentsCalls.append((postID: postID, offset: offset, limit: limit))
        if commentPages.isEmpty {
            return CommentPage(items: [], hasMore: false)
        }

        return try commentPages.removeFirst().get()
    }

    func createComment(postID: Int64, content: String) async throws -> InteractionComment {
        _ = postID
        _ = content
        throw InteractionFeatureError.invalidResponse
    }
}
