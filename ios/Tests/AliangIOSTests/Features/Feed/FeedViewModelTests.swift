import Foundation
import XCTest
@testable import AliangIOS

@MainActor
final class FeedViewModelTests: XCTestCase {
    func testInitialLoadFetchesFirstPage() async {
        let service = FeedServiceMock()
        service.feedResults = [
            .success(
                FeedPage(items: [samplePost(id: 1), samplePost(id: 2)], hasMore: true)
            )
        ]

        let viewModel = FeedViewModel(service: service, pageSize: 2)

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.posts.map(\.id), [1, 2])
        XCTAssertTrue(viewModel.hasMore)
        XCTAssertEqual(service.feedCalls.count, 1)
        XCTAssertEqual(service.feedCalls.first?.offset, 0)
        XCTAssertEqual(service.feedCalls.first?.limit, 2)
    }

    func testRefreshReplacesList() async {
        let service = FeedServiceMock()
        service.feedResults = [
            .success(FeedPage(items: [samplePost(id: 1), samplePost(id: 2)], hasMore: true)),
            .success(FeedPage(items: [samplePost(id: 10), samplePost(id: 11)], hasMore: false)),
        ]

        let viewModel = FeedViewModel(service: service, pageSize: 2)

        await viewModel.loadInitial()
        await viewModel.refresh()

        XCTAssertEqual(viewModel.posts.map(\.id), [10, 11])
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertEqual(service.feedCalls.count, 2)
        XCTAssertEqual(service.feedCalls[1].offset, 0)
    }

    func testLoadMoreAppendsNextPage() async {
        let service = FeedServiceMock()
        service.feedResults = [
            .success(FeedPage(items: [samplePost(id: 1), samplePost(id: 2)], hasMore: true)),
            .success(FeedPage(items: [samplePost(id: 3)], hasMore: false)),
        ]

        let viewModel = FeedViewModel(service: service, pageSize: 2)

        await viewModel.loadInitial()
        await viewModel.loadMoreIfNeeded(currentPost: viewModel.posts[1])

        XCTAssertEqual(viewModel.posts.map(\.id), [1, 2, 3])
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertEqual(service.feedCalls.count, 2)
        XCTAssertEqual(service.feedCalls[1].offset, 2)
    }

    func testOpenPostDetailLoadsSelectedPost() async {
        let service = FeedServiceMock()
        service.detailResult = .success(samplePost(id: 9, title: "Detail", isLiked: true))

        let viewModel = FeedViewModel(service: service)

        await viewModel.openPostDetail(postID: 9)

        XCTAssertEqual(viewModel.selectedPost?.id, 9)
        XCTAssertEqual(viewModel.selectedPost?.title, "Detail")
        XCTAssertEqual(viewModel.selectedPost?.isLiked, true)
        XCTAssertEqual(service.detailCalls, [9])
    }

    func testApplyInteractionStateUpdatesListAndSelectedPost() async {
        let service = FeedServiceMock()
        service.feedResults = [
            .success(FeedPage(items: [samplePost(id: 1, isLiked: false), samplePost(id: 2)], hasMore: false))
        ]
        service.detailResult = .success(samplePost(id: 1, title: "Detail", isLiked: false))

        let viewModel = FeedViewModel(service: service)

        await viewModel.loadInitial()
        await viewModel.openPostDetail(postID: 1)

        viewModel.applyInteractionState(
            PostInteractionState(postID: 1, isLiked: true, likeCount: 11, commentCount: 5)
        )

        XCTAssertEqual(viewModel.posts.first?.id, 1)
        XCTAssertEqual(viewModel.posts.first?.isLiked, true)
        XCTAssertEqual(viewModel.posts.first?.likeCount, 11)
        XCTAssertEqual(viewModel.posts.first?.commentCount, 5)

        XCTAssertEqual(viewModel.selectedPost?.id, 1)
        XCTAssertEqual(viewModel.selectedPost?.isLiked, true)
        XCTAssertEqual(viewModel.selectedPost?.likeCount, 11)
        XCTAssertEqual(viewModel.selectedPost?.commentCount, 5)
    }

    func testApplyInteractionStateIgnoresUnknownPost() async {
        let service = FeedServiceMock()
        service.feedResults = [
            .success(FeedPage(items: [samplePost(id: 1, isLiked: false)], hasMore: false))
        ]

        let viewModel = FeedViewModel(service: service)

        await viewModel.loadInitial()

        viewModel.applyInteractionState(
            PostInteractionState(postID: 999, isLiked: true, likeCount: 100, commentCount: 80)
        )

        XCTAssertEqual(viewModel.posts.count, 1)
        XCTAssertEqual(viewModel.posts.first?.id, 1)
        XCTAssertEqual(viewModel.posts.first?.isLiked, false)
        XCTAssertEqual(viewModel.posts.first?.likeCount, 10)
        XCTAssertEqual(viewModel.posts.first?.commentCount, 2)
    }

    func testFailureSetsErrorMessage() async {
        let service = FeedServiceMock()
        service.feedResults = [
            .failure(APIError.network("offline"))
        ]

        let viewModel = FeedViewModel(service: service)

        await viewModel.loadInitial()

        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Network error: offline")
    }

    private func samplePost(id: Int64, title: String = "Title", isLiked: Bool = false) -> FeedPost {
        FeedPost(
            id: id,
            userID: 1,
            title: title,
            content: "Content \(id)",
            postType: "image",
            likeCount: 10,
            commentCount: 2,
            isLiked: isLiked,
            createdAt: Date(),
            author: FeedAuthor(id: 1, nickname: "tester", avatarURL: nil),
            media: []
        )
    }
}

private final class FeedServiceMock: FeedServiceProtocol, @unchecked Sendable {
    var feedResults: [Result<FeedPage, Error>] = []
    var detailResult: Result<FeedPost, Error> = .failure(APIError.invalidResponse)

    private(set) var feedCalls: [(offset: Int, limit: Int)] = []
    private(set) var detailCalls: [Int64] = []

    func fetchFeed(offset: Int, limit: Int) async throws -> FeedPage {
        feedCalls.append((offset: offset, limit: limit))
        guard feedResults.isEmpty == false else {
            return FeedPage(items: [], hasMore: false)
        }

        let result = feedResults.removeFirst()
        return try result.get()
    }

    func fetchPostDetail(postID: Int64) async throws -> FeedPost {
        detailCalls.append(postID)
        return try detailResult.get()
    }
}
