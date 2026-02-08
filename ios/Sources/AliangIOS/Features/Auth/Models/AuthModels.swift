import Foundation

public struct SendSMSRequestBody: Encodable, Equatable, Sendable {
    public let phone: String

    public init(phone: String) {
        self.phone = phone
    }
}

public struct VerifySMSRequestBody: Encodable, Equatable, Sendable {
    public let phone: String
    public let code: String

    public init(phone: String, code: String) {
        self.phone = phone
        self.code = code
    }
}

public struct SendSMSResponse: Decodable, Equatable, Sendable {
    public let code: String?
    public let expiresAt: String?
    public let phone: String?

    enum CodingKeys: String, CodingKey {
        case code
        case expiresAt = "expires_at"
        case phone
    }

    public init(code: String?, expiresAt: String?, phone: String? = nil) {
        self.code = code
        self.expiresAt = expiresAt
        self.phone = phone
    }
}

public struct AuthUser: Decodable, Equatable, Sendable {
    public let id: Int64
    public let phone: String
    public let nickname: String?
    public let avatarURL: String?
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case nickname
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }

    public init(id: Int64, phone: String, nickname: String?, avatarURL: String?, createdAt: Date?) {
        self.id = id
        self.phone = phone
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}

public struct VerifySMSResponse: Decodable, Equatable, Sendable {
    public let token: String
    public let user: AuthUser

    public init(token: String, user: AuthUser) {
        self.token = token
        self.user = user
    }
}
