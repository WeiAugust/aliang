import Foundation
import XCTest
@testable import AliangIOS

@MainActor
final class SearchRenderTests: XCTestCase {
    func testSearchViewModelInitialState() {
        let service = SearchServiceMock()
        let viewModel = SearchViewModel(service: service)

        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertTrue(viewModel.trendingHashtags.isEmpty)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertTrue(viewModel.hashtagPosts.isEmpty)
        XCTAssertNil(viewModel.selectedHashtag)
        XCTAssertFalse(viewModel.isLoadingTrending)
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSearchViewModelClearSearch() {
        let service = SearchServiceMock()
        let viewModel = SearchViewModel(service: service)

        viewModel.searchQuery = "test"
        viewModel.clearSearch()

        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.selectedHashtag)
        XCTAssertTrue(viewModel.hashtagPosts.isEmpty)
    }

    func testSearchViewModelSelectHashtag() async {
        let service = SearchServiceMock()
        service.hashtagPostsResult = .success(HashtagPostPage(items: [], hasMore: false))

        let viewModel = SearchViewModel(service: service)
        let hashtag = TrendingHashtag(id: 1, name: "trending", postCount: 100)

        viewModel.selectHashtag(hashtag)

        XCTAssertEqual(viewModel.selectedHashtag, "trending")
    }

    func testSearchViewModelClearError() {
        let service = SearchServiceMock()
        service.trendingHashtagsResult = .failure(APIError.server(statusCode: 500, code: "ERROR", message: "Test error"))

        let viewModel = SearchViewModel(service: service)

        let expectation = XCTestExpectation(description: "Error loaded")
        Task {
            await viewModel.loadTrendingHashtags()
            XCTAssertNotNil(viewModel.errorMessage)

            viewModel.clearError()
            XCTAssertNil(viewModel.errorMessage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

private final class SearchServiceMock: SearchServiceProtocol, @unchecked Sendable {
    var trendingHashtagsResult: Result<[TrendingHashtag], Error> = .success([])
    var searchPostsResult: Result<SearchResult, Error> = .failure(APIError.invalidResponse)
    var hashtagPostsResult: Result<HashtagPostPage, Error> = .failure(APIError.invalidResponse)

    func searchPosts(query: String, offset: Int, limit: Int) async throws -> SearchResult {
        return try searchPostsResult.get()
    }

    func getTrendingHashtags(limit: Int) async throws -> [TrendingHashtag] {
        return try trendingHashtagsResult.get()
    }

    func getPostsByHashtag(name: String, offset: Int, limit: Int) async throws -> HashtagPostPage {
        return try hashtagPostsResult.get()
    }
}
