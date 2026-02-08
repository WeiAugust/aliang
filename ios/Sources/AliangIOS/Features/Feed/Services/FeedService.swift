import Foundation

public protocol FeedServiceProtocol: Sendable {
    func fetchFeed(offset: Int, limit: Int) async throws -> FeedPage
    func fetchPostDetail(postID: Int64) async throws -> FeedPost
}

public final class FeedService: FeedServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let tokenProvider: @Sendable () -> String?

    public init(
        httpClient: HTTPClientProtocol,
        tokenProvider: @escaping @Sendable () -> String? = { nil }
    ) {
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
    }

    public func fetchFeed(offset: Int, limit: Int) async throws -> FeedPage {
        try await httpClient.send(
            ListFeedRequest(offset: offset, limit: limit),
            authToken: tokenProvider()
        )
    }

    public func fetchPostDetail(postID: Int64) async throws -> FeedPost {
        try await httpClient.send(
            PostDetailRequest(postID: postID),
            authToken: tokenProvider()
        )
    }
}
