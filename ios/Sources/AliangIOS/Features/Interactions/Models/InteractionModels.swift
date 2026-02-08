import Foundation

public struct PostInteractionState: Equatable, Sendable {
    public let postID: Int64
    public var isLiked: Bool
    public var likeCount: Int
    public var commentCount: Int
    public var isLikeUpdating: Bool

    public init(
        postID: Int64,
        isLiked: Bool,
        likeCount: Int,
        commentCount: Int,
        isLikeUpdating: Bool = false
    ) {
        self.postID = postID
        self.isLiked = isLiked
        self.likeCount = max(0, likeCount)
        self.commentCount = max(0, commentCount)
        self.isLikeUpdating = isLikeUpdating
    }
}

public struct ToggleLikeResponse: Decodable, Equatable, Sendable {
    public let isLiked: Bool
    public let likeCount: Int?

    enum CodingKeys: String, CodingKey {
        case isLiked = "is_liked"
        case likeCount = "like_count"
    }

    public init(isLiked: Bool, likeCount: Int? = nil) {
        self.isLiked = isLiked
        self.likeCount = likeCount
    }
}

public struct InteractionComment: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let postID: Int64
    public let userID: Int64
    public let content: String
    public let createdAt: Date
    public let isPending: Bool

    public init(
        id: Int64,
        postID: Int64,
        userID: Int64,
        content: String,
        createdAt: Date,
        isPending: Bool = false
    ) {
        self.id = id
        self.postID = postID
        self.userID = userID
        self.content = content
        self.createdAt = createdAt
        self.isPending = isPending
    }
}

public struct CommentPage: Equatable, Sendable {
    public let items: [InteractionComment]
    public let hasMore: Bool

    public init(items: [InteractionComment], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}
