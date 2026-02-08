import AliangIOS
import Foundation
import XCTest

@MainActor
final class AppSessionTests: XCTestCase {
    func testBootstrapLoadsTokenFromStore() {
        let store = InMemoryTokenStore(initialToken: "token-123")
        let session = AppSession(tokenStore: store)

        session.bootstrap()

        XCTAssertEqual(session.state, .authenticated(token: "token-123"))
        XCTAssertEqual(session.authToken, "token-123")
        XCTAssertTrue(session.isLoggedIn)
    }

    func testBootstrapWithoutTokenSetsUnauthenticated() {
        let store = InMemoryTokenStore(initialToken: nil)
        let session = AppSession(tokenStore: store)

        session.bootstrap()

        XCTAssertEqual(session.state, .unauthenticated)
        XCTAssertNil(session.authToken)
        XCTAssertFalse(session.isLoggedIn)
        XCTAssertNil(session.currentUserID)
    }

    func testBootstrapParsesCurrentUserIDFromJWTPayload() {
        let token = makeJWT(payload: ["user_id": 321])
        let store = InMemoryTokenStore(initialToken: token)
        let session = AppSession(tokenStore: store)

        session.bootstrap()

        XCTAssertEqual(session.currentUserID, 321)
    }

    func testLoginPersistsTokenAndUpdatesState() throws {
        let store = InMemoryTokenStore(initialToken: nil)
        let session = AppSession(tokenStore: store)

        session.login(with: "new-token")

        XCTAssertEqual(session.state, .authenticated(token: "new-token"))
        XCTAssertEqual(try store.readToken(), "new-token")
    }

    func testLoginWithExplicitUserIDSetsCurrentUserID() {
        let store = InMemoryTokenStore(initialToken: nil)
        let session = AppSession(tokenStore: store)

        session.login(with: "opaque-token", userID: 9527)

        XCTAssertEqual(session.currentUserID, 9527)
    }

    func testLogoutClearsTokenAndResetsState() throws {
        let token = makeJWT(payload: ["user_id": 88])
        let store = InMemoryTokenStore(initialToken: token)
        let session = AppSession(tokenStore: store)
        session.bootstrap()

        session.logout()

        XCTAssertEqual(session.state, .unauthenticated)
        XCTAssertNil(try store.readToken())
        XCTAssertNil(session.currentUserID)
    }

    private func makeJWT(payload: [String: Any]) -> String {
        let headerData = Data(#"{"alg":"HS256","typ":"JWT"}"#.utf8)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)
        let header = encodeBase64URL(headerData)
        let body = encodeBase64URL(payloadData)
        return "\(header).\(body).signature"
    }

    private func encodeBase64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
