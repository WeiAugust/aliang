import Foundation

public struct APIEnvelope<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let message: String?
    public let code: String?
    public let error: APIEnvelopeError?

    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case code
        case errorCode = "error_code"
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
        data = try container.decodeIfPresent(T.self, forKey: .data)
        error = try container.decodeIfPresent(APIEnvelopeError.self, forKey: .error)

        if let nestedError = error {
            let fallbackMessage = try container.decodeIfPresent(String.self, forKey: .message)
            let fallbackCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
                ?? container.decodeIfPresent(String.self, forKey: .code)
            message = nestedError.message ?? fallbackMessage
            code = nestedError.code ?? fallbackCode
        } else {
            message = try container.decodeIfPresent(String.self, forKey: .message)
            code = try container.decodeIfPresent(String.self, forKey: .errorCode)
                ?? container.decodeIfPresent(String.self, forKey: .code)
        }
    }
}

public struct APIEnvelopeError: Decodable {
    public let code: String?
    public let message: String?

    public init(code: String?, message: String?) {
        self.code = code
        self.message = message
    }
}
