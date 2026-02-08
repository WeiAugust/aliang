import Foundation
import XCTest
@testable import AliangIOS

final class ProfileModelsTests: XCTestCase {
    private var iso8601Decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testUserProfileDecoding() throws {
        let json = """
        {
            "id": 123,
            "phone": "13800138000",
            "nickname": "TestUser",
            "avatar_url": "https://example.com/avatar.jpg",
            "bio": "Hello world",
            "post_count": 42,
            "created_at": "2026-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let profile = try iso8601Decoder.decode(UserProfile.self, from: json)

        XCTAssertEqual(profile.id, 123)
        XCTAssertEqual(profile.phone, "13800138000")
        XCTAssertEqual(profile.nickname, "TestUser")
        XCTAssertEqual(profile.avatarURL, "https://example.com/avatar.jpg")
        XCTAssertEqual(profile.bio, "Hello world")
        XCTAssertEqual(profile.postCount, 42)
    }

    func testUserProfileDecodingWithOptionalFields() throws {
        let json = """
        {
            "id": 456,
            "nickname": "MinimalUser"
        }
        """.data(using: .utf8)!

        let profile = try iso8601Decoder.decode(UserProfile.self, from: json)

        XCTAssertEqual(profile.id, 456)
        XCTAssertNil(profile.phone)
        XCTAssertEqual(profile.nickname, "MinimalUser")
        XCTAssertNil(profile.avatarURL)
        XCTAssertNil(profile.bio)
        XCTAssertEqual(profile.postCount, 0)
    }

    func testUserProfileEquality() {
        let date = Date(timeIntervalSince1970: 1000)
        let profile1 = UserProfile(
            id: 1,
            phone: "13800138000",
            nickname: "User",
            avatarURL: "https://example.com/avatar.jpg",
            bio: "Bio",
            postCount: 10,
            createdAt: date
        )

        let profile2 = UserProfile(
            id: 1,
            phone: "13800138000",
            nickname: "User",
            avatarURL: "https://example.com/avatar.jpg",
            bio: "Bio",
            postCount: 10,
            createdAt: date
        )

        XCTAssertEqual(profile1, profile2)
    }

    func testUserProfileInequality() {
        let date = Date(timeIntervalSince1970: 1000)
        let profile1 = UserProfile(id: 1, nickname: "User1", createdAt: date)
        let profile2 = UserProfile(id: 2, nickname: "User2", createdAt: date)

        XCTAssertNotEqual(profile1, profile2)
    }

    func testUpdateProfileRequestEncoding() throws {
        let request = UpdateProfileRequest(
            nickname: "NewName",
            avatarURL: "https://example.com/new.jpg",
            bio: "New bio"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("nickname"))
        XCTAssertTrue(json.contains("NewName"))
        XCTAssertTrue(json.contains("avatar_url"))
        XCTAssertTrue(json.contains("bio"))
        XCTAssertTrue(json.contains("New bio"))
    }

    func testUpdateProfileRequestEncodingWithNilFields() throws {
        let request = UpdateProfileRequest(nickname: "OnlyName", avatarURL: nil, bio: nil)

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("nickname"))
        XCTAssertTrue(json.contains("OnlyName"))
        XCTAssertFalse(json.contains("avatar_url"))
        XCTAssertFalse(json.contains("bio"))
    }

    func testUpdateProfileRequestDecoding() throws {
        let json = """
        {
            "nickname": "DecodedName",
            "avatar_url": "https://example.com/decoded.jpg",
            "bio": "Decoded bio"
        }
        """.data(using: .utf8)!

        let request = try JSONDecoder().decode(UpdateProfileRequest.self, from: json)

        XCTAssertEqual(request.nickname, "DecodedName")
        XCTAssertEqual(request.avatarURL, "https://example.com/decoded.jpg")
        XCTAssertEqual(request.bio, "Decoded bio")
    }

    func testUserPostPageDecoding() throws {
        let json = """
        {
            "items": [
                {
                    "id": 1,
                    "user_id": 100,
                    "title": "Post 1",
                    "content": "Content 1",
                    "post_type": "image",
                    "like_count": 10,
                    "comment_count": 5,
                    "is_liked": true,
                    "created_at": "2026-01-15T10:30:00Z",
                    "user": {
                        "id": 100,
                        "nickname": "author",
                        "avatar_url": null
                    },
                    "media": []
                }
            ],
            "has_more": true
        }
        """.data(using: .utf8)!

        let page = try iso8601Decoder.decode(UserPostPage.self, from: json)

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items.first?.id, 1)
        XCTAssertEqual(page.items.first?.title, "Post 1")
        XCTAssertTrue(page.hasMore)
    }

    func testUserPostPageEmptyItems() throws {
        let json = """
        {
            "items": [],
            "has_more": false
        }
        """.data(using: .utf8)!

        let page = try JSONDecoder().decode(UserPostPage.self, from: json)

        XCTAssertTrue(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
    }
}
