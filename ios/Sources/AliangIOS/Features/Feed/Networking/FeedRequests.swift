import Foundation

struct ListFeedRequest: APIRequest {
    typealias Response = FeedPage

    let offset: Int
    let limit: Int

    var path: String { "api/v1/posts" }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "offset", value: String(max(0, offset))),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
        ]
    }
}

struct PostDetailRequest: APIRequest {
    typealias Response = FeedPost

    let postID: Int64

    var path: String { "api/v1/posts/\(postID)" }
}
