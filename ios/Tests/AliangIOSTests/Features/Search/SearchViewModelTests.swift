import Foundation
import XCTest
@testable import AliangIOS

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testLoadTrendingHashtags() async {
        let service = SearchServiceMock()
        service.trendingHashtagsResult = .success([
            TrendingHashtag(id: 1, name: "swift", postCount: 100),
            TrendingHashtag(id: 2, name: "ios", postCount: 80),
        ])

        let viewModel = SearchViewModel(service: service)
        await viewModel.loadTrendingHashtags()

        XCTAssertEqual(viewModel.trendingHashtags.count, 2)
        XCTAssertEqual(viewModel.trendingHashtags.first?.name, "swift")
        XCTAssertFalse(viewModel.isLoadingTrending)
    }

    func testLoadTrendingHashtagsHandlesError() async {
        let service = SearchServiceMock()
        service.trendingHashtagsResult = .failure(APIError.server(statusCode: 500, code: "TRENDING_ERROR", message: "Failed to load trending"))

        let viewModel = SearchViewModel(service: service)
        await viewModel.loadTrendingHashtags()

        XCTAssertTrue(viewModel.trendingHashtags.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Server error (500): Failed to load trending")
    }

    func testSearchPosts() async {
        let service = SearchServiceMock()
        service.searchPostsResult = .success(SearchResult(
            items: [samplePost(id: 1, title: "Search Result")],
            hasMore: false
        ))

        let viewModel = SearchViewModel(service: service)
        viewModel.searchQuery = "test query"

        await viewModel.search()

        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.title, "Search Result")
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(service.searchPostsCalls.map(\.query), ["test query"])
    }

    func testSearchTrimsWhitespaceBeforeRequest() async {
        let service = SearchServiceMock()
        service.searchPostsResult = .success(SearchResult(items: [], hasMore: false))

        let viewModel = SearchViewModel(service: service)
        viewModel.searchQuery = "   spaced query   \n"

        await viewModel.search()

        XCTAssertEqual(viewModel.searchQuery, "spaced query")
        XCTAssertEqual(service.searchPostsCalls.map(\.query), ["spaced query"])
    }

    func testSearchWhitespaceOnlySkipsRequestAndClearsResults() async {
        let service = SearchServiceMock()
        let viewModel = SearchViewModel(service: service)
        viewModel.searchQuery = "    \n"

        await viewModel.search()

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertEqual(service.searchPostsCalls.count, 0)
    }

    func testSearchWithEmptyQueryClearsResults() async {
        let service = SearchServiceMock()

        let viewModel = SearchViewModel(service: service)
        viewModel.searchQuery = "some query"
        await viewModel.search()

        viewModel.searchQuery = ""
        viewModel.clearSearch()

        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertTrue(viewModel.hasMoreSearchResults)
    }

    func testLoadMoreSearchResults() async {
        let service = SearchServiceMock()
        service.searchPostsResult = .success(SearchResult(
            items: [samplePost(id: 1)],
            hasMore: true
        ))

        let viewModel = SearchViewModel(service: service, pageSize: 10)
        viewModel.searchQuery = "test"

        await viewModel.search()

        service.searchPostsResult = .success(SearchResult(
            items: [samplePost(id: 2), samplePost(id: 3)],
            hasMore: false
        ))
        await viewModel.loadMoreSearchResults()

        XCTAssertEqual(viewModel.searchResults.count, 3)
        XCTAssertFalse(viewModel.hasMoreSearchResults)
    }

    func testLoadMoreSearchUsesNormalizedQuery() async {
        let service = SearchServiceMock()
        service.searchPostsResult = .success(SearchResult(items: [samplePost(id: 1)], hasMore: true))

        let viewModel = SearchViewModel(service: service, pageSize: 5)
        viewModel.searchQuery = "   fuzzy query   "
        await viewModel.search()

        viewModel.searchQuery = "fuzzy query   "
        service.searchPostsResult = .success(SearchResult(items: [samplePost(id: 2)], hasMore: false))
        await viewModel.loadMoreSearchResults()

        XCTAssertEqual(service.searchPostsCalls.count, 2)
        XCTAssertEqual(service.searchPostsCalls[0].query, "fuzzy query")
        XCTAssertEqual(service.searchPostsCalls[1].query, "fuzzy query")
        XCTAssertEqual(service.searchPostsCalls[1].offset, 1)
    }

    func testSelectHashtagLoadsPosts() async {
        let service = SearchServiceMock()
        service.hashtagPostsResult = .success(HashtagPostPage(
            items: [samplePost(id: 10)],
            hasMore: false
        ))

        let viewModel = SearchViewModel(service: service)
        let hashtag = TrendingHashtag(id: 1, name: "featured", postCount: 50)

        viewModel.selectHashtag(hashtag)
        await viewModel.loadHashtagPosts()

        XCTAssertEqual(viewModel.selectedHashtag, "featured")
        XCTAssertEqual(viewModel.hashtagPosts.count, 1)
        XCTAssertEqual(service.hashtagPostsCalls.count, 1)
        XCTAssertEqual(service.hashtagPostsCalls[0].name, "featured")
        XCTAssertEqual(service.hashtagPostsCalls[0].offset, 0)
        XCTAssertEqual(service.hashtagPostsCalls[0].limit, 20)
    }

    func testHashtagPostsRefresh() async {
        let service = SearchServiceMock()
        service.hashtagPostsResult = .success(HashtagPostPage(
            items: [samplePost(id: 1)],
            hasMore: true
        ))

        let viewModel = SearchViewModel(service: service, pageSize: 5)
        let hashtag = TrendingHashtag(id: 1, name: "trending")

        viewModel.selectHashtag(hashtag)
        await viewModel.loadHashtagPosts(refresh: true)

        XCTAssertEqual(viewModel.hashtagPosts.count, 1)
        XCTAssertTrue(viewModel.hasMoreHashtagPosts)
    }

    func testLoadMoreHashtagPosts() async {
        let service = SearchServiceMock()
        service.hashtagPostsResult = .success(HashtagPostPage(
            items: [samplePost(id: 1)],
            hasMore: true
        ))

        let viewModel = SearchViewModel(service: service, pageSize: 1)
        let hashtag = TrendingHashtag(id: 1, name: "popular")

        viewModel.selectHashtag(hashtag)
        await viewModel.loadHashtagPosts()

        service.hashtagPostsResult = .success(HashtagPostPage(
            items: [samplePost(id: 2)],
            hasMore: false
        ))
        await viewModel.loadMoreIfNeeded(currentPost: viewModel.hashtagPosts[0])

        XCTAssertEqual(viewModel.hashtagPosts.count, 2)
        XCTAssertFalse(viewModel.hasMoreHashtagPosts)
    }

    func testClearSearchResetsEverything() async {
        let service = SearchServiceMock()
        service.searchPostsResult = .success(SearchResult(items: [samplePost(id: 1)], hasMore: false))
        service.hashtagPostsResult = .success(HashtagPostPage(items: [], hasMore: false))

        let viewModel = SearchViewModel(service: service)
        viewModel.searchQuery = "query"
        await viewModel.search()

        viewModel.selectHashtag(TrendingHashtag(id: 1, name: "tag"))

        viewModel.clearSearch()

        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertNil(viewModel.selectedHashtag)
        XCTAssertTrue(viewModel.hashtagPosts.isEmpty)
    }

    private func samplePost(id: Int64, title: String = "Title") -> FeedPost {
        FeedPost(
            id: id,
            userID: 1,
            title: title,
            content: "Content",
            postType: "image",
            likeCount: 10,
            commentCount: 2,
            isLiked: false,
            createdAt: Date(),
            author: FeedAuthor(id: 1, nickname: "tester", avatarURL: nil),
            media: []
        )
    }
}

private final class SearchServiceMock: SearchServiceProtocol, @unchecked Sendable {
    var trendingHashtagsResult: Result<[TrendingHashtag], Error> = .success([])
    var searchPostsResult: Result<SearchResult, Error> = .failure(APIError.invalidResponse)
    var hashtagPostsResult: Result<HashtagPostPage, Error> = .failure(APIError.invalidResponse)

    private(set) var trendingHashtagsCalls: [Int] = []
    private(set) var searchPostsCalls: [(query: String, offset: Int, limit: Int)] = []
    private(set) var hashtagPostsCalls: [(name: String, offset: Int, limit: Int)] = []

    func searchPosts(query: String, offset: Int, limit: Int) async throws -> SearchResult {
        searchPostsCalls.append((query: query, offset: offset, limit: limit))
        return try searchPostsResult.get()
    }

    func getTrendingHashtags(limit: Int) async throws -> [TrendingHashtag] {
        trendingHashtagsCalls.append(limit)
        return try trendingHashtagsResult.get()
    }

    func getPostsByHashtag(name: String, offset: Int, limit: Int) async throws -> HashtagPostPage {
        hashtagPostsCalls.append((name: name, offset: offset, limit: limit))
        return try hashtagPostsResult.get()
    }
}
