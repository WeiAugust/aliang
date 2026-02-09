import Foundation

public struct FeedAuthor: Decodable, Equatable, Sendable {
    public let id: Int64
    public let nickname: String
    public let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case avatarURL = "avatar_url"
    }

    public init(id: Int64, nickname: String, avatarURL: String?) {
        self.id = id
        self.nickname = nickname
        self.avatarURL = avatarURL
    }
}

public struct FeedMedia: Decodable, Equatable, Sendable, Identifiable {
    public let id: Int64
    public let mediaURL: String
    public let thumbnailURL: String?
    public let mediaType: String

    public var displayURL: String {
        thumbnailURL ?? mediaURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case mediaURL = "media_url"
        case thumbnailURL = "thumbnail_url"
        case mediaType = "media_type"
    }

    public init(id: Int64, mediaURL: String, thumbnailURL: String?, mediaType: String) {
        self.id = id
        self.mediaURL = FeedMedia.normalizedRemoteURL(mediaURL)
        self.thumbnailURL = FeedMedia.normalizedOptionalRemoteURL(thumbnailURL)
        self.mediaType = mediaType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)

        let rawMediaURL = try container.decode(String.self, forKey: .mediaURL)
        let rawThumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)

        mediaURL = FeedMedia.normalizedRemoteURL(rawMediaURL)
        thumbnailURL = FeedMedia.normalizedOptionalRemoteURL(rawThumbnailURL)
        mediaType = try container.decode(String.self, forKey: .mediaType)
    }

    private static func normalizedOptionalRemoteURL(_ value: String?) -> String? {
        guard let value else { return nil }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        return normalizedRemoteURL(trimmed)
    }

    private static func normalizedRemoteURL(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return value }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }

        if trimmed.hasPrefix("//") {
            let baseScheme = RemoteMediaURLResolver.baseURL.scheme ?? "http"
            return "\(baseScheme):\(trimmed)"
        }

        if trimmed.hasPrefix("/") {
            return RemoteMediaURLResolver.resolve(relativePath: trimmed) ?? trimmed
        }

        let baseScheme = RemoteMediaURLResolver.baseURL.scheme ?? "http"
        return "\(baseScheme)://\(trimmed)"
    }
}

public struct FeedPost: Decodable, Equatable, Sendable, Identifiable {
    public let id: Int64
    public let userID: Int64
    public let title: String
    public let content: String
    public let postType: String
    public let likeCount: Int
    public let commentCount: Int
    public let isLiked: Bool
    public let createdAt: Date
    public let author: FeedAuthor?
    public let media: [FeedMedia]

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case content
        case postType = "post_type"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case isLiked = "is_liked"
        case createdAt = "created_at"
        case user
        case media
    }

    public init(
        id: Int64,
        userID: Int64,
        title: String,
        content: String,
        postType: String,
        likeCount: Int,
        commentCount: Int,
        isLiked: Bool = false,
        createdAt: Date,
        author: FeedAuthor?,
        media: [FeedMedia]
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.content = content
        self.postType = postType
        self.likeCount = max(0, likeCount)
        self.commentCount = max(0, commentCount)
        self.isLiked = isLiked
        self.createdAt = createdAt
        self.author = author
        self.media = media
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int64.self, forKey: .id)
        userID = try container.decode(Int64.self, forKey: .userID)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        postType = try container.decode(String.self, forKey: .postType)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        media = try container.decodeIfPresent([FeedMedia].self, forKey: .media) ?? []
        author = try container.decodeIfPresent(FeedAuthor.self, forKey: .user)

        if let parsed = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = parsed
        } else if let raw = try container.decodeIfPresent(String.self, forKey: .createdAt),
                  let parsed = ISO8601DateFormatter.withFractionalSeconds.date(from: raw)
                      ?? ISO8601DateFormatter().date(from: raw) {
            createdAt = parsed
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt,
                in: container,
                debugDescription: "Invalid created_at format"
            )
        }
    }
}

public struct FeedPage: Decodable, Equatable, Sendable {
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

private extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
