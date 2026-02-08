import Foundation

public protocol InteractionServiceProtocol {
    func toggleLike(postID: Int64) async throws -> ToggleLikeResponse
    func listComments(postID: Int64, offset: Int, limit: Int) async throws -> CommentPage
    func createComment(postID: Int64, content: String) async throws -> InteractionComment
}

public enum InteractionFeatureError: Error, Equatable, LocalizedError {
    case unauthorized
    case emptyComment
    case invalidResponse
    case server(message: String)
    case network(message: String)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Authentication required"
        case .emptyComment:
            return "Comment content cannot be empty"
        case .invalidResponse:
            return "Invalid server response"
        case .server(let message):
            return message
        case .network(let message):
            return message
        }
    }
}

public final class InteractionService: InteractionServiceProtocol {
    private struct ToggleLikeRequest: APIRequest {
        typealias Response = ToggleLikeResponse

        let postID: Int64
        var path: String { "api/v1/posts/\(postID)/like" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
    }

    private struct ListCommentsRequest: APIRequest {
        typealias Response = ListCommentsPayload

        let postID: Int64
        let offset: Int
        let limit: Int

        var path: String { "api/v1/posts/\(postID)/comments" }
        var requiresAuth: Bool { true }
        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "offset", value: String(offset)),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        }
    }

    private struct CreateCommentRequest: APIRequest {
        typealias Response = CommentPayload

        let postID: Int64
        let content: String

        var path: String { "api/v1/posts/\(postID)/comments" }
        var method: HTTPMethod { .post }
        var requiresAuth: Bool { true }
        var headers: [String: String] { ["Content-Type": "application/json"] }
        var body: Data? { try? JSONEncoder().encode(Payload(content: content)) }

        private struct Payload: Encodable {
            let content: String
        }
    }

    private struct ListCommentsPayload: Decodable {
        let items: [CommentPayload]
        let hasMore: Bool

        enum CodingKeys: String, CodingKey {
            case items
            case hasMore = "has_more"
        }
    }

    private struct CommentPayload: Decodable {
        let id: Int64
        let userID: Int64
        let postID: Int64?
        let content: String
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userID = "user_id"
            case postID = "post_id"
            case content
            case createdAt = "created_at"
        }
    }

    private let httpClient: HTTPClientProtocol
    private let tokenProvider: @Sendable () -> String?

    public init(
        httpClient: HTTPClientProtocol,
        tokenProvider: @escaping @Sendable () -> String?
    ) {
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
    }

    public func toggleLike(postID: Int64) async throws -> ToggleLikeResponse {
        do {
            return try await httpClient.send(ToggleLikeRequest(postID: postID), authToken: tokenProvider())
        } catch {
            throw mapError(error)
        }
    }

    public func listComments(postID: Int64, offset: Int, limit: Int) async throws -> CommentPage {
        do {
            let payload = try await httpClient.send(
                ListCommentsRequest(postID: postID, offset: max(0, offset), limit: max(1, limit)),
                authToken: tokenProvider()
            )

            return CommentPage(
                items: payload.items.map { item in
                    InteractionComment(
                        id: item.id,
                        postID: item.postID ?? postID,
                        userID: item.userID,
                        content: item.content,
                        createdAt: item.createdAt
                    )
                },
                hasMore: payload.hasMore
            )
        } catch {
            throw mapError(error)
        }
    }

    public func createComment(postID: Int64, content: String) async throws -> InteractionComment {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw InteractionFeatureError.emptyComment
        }

        do {
            let payload = try await httpClient.send(
                CreateCommentRequest(postID: postID, content: trimmed),
                authToken: tokenProvider()
            )

            return InteractionComment(
                id: payload.id,
                postID: payload.postID ?? postID,
                userID: payload.userID,
                content: payload.content,
                createdAt: payload.createdAt
            )
        } catch {
            throw mapError(error)
        }
    }

    private func mapError(_ error: Error) -> InteractionFeatureError {
        if let interactionError = error as? InteractionFeatureError {
            return interactionError
        }

        guard let apiError = error as? APIError else {
            return .network(message: error.localizedDescription)
        }

        switch apiError {
        case .unauthorized:
            return .unauthorized
        case .invalidURL, .invalidResponse, .emptyResponseData, .decoding(_):
            return .invalidResponse
        case .server(_, _, let message):
            return .server(message: message ?? "Request failed")
        case .network(let message):
            return .network(message: message)
        case .keychain(let message):
            return .network(message: message)
        }
    }
}
