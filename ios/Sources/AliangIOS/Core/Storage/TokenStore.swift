import Foundation

public protocol TokenStore: Sendable {
    func save(token: String) throws
    func readToken() throws -> String?
    func clearToken() throws
}

public final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var token: String?
    private let lock = NSLock()

    public init(initialToken: String? = nil) {
        self.token = initialToken
    }

    public func save(token: String) throws {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
    }

    public func readToken() throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    public func clearToken() throws {
        lock.lock()
        defer { lock.unlock() }
        token = nil
    }
}
