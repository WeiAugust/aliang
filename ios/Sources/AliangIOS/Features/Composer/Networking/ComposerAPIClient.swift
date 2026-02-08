import Foundation

public protocol ComposerTokenProvider: Sendable {
    func authToken() -> String?
}

public struct StaticComposerTokenProvider: ComposerTokenProvider {
    public let token: String?

    public init(token: String?) {
        self.token = token
    }

    public func authToken() -> String? {
        token
    }
}

public protocol ComposerAPIClient: Sendable {
    func uploadImage(
        fileName: String,
        data: Data,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadedMediaResource

    func uploadVideo(
        fileName: String,
        data: Data,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadedMediaResource

    func createPost(payload: CreatePostPayload) async throws -> PublishedPost
}

public enum ComposerNetworkError: Error, Equatable, LocalizedError {
    case missingAuthToken
    case invalidResponse
    case server(statusCode: Int, message: String)
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .missingAuthToken:
            return "Missing auth token"
        case .invalidResponse:
            return "Invalid server response"
        case .server(let statusCode, let message):
            return "Server returned \(statusCode): \(message)"
        case .decodingFailed:
            return "Failed to decode server response"
        }
    }
}

public final class URLSessionComposerAPIClient: ComposerAPIClient, @unchecked Sendable {
    private struct APIEnvelope<T: Decodable>: Decodable {
        let success: Bool
        let data: T?
        let error: APIErrorPayload?
        let message: String?
    }

    private struct APIErrorPayload: Decodable {
        let code: String
        let message: String
    }

    private struct UploadDataResponse: Decodable {
        let url: String
        let thumbnailURL: String?

        enum CodingKeys: String, CodingKey {
            case url
            case thumbnailURL = "thumbnail_url"
        }
    }

    private struct CreatePostResponse: Decodable {
        let id: Int64
    }

    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: any ComposerTokenProvider
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

    public init(baseURL: URL, session: URLSession = .shared, tokenProvider: some ComposerTokenProvider) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    public func uploadImage(
        fileName: String,
        data: Data,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadedMediaResource {
        let uploadData = try await uploadMultipart(
            endpointPath: "/api/v1/upload/image",
            fileName: fileName,
            mimeType: mimeType(fileName: fileName, mediaType: .image),
            data: data,
            onProgress: onProgress
        )
        return UploadedMediaResource(url: uploadData.url, thumbnailURL: uploadData.thumbnailURL, mediaType: .image)
    }

    public func uploadVideo(
        fileName: String,
        data: Data,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadedMediaResource {
        let uploadData = try await uploadMultipart(
            endpointPath: "/api/v1/upload/video",
            fileName: fileName,
            mimeType: mimeType(fileName: fileName, mediaType: .video),
            data: data,
            onProgress: onProgress
        )
        return UploadedMediaResource(url: uploadData.url, thumbnailURL: uploadData.thumbnailURL, mediaType: .video)
    }

    public func createPost(payload: CreatePostPayload) async throws -> PublishedPost {
        let endpoint = try makeURL(path: "/api/v1/posts")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let token = tokenProvider.authToken(), !token.isEmpty else {
            throw ComposerNetworkError.missingAuthToken
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try jsonEncoder.encode(payload)
        } catch {
            throw ComposerNetworkError.invalidResponse
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ComposerNetworkError.invalidResponse
        }

        let envelope = try decodeEnvelope(CreatePostResponse.self, from: data)
        guard (200 ... 299).contains(httpResponse.statusCode), envelope.success, let createResponse = envelope.data else {
            throw mapServerError(statusCode: httpResponse.statusCode, envelopeMessage: envelope.message)
        }

        return PublishedPost(id: createResponse.id)
    }

    private func uploadMultipart(
        endpointPath: String,
        fileName: String,
        mimeType: String,
        data: Data,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> UploadDataResponse {
        let endpoint = try makeURL(path: endpointPath)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"

        guard let token = tokenProvider.authToken(), !token.isEmpty else {
            throw ComposerNetworkError.missingAuthToken
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = makeMultipartBody(boundary: boundary, fileName: fileName, mimeType: mimeType, data: data)

        onProgress(0.1)
        let (responseData, response) = try await session.data(for: request)
        onProgress(1.0)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ComposerNetworkError.invalidResponse
        }

        let envelope = try decodeEnvelope(UploadDataResponse.self, from: responseData)
        guard (200 ... 299).contains(httpResponse.statusCode), envelope.success, let uploadData = envelope.data else {
            throw mapServerError(statusCode: httpResponse.statusCode, envelopeMessage: envelope.message)
        }

        return uploadData
    }

    private func makeURL(path: String) throws -> URL {
        guard let endpoint = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw ComposerNetworkError.invalidResponse
        }
        return endpoint
    }

    private func makeMultipartBody(boundary: String, fileName: String, mimeType: String, data: Data) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func decodeEnvelope<T: Decodable>(_ type: T.Type, from data: Data) throws -> APIEnvelope<T> {
        do {
            return try jsonDecoder.decode(APIEnvelope<T>.self, from: data)
        } catch {
            throw ComposerNetworkError.decodingFailed
        }
    }

    private func mapServerError(statusCode: Int, envelopeMessage: String?) -> ComposerNetworkError {
        .server(statusCode: statusCode, message: envelopeMessage ?? "request failed")
    }

    private func mimeType(fileName: String, mediaType: ComposerMediaType) -> String {
        switch mediaType {
        case .image:
            if fileName.lowercased().hasSuffix(".png") { return "image/png" }
            if fileName.lowercased().hasSuffix(".gif") { return "image/gif" }
            if fileName.lowercased().hasSuffix(".webp") { return "image/webp" }
            return "image/jpeg"
        case .video:
            if fileName.lowercased().hasSuffix(".mov") { return "video/quicktime" }
            if fileName.lowercased().hasSuffix(".webm") { return "video/webm" }
            return "video/mp4"
        }
    }
}
