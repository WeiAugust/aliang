import Foundation
@testable import AliangIOS

final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var token: String?
    private let lock = NSLock()

    init(initialToken: String? = nil) {
        token = initialToken
    }

    func save(token: String) throws {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
    }

    func readToken() throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    func clearToken() throws {
        lock.lock()
        defer { lock.unlock() }
        token = nil
    }
}
