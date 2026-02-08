import Foundation

struct GetMyProfileRequest: APIRequest {
    typealias Response = UserProfile

    var path: String { "api/v1/users/me" }
    var requiresAuth: Bool { true }
}

struct GetUserProfileRequest: APIRequest {
    typealias Response = UserProfile

    let userID: Int64

    var path: String { "api/v1/users/\(userID)" }
    var requiresAuth: Bool { true }
}

struct GetUserPostsRequest: APIRequest {
    typealias Response = UserPostPage

    let userID: Int64
    let offset: Int
    let limit: Int

    var path: String { "api/v1/users/\(userID)/posts" }

    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "offset", value: String(max(0, offset))),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
        ]
    }

    var requiresAuth: Bool { true }
}

struct UpdateProfileRequestWrapper: APIRequest {
    typealias Response = UserProfile

    let payload: UpdateProfileRequest

    var path: String { "api/v1/users/me" }
    var method: HTTPMethod { .patch }
    var requiresAuth: Bool { true }

    var body: Data? {
        try? JSONEncoder().encode(payload)
    }
}
