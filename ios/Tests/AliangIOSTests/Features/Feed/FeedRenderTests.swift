import Foundation
import XCTest
@testable import AliangIOS

final class FeedRenderTests: XCTestCase {
    func testFeedPostRenderFields() {
        let post = FeedPost(
            id: 8,
            userID: 2,
            title: "Hello",
            content: "World",
            postType: "image",
            likeCount: 13,
            commentCount: 7,
            isLiked: true,
            createdAt: Date(),
            author: FeedAuthor(id: 2, nickname: "Alice", avatarURL: nil),
            media: [
                FeedMedia(id: 99, mediaURL: "https://example.com/x.jpg", thumbnailURL: nil, mediaType: "image")
            ]
        )

        XCTAssertEqual(post.title, "Hello")
        XCTAssertEqual(post.content, "World")
        XCTAssertEqual(post.author?.nickname, "Alice")
        XCTAssertEqual(post.likeCount, 13)
        XCTAssertEqual(post.commentCount, 7)
        XCTAssertEqual(post.isLiked, true)
        XCTAssertEqual(post.media.count, 1)
    }

    func testFeedPageDecodeWithHasMore() throws {
        let json = #"""
        {
          "success": true,
          "data": {
            "items": [
              {
                "id": 1,
                "user_id": 3,
                "title": "test",
                "content": "content",
                "post_type": "image",
                "like_count": 2,
                "comment_count": 1,
                "is_liked": true,
                "created_at": "2026-02-08T10:00:00Z",
                "media": []
              }
            ],
            "has_more": true
          }
        }
        """#

        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let envelope = try decoder.decode(APIEnvelope<FeedPage>.self, from: data)
        XCTAssertTrue(envelope.success)
        XCTAssertEqual(envelope.data?.items.count, 1)
        XCTAssertEqual(envelope.data?.items.first?.isLiked, true)
        XCTAssertEqual(envelope.data?.hasMore, true)
    }

    func testFeedPageDecodeNormalizesMediaURLWithoutScheme() throws {
        let json = #"""
        {
          "success": true,
          "data": {
            "items": [
              {
                "id": 1,
                "user_id": 3,
                "title": "test",
                "content": "content",
                "post_type": "image",
                "like_count": 2,
                "comment_count": 1,
                "is_liked": true,
                "created_at": "2026-02-08T10:00:00Z",
                "media": [
                  {
                    "id": 10,
                    "media_url": "localhost:9000/aliang-media/images/a.jpg",
                    "thumbnail_url": "//localhost:9000/aliang-media/images/t.jpg",
                    "media_type": "image"
                  }
                ]
              }
            ],
            "has_more": false
          }
        }
        """#

        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let envelope = try decoder.decode(APIEnvelope<FeedPage>.self, from: data)
        let media = try XCTUnwrap(envelope.data?.items.first?.media.first)
        XCTAssertEqual(media.mediaURL, "http://localhost:9000/aliang-media/images/a.jpg")
        XCTAssertEqual(media.thumbnailURL, "http://localhost:9000/aliang-media/images/t.jpg")
    }
}
