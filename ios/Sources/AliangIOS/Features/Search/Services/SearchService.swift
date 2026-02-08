import Foundation

public protocol SearchServiceProtocol: Sendable {
    func searchPosts(query: String, offset: Int, limit: Int) async throws -> SearchResult
    func getTrendingHashtags(limit: Int) async throws -> [TrendingHashtag]
    func getPostsByHashtag(name: String, offset: Int, limit: Int) async throws -> HashtagPostPage
}

public final class SearchService: SearchServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let tokenProvider: @Sendable () -> String?

    public init(
        httpClient: HTTPClientProtocol,
        tokenProvider: @escaping @Sendable () -> String? = { nil }
    ) {
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
    }

    public func searchPosts(query: String, offset: Int, limit: Int) async throws -> SearchResult {
        try await httpClient.send(
            SearchPostsRequest(query: query, offset: offset, limit: limit),
            authToken: tokenProvider()
        )
    }

    public func getTrendingHashtags(limit: Int) async throws -> [TrendingHashtag] {
        try await httpClient.send(
            GetTrendingHashtagsRequest(limit: limit),
            authToken: tokenProvider()
        )
    }

    public func getPostsByHashtag(name: String, offset: Int, limit: Int) async throws -> HashtagPostPage {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return try await httpClient.send(
            GetHashtagPostsRequest(name: encodedName, offset: offset, limit: limit),
            authToken: tokenProvider()
        )
    }
}
