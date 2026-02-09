import Foundation

enum RemoteMediaURLResolver {
    private static let lock = NSLock()
    private static var configuredBaseURL: URL = AppConfig().baseAPIURL

    static func configure(baseURL: URL) {
        lock.lock()
        configuredBaseURL = baseURL
        lock.unlock()
    }

    static var baseURL: URL {
        lock.lock()
        defer { lock.unlock() }
        return configuredBaseURL
    }

    static func resolve(relativePath: String) -> String? {
        URL(string: relativePath, relativeTo: baseURL)?.absoluteURL.absoluteString
    }
}
