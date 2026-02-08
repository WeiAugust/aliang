import Foundation

public enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case emptyResponseData
    case unauthorized
    case decoding(String)
    case network(String)
    case keychain(String)
    case server(statusCode: Int, code: String?, message: String?)
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid response"
        case .emptyResponseData:
            return "Response data is empty"
        case .unauthorized:
            return "Authentication required"
        case let .decoding(message):
            return "Failed to decode response: \(message)"
        case let .network(message):
            return "Network error: \(message)"
        case let .keychain(message):
            return "Keychain error: \(message)"
        case let .server(statusCode, _, message):
            return "Server error (\(statusCode)): \(message ?? "Request failed")"
        }
    }
}
