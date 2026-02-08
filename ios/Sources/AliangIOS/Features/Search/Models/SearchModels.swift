import Foundation

public struct SearchResult: Decodable, Equatable, Sendable {
    public let items: [FeedPost]
    public let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case hasMore = "has_more"
    }

    public init(items: [FeedPost], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}

public struct TrendingHashtag: Decodable, Equatable, Sendable, Identifiable {
    public let id: Int64
    public let name: String
    public let postCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case postCount = "post_count"
    }

    public init(id: Int64, name: String, postCount: Int? = nil) {
        self.id = id
        self.name = name
        self.postCount = postCount
    }
}

public struct HashtagPostPage: Decodable, Equatable, Sendable {
    public let items: [FeedPost]
    public let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case hasMore = "has_more"
    }

    public init(items: [FeedPost], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}
