import Foundation
import XCTest
@testable import AliangIOS

final class SearchRequestsTests: XCTestCase {
    func testSearchPostsRequestPathAndQuery() {
        let request = SearchPostsRequest(query: "swift", offset: 0, limit: 20)

        XCTAssertEqual(request.path, "api/v1/search")
        XCTAssertEqual(request.method, .get)
        XCTAssertFalse(request.requiresAuth)
        XCTAssertEqual(request.queryItems.count, 3)

        let queryItem = request.queryItems.first { $0.name == "q" }
        XCTAssertEqual(queryItem?.value, "swift")

        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "0")

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "20")
    }

    func testSearchPostsRequestWithSpecialCharacters() {
        let request = SearchPostsRequest(query: "hello world", offset: 5, limit: 10)

        let queryItem = request.queryItems.first { $0.name == "q" }
        XCTAssertEqual(queryItem?.value, "hello world")
    }

    func testGetTrendingHashtagsRequestPathAndQuery() {
        let request = GetTrendingHashtagsRequest(limit: 5)

        XCTAssertEqual(request.path, "api/v1/hashtags/trending")
        XCTAssertEqual(request.method, .get)
        XCTAssertFalse(request.requiresAuth)

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "5")
    }

    func testGetTrendingHashtagsWithDefaultLimit() {
        let request = GetTrendingHashtagsRequest(limit: 0)

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "1")
    }

    func testGetHashtagPostsRequestPathAndQuery() {
        let request = GetHashtagPostsRequest(name: "trending", offset: 10, limit: 15)

        XCTAssertEqual(request.path, "api/v1/hashtags/trending")
        XCTAssertEqual(request.method, .get)
        XCTAssertFalse(request.requiresAuth)
        XCTAssertEqual(request.queryItems.count, 2)

        let offsetItem = request.queryItems.first { $0.name == "offset" }
        XCTAssertEqual(offsetItem?.value, "10")

        let limitItem = request.queryItems.first { $0.name == "limit" }
        XCTAssertEqual(limitItem?.value, "15")
    }

    func testGetHashtagPostsURLEncoding() {
        let request = GetHashtagPostsRequest(name: "hello world", offset: 0, limit: 10)

        XCTAssertTrue(request.path.contains("hashtags/"))
        XCTAssertTrue(request.path.contains("hello"))
    }

    func testGetHashtagPostsWithSpecialCharacters() {
        let request = GetHashtagPostsRequest(name: "#test!", offset: 0, limit: 10)

        let path = request.path
        XCTAssertTrue(path.contains("hashtags/"))
    }
}
