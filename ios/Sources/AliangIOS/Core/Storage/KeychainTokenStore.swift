import Foundation

#if canImport(Security)
import Security
#endif

public final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    public init(
        service: String = "com.aliang.app",
        account: String = "auth_token"
    ) {
        self.service = service
        self.account = account
    }

    public func save(token: String) throws {
#if canImport(Security)
        let data = Data(token.utf8)
        var query = baseQuery

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw APIError.keychain("Failed to update keychain item")
            }
            return
        }

        query.merge(attributes) { _, new in new }
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw APIError.keychain("Failed to add keychain item")
        }
#else
        throw APIError.keychain("Keychain is unavailable on current platform")
#endif
    }

    public func readToken() throws -> String? {
#if canImport(Security)
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess else {
            throw APIError.keychain("Failed to read keychain item")
        }

        guard let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
            throw APIError.decoding("Failed to decode token from keychain")
        }

        return token
#else
        throw APIError.keychain("Keychain is unavailable on current platform")
#endif
    }

    public func clearToken() throws {
#if canImport(Security)
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIError.keychain("Failed to clear keychain token")
        }
#else
        throw APIError.keychain("Keychain is unavailable on current platform")
#endif
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
