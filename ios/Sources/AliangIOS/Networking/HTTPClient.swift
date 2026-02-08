import Foundation

public protocol HTTPClientProtocol: Sendable {
    func send<R: APIRequest>(_ request: R, authToken: String?) async throws -> R.Response
}

public final class HTTPClient: HTTPClientProtocol {
    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.decoder = decoder
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let withFractional = ISO8601DateFormatter()
            withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFractional.date(from: dateString) {
                return date
            }

            let withoutFractional = ISO8601DateFormatter()
            withoutFractional.formatOptions = [.withInternetDateTime]
            if let date = withoutFractional.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }
    }

    public var configuredBaseURL: URL {
        baseURL
    }

    public func send<R: APIRequest>(_ request: R, authToken: String?) async throws -> R.Response {
        let urlRequest = try buildRequest(request, authToken: authToken)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw decodeServerError(data: data, statusCode: httpResponse.statusCode)
        }

        if R.Response.self == EmptyPayload.self,
           data.isEmpty {
            return EmptyPayload() as! R.Response
        }

        guard data.isEmpty == false else {
            throw APIError.emptyResponseData
        }

        do {
            let envelope = try decoder.decode(APIEnvelope<R.Response>.self, from: data)
            guard envelope.success else {
                throw APIError.server(
                    statusCode: httpResponse.statusCode,
                    code: envelope.code,
                    message: envelope.message
                )
            }

            guard let payload = envelope.data else {
                throw APIError.emptyResponseData
            }

            return payload
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    private func buildRequest<R: APIRequest>(_ request: R, authToken: String?) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if request.body != nil,
           request.headers.keys.contains(where: { $0.caseInsensitiveCompare("Content-Type") == .orderedSame }) == false {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if request.requiresAuth {
            guard let authToken, !authToken.isEmpty else {
                throw APIError.unauthorized
            }
            urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }

    private func decodeServerError(data: Data, statusCode: Int) -> APIError {
        guard !data.isEmpty else {
            return .server(statusCode: statusCode, code: nil, message: "Server returned an error")
        }

        if let envelope = try? decoder.decode(APIEnvelope<EmptyPayload>.self, from: data) {
            return .server(
                statusCode: statusCode,
                code: envelope.code,
                message: envelope.message ?? "Server returned an error"
            )
        }

        return .server(statusCode: statusCode, code: nil, message: "Server returned an error")
    }
}
