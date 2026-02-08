import Foundation

public protocol AuthServiceProtocol: Sendable {
    func sendSMSCode(phone: String) async throws -> SendSMSResponse
    func verifySMSCode(phone: String, code: String) async throws -> VerifySMSResponse
}

public final class AuthService: AuthServiceProtocol {
    private let httpClient: HTTPClientProtocol

    public init(httpClient: HTTPClientProtocol) {
        self.httpClient = httpClient
    }

    public func sendSMSCode(phone: String) async throws -> SendSMSResponse {
        try await httpClient.send(SendSMSRequest(phone: phone), authToken: nil)
    }

    public func verifySMSCode(phone: String, code: String) async throws -> VerifySMSResponse {
        try await httpClient.send(VerifySMSRequest(phone: phone, code: code), authToken: nil)
    }
}
