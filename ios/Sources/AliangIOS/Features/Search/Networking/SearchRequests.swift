import Foundation

struct SearchPostsRequest: APIRequest {
    typealias Response = SearchResult

    let query: String
    let offset: Int
    let limit: Int

    var path: String { "api/v1/search" }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "offset", value: String(max(0, offset))),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
        ]
    }

    var requiresAuth: Bool { false }
}

struct GetTrendingHashtagsRequest: APIRequest {
    typealias Response = [TrendingHashtag]

    let limit: Int

    var path: String { "api/v1/hashtags/trending" }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "limit", value: String(max(1, limit)))]
    }
}

struct GetHashtagPostsRequest: APIRequest {
    typealias Response = HashtagPostPage

    let name: String
    let offset: Int
    let limit: Int

    var path: String { "api/v1/hashtags/\(name)/posts" }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "offset", value: String(max(0, offset))),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
        ]
    }

    var requiresAuth: Bool { false }
}
