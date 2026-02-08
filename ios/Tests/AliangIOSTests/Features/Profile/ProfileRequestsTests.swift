import Foundation
import XCTest
@testable import AliangIOS

final class ProfileRequestsTests: XCTestCase {
    func testGetMyProfileRequestPath() {
        let request = GetMyProfileRequest()
        XCTAssertEqual(request.path, "api/v1/users/me")
        XCTAssertTrue(request.requiresAuth)
        XCTAssertEqual(request.method, .get)
    }

    func testGetUserProfileRequestPath() {
        let request = GetUserProfileRequest(userID: 42)
        XCTAssertEqual(request.path, "api/v1/users/42")
        XCTAssertTrue(request.requiresAuth)
    }

    func testGetUserPostsRequestPathAndQuery() {
        let request = GetUserPostsRequest(userID: 123, offset: 10, limit: 20)

        XCTAssertEqual(request.path, "api/v1/users/123/posts")
        XCTAssertEqual(request.queryItems.count, 2)

        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "10")

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "20")
    }

    func testGetUserPostsRequestWithZeroOffset() {
        let request = GetUserPostsRequest(userID: 1, offset: 0, limit: 20)
        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "0")
    }

    func testGetUserPostsRequestWithNegativeValues() {
        let request = GetUserPostsRequest(userID: 1, offset: -5, limit: -1)

        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "0")

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "1")
    }

    func testUpdateProfileRequestPathMethodAndBody() {
        let payload = UpdateProfileRequest(
            nickname: "NewName",
            avatarURL: "https://example.com/avatar.jpg",
            bio: "My new bio"
        )
        let request = UpdateProfileRequestWrapper(payload: payload)

        XCTAssertEqual(request.path, "api/v1/users/me")
        XCTAssertEqual(request.method, .patch)
        XCTAssertTrue(request.requiresAuth)
        XCTAssertNotNil(request.body)

        let decodedBody = try? JSONDecoder().decode(UpdateProfileRequest.self, from: request.body!)
        XCTAssertEqual(decodedBody?.nickname, "NewName")
        XCTAssertEqual(decodedBody?.avatarURL, "https://example.com/avatar.jpg")
        XCTAssertEqual(decodedBody?.bio, "My new bio")
    }

    func testUpdateProfileRequestWithPartialUpdates() {
        let payload = UpdateProfileRequest(nickname: "OnlyName", avatarURL: nil, bio: nil)
        let request = UpdateProfileRequestWrapper(payload: payload)

        XCTAssertNotNil(request.body)

        let decodedBody = try? JSONDecoder().decode(UpdateProfileRequest.self, from: request.body!)
        XCTAssertEqual(decodedBody?.nickname, "OnlyName")
        XCTAssertNil(decodedBody?.avatarURL)
        XCTAssertNil(decodedBody?.bio)
    }
}
