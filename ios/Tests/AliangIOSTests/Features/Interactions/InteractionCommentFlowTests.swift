import Foundation
import XCTest

@testable import AliangIOS

@MainActor
final class InteractionCommentFlowTests: XCTestCase {
    func testSubmitCommentRejectEmpty() async {
        let service = CommentFlowServiceMock()
        let viewModel = InteractionViewModel(
            interactionService: service,
            initialState: PostInteractionState(postID: 8, isLiked: false, likeCount: 0, commentCount: 0),
            currentUserIDProvider: { 88 }
        )

        await viewModel.submitComment(content: "   ")

        XCTAssertTrue(viewModel.comments.isEmpty)
        XCTAssertEqual(viewModel.state.commentCount, 0)
        XCTAssertEqual(viewModel.errorMessage, InteractionFeatureError.emptyComment.errorDescription)
    }

    func testSubmitCommentRollback() async {
        let service = CommentFlowServiceMock()
        await service.setCreateCommentResult(.failure(InteractionFeatureError.server(message: "create failed")))

        let existing = InteractionComment(id: 200, postID: 8, userID: 2, content: "existing", createdAt: Date())
        let viewModel = InteractionViewModel(
            interactionService: service,
            initialState: PostInteractionState(postID: 8, isLiked: false, likeCount: 0, commentCount: 1),
            initialComments: [existing],
            currentUserIDProvider: { 88 }
        )

        await viewModel.submitComment(content: "new")

        XCTAssertEqual(viewModel.comments, [existing])
        XCTAssertEqual(viewModel.state.commentCount, 1)
        XCTAssertEqual(viewModel.errorMessage, "create failed")
    }

    func testSubmitCommentSuccess() async {
        let service = CommentFlowServiceMock()
        let created = InteractionComment(id: 300, postID: 8, userID: 88, content: "hello", createdAt: Date())
        await service.setCreateCommentResult(.success(created))

        let viewModel = InteractionViewModel(
            interactionService: service,
            initialState: PostInteractionState(postID: 8, isLiked: false, likeCount: 0, commentCount: 0),
            currentUserIDProvider: { 88 }
        )

        await viewModel.submitComment(content: " hello ")

        XCTAssertEqual(viewModel.comments.count, 1)
        XCTAssertEqual(viewModel.comments.first?.id, 300)
        XCTAssertEqual(viewModel.comments.first?.isPending, false)
        XCTAssertEqual(viewModel.state.commentCount, 1)
        XCTAssertNil(viewModel.errorMessage)

        let calls = await service.createCommentCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.content, "hello")
    }
}

private actor CommentFlowServiceMock: InteractionServiceProtocol {
    private var createCommentResult: Result<InteractionComment, Error> = .failure(InteractionFeatureError.invalidResponse)
    private(set) var createCommentCalls: [(postID: Int64, content: String)] = []

    func setCreateCommentResult(_ value: Result<InteractionComment, Error>) {
        createCommentResult = value
    }

    func toggleLike(postID: Int64) async throws -> ToggleLikeResponse {
        _ = postID
        return ToggleLikeResponse(isLiked: true, likeCount: 1)
    }

    func listComments(postID: Int64, offset: Int, limit: Int) async throws -> CommentPage {
        _ = postID
        _ = offset
        _ = limit
        return CommentPage(items: [], hasMore: false)
    }

    func createComment(postID: Int64, content: String) async throws -> InteractionComment {
        createCommentCalls.append((postID: postID, content: content))
        return try createCommentResult.get()
    }
}
