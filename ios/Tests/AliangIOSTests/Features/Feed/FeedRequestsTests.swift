import Foundation
import XCTest
@testable import AliangIOS

final class FeedRequestsTests: XCTestCase {
    func testListFeedRequestPathAndQuery() {
        let request = ListFeedRequest(offset: 10, limit: 20)

        XCTAssertEqual(request.path, "api/v1/posts")
        XCTAssertEqual(request.method, .get)
        XCTAssertFalse(request.requiresAuth)

        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "10")

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "20")
    }

    func testListFeedRequestNormalizesPagination() {
        let request = ListFeedRequest(offset: -1, limit: 0)

        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "0")

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "1")
    }

    func testPostDetailRequestPath() {
        let request = PostDetailRequest(postID: 42)

        XCTAssertEqual(request.path, "api/v1/posts/42")
        XCTAssertEqual(request.method, .get)
        XCTAssertFalse(request.requiresAuth)
    }
}
