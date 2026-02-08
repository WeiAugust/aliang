import Foundation

public struct AppConfig: Equatable, Sendable {
    public var baseAPIURL: URL

    public init(baseAPIURL: URL = URL(string: "http://localhost:8080")!) {
        self.baseAPIURL = baseAPIURL
    }
}
