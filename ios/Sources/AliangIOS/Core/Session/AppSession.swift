import Foundation

@MainActor
public final class AppSession: ObservableObject {
    public enum State: Equatable {
        case launching
        case authenticated(token: String)
        case unauthenticated
    }

    @Published public private(set) var state: State = .launching

    public var authToken: String? {
        guard case let .authenticated(token) = state else {
            return nil
        }
        return token
    }

    public var currentUserID: Int64? {
        if let explicitCurrentUserID {
            return explicitCurrentUserID
        }

        guard let token = authToken else {
            return nil
        }

        return Self.userID(fromJWT: token)
    }

    public var isLoggedIn: Bool {
        authToken != nil
    }

    private let tokenStore: TokenStore
    private var explicitCurrentUserID: Int64?

    public init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
    }

    public func bootstrap() {
        do {
            let token = try tokenStore.readToken()
            guard let token, token.isEmpty == false else {
                state = .unauthenticated
                explicitCurrentUserID = nil
                return
            }

            state = .authenticated(token: token)
            explicitCurrentUserID = Self.userID(fromJWT: token)
        } catch {
            state = .unauthenticated
            explicitCurrentUserID = nil
        }
    }

    public func login(with token: String, userID: Int64? = nil) {
        do {
            try tokenStore.save(token: token)
            state = .authenticated(token: token)
            explicitCurrentUserID = userID ?? Self.userID(fromJWT: token)
        } catch {
            state = .unauthenticated
            explicitCurrentUserID = nil
        }
    }

    public func logout() {
        do {
            try tokenStore.clearToken()
        } catch {
            // Keep logout idempotent for UI flow.
        }
        state = .unauthenticated
        explicitCurrentUserID = nil
    }

    private static func userID(fromJWT token: String) -> Int64? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2,
              let payloadData = decodeBase64URL(segments[1]),
              let object = try? JSONSerialization.jsonObject(with: payloadData),
              let claims = object as? [String: Any]
        else {
            return nil
        }

        let keys = ["user_id", "uid", "id", "sub"]
        for key in keys {
            if let value = parseInt64(claims[key]) {
                return value
            }
        }

        return nil
    }

    private static func parseInt64(_ value: Any?) -> Int64? {
        if let int64Value = value as? Int64 {
            return int64Value
        }

        if let intValue = value as? Int {
            return Int64(intValue)
        }

        if let stringValue = value as? String {
            return Int64(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if let numberValue = value as? NSNumber {
            return numberValue.int64Value
        }

        return nil
    }

    private static func decodeBase64URL(_ value: Substring) -> Data? {
        var base64 = String(value)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        return Data(base64Encoded: base64)
    }
}
