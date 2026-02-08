import Foundation
import XCTest
@testable import AliangIOS

final class SearchModelsTests: XCTestCase {
    private var iso8601Decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testSearchResultDecoding() throws {
        let json = """
        {
            "items": [
                {
                    "id": 1,
                    "user_id": 100,
                    "title": "First Post",
                    "content": "Content 1",
                    "post_type": "image",
                    "like_count": 5,
                    "comment_count": 2,
                    "is_liked": false,
                    "created_at": "2026-01-15T10:30:00Z",
                    "user": {
                        "id": 100,
                        "nickname": "author1",
                        "avatar_url": null
                    },
                    "media": []
                },
                {
                    "id": 2,
                    "user_id": 101,
                    "title": "Second Post",
                    "content": "Content 2",
                    "post_type": "video",
                    "like_count": 10,
                    "comment_count": 3,
                    "is_liked": true,
                    "created_at": "2026-01-16T10:30:00Z",
                    "user": {
                        "id": 101,
                        "nickname": "author2",
                        "avatar_url": "https://example.com/avatar.jpg"
                    },
                    "media": []
                }
            ],
            "has_more": true
        }
        """.data(using: .utf8)!

        let result = try iso8601Decoder.decode(SearchResult.self, from: json)

        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items.first?.title, "First Post")
        XCTAssertEqual(result.items.last?.title, "Second Post")
        XCTAssertTrue(result.hasMore)
    }

    func testSearchResultWithEmptyItems() throws {
        let json = """
        {
            "items": [],
            "has_more": false
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(SearchResult.self, from: json)

        XCTAssertTrue(result.items.isEmpty)
        XCTAssertFalse(result.hasMore)
    }

    func testTrendingHashtagDecoding() throws {
        let json = """
        {
            "id": 1,
            "name": "technology",
            "post_count": 500
        }
        """.data(using: .utf8)!

        let hashtag = try JSONDecoder().decode(TrendingHashtag.self, from: json)

        XCTAssertEqual(hashtag.id, 1)
        XCTAssertEqual(hashtag.name, "technology")
        XCTAssertEqual(hashtag.postCount, 500)
    }

    func testTrendingHashtagWithNilPostCount() throws {
        let json = """
        {
            "id": 2,
            "name": "newtag"
        }
        """.data(using: .utf8)!

        let hashtag = try JSONDecoder().decode(TrendingHashtag.self, from: json)

        XCTAssertEqual(hashtag.id, 2)
        XCTAssertEqual(hashtag.name, "newtag")
        XCTAssertNil(hashtag.postCount)
    }

    func testHashtagPostPageDecoding() throws {
        let json = """
        {
            "items": [
                {
                    "id": 10,
                    "user_id": 200,
                    "title": "Tagged Post",
                    "content": "Has great content",
                    "post_type": "image",
                    "like_count": 25,
                    "comment_count": 8,
                    "is_liked": false,
                    "created_at": "2026-01-15T10:30:00Z",
                    "user": {
                        "id": 200,
                        "nickname": "poster",
                        "avatar_url": null
                    },
                    "media": []
                }
            ],
            "has_more": false
        }
        """.data(using: .utf8)!

        let page = try iso8601Decoder.decode(HashtagPostPage.self, from: json)

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items.first?.id, 10)
        XCTAssertFalse(page.hasMore)
    }

    func testTrendingHashtagEquality() {
        let hashtag1 = TrendingHashtag(id: 1, name: "test", postCount: 100)
        let hashtag2 = TrendingHashtag(id: 1, name: "test", postCount: 100)
        let hashtag3 = TrendingHashtag(id: 2, name: "test", postCount: 100)

        XCTAssertEqual(hashtag1, hashtag2)
        XCTAssertNotEqual(hashtag1, hashtag3)
    }

    func testSearchResultEquality() {
        let post1 = FeedPost(
            id: 1,
            userID: 1,
            title: "Test",
            content: "Content",
            postType: "image",
            likeCount: 10,
            commentCount: 5,
            isLiked: false,
            createdAt: Date(),
            author: nil,
            media: []
        )

        let result1 = SearchResult(items: [post1], hasMore: true)
        let result2 = SearchResult(items: [post1], hasMore: true)
        let result3 = SearchResult(items: [post1], hasMore: false)

        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
}
