import Foundation

public struct UserProfile: Decodable, Equatable, Sendable, Identifiable {
    public let id: Int64
    public let phone: String?
    public let nickname: String
    public let avatarURL: String?
    public let bio: String?
    public let postCount: Int
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case nickname
        case avatarURL = "avatar_url"
        case bio
        case postCount = "post_count"
        case createdAt = "created_at"
    }

    public init(
        id: Int64,
        phone: String? = nil,
        nickname: String,
        avatarURL: String? = nil,
        bio: String? = nil,
        postCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.phone = phone
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.bio = bio
        self.postCount = postCount
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int64.self, forKey: .id)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        nickname = try container.decode(String.self, forKey: .nickname)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        postCount = try container.decodeIfPresent(Int.self, forKey: .postCount) ?? 0

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let parsed = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = parsed
        } else if let raw = try container.decodeIfPresent(String.self, forKey: .createdAt),
                  let parsed = formatter.date(from: raw)
                      ?? ISO8601DateFormatter().date(from: raw) {
            createdAt = parsed
        } else {
            createdAt = Date()
        }
    }
}

public struct UserPostPage: Decodable, Equatable, Sendable {
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

public struct UpdateProfileRequest: Encodable, Decodable {
    public let nickname: String?
    public let avatarURL: String?
    public let bio: String?

    public init(nickname: String? = nil, avatarURL: String? = nil, bio: String? = nil) {
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.bio = bio
    }

    enum CodingKeys: String, CodingKey {
        case nickname
        case avatarURL = "avatar_url"
        case bio
    }
}
