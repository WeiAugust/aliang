import Foundation
import XCTest
@testable import AliangIOS

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testLoadMyProfileFetchesCurrentUser() async {
        let service = ProfileServiceMock()
        service.myProfileResult = .success(sampleProfile(id: 1, nickname: "MyUser"))

        let viewModel = ProfileViewModel(service: service)
        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.profile?.id, 1)
        XCTAssertEqual(viewModel.profile?.nickname, "MyUser")
        XCTAssertFalse(viewModel.isLoadingProfile)
        XCTAssertEqual(service.myProfileCalls, 1)
    }

    func testLoadOtherUserProfile() async {
        let service = ProfileServiceMock()
        service.userProfileResult = .success(sampleProfile(id: 5, nickname: "OtherUser"))

        let viewModel = ProfileViewModel(service: service, userID: 5)
        await viewModel.loadProfile()

        XCTAssertEqual(viewModel.profile?.id, 5)
        XCTAssertEqual(viewModel.profile?.nickname, "OtherUser")
        XCTAssertEqual(service.userProfileCalls, [5])
    }

    func testLoadProfileHandlesError() async {
        let service = ProfileServiceMock()
        service.myProfileResult = .failure(APIError.server(statusCode: 500, code: "NOT_FOUND", message: "Profile not found"))

        let viewModel = ProfileViewModel(service: service)
        await viewModel.loadProfile()

        XCTAssertNil(viewModel.profile)
        XCTAssertEqual(viewModel.errorMessage, "Server error (500): Profile not found")
    }

    func testLoadPostsFetchesUserPosts() async {
        let service = ProfileServiceMock()
        service.userPostsResult = .success(UserPostPage(
            items: [samplePost(id: 10), samplePost(id: 11)],
            hasMore: true
        ))

        let viewModel = ProfileViewModel(service: service, userID: 1)
        await viewModel.loadPosts()

        XCTAssertEqual(viewModel.posts.map(\.id), [10, 11])
        XCTAssertTrue(viewModel.hasMorePosts)
        XCTAssertEqual(service.userPostsCalls.count, 1)
        XCTAssertEqual(service.userPostsCalls[0].userID, 1)
        XCTAssertEqual(service.userPostsCalls[0].offset, 0)
        XCTAssertEqual(service.userPostsCalls[0].limit, 20)
    }

    func testRefreshResetsAndReloads() async {
        let service = ProfileServiceMock()
        service.myProfileResult = .success(sampleProfile(id: 1))
        service.userPostsResult = .success(UserPostPage(items: [samplePost(id: 20)], hasMore: false))

        let viewModel = ProfileViewModel(service: service, pageSize: 10)

        await viewModel.loadProfile()
        await viewModel.loadPosts()

        XCTAssertEqual(viewModel.posts.count, 1)

        service.userPostsResult = .success(UserPostPage(items: [samplePost(id: 30)], hasMore: false))
        await viewModel.refresh()

        XCTAssertEqual(viewModel.posts.map(\.id), [30])
        XCTAssertFalse(viewModel.hasMorePosts)
    }

    func testLoadMorePostsAppendsToList() async {
        let service = ProfileServiceMock()
        service.userPostsResult = .success(UserPostPage(
            items: [samplePost(id: 1), samplePost(id: 2)],
            hasMore: true
        ))

        let viewModel = ProfileViewModel(service: service, userID: 1, pageSize: 2)
        await viewModel.loadPosts()

        service.userPostsResult = .success(UserPostPage(
            items: [samplePost(id: 3)],
            hasMore: false
        ))
        await viewModel.loadMoreIfNeeded(currentPost: viewModel.posts[1])

        XCTAssertEqual(viewModel.posts.map(\.id), [1, 2, 3])
        XCTAssertFalse(viewModel.hasMorePosts)
        XCTAssertEqual(service.userPostsCalls.count, 2)
    }

    func testUpdateProfileModifiesProfile() async {
        let service = ProfileServiceMock()
        service.myProfileResult = .success(sampleProfile(id: 1, nickname: "OldName"))
        service.updateProfileResult = .success(sampleProfile(id: 1, nickname: "NewName"))

        let viewModel = ProfileViewModel(service: service)
        await viewModel.loadProfile()

        let success = await viewModel.updateProfile(nickname: "NewName", avatarURL: nil, bio: nil)

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.profile?.nickname, "NewName")
        XCTAssertEqual(service.updateProfileCalls.count, 1)
    }

    func testUpdateProfileHandlesFailure() async {
        let service = ProfileServiceMock()
        service.myProfileResult = .success(sampleProfile(id: 1))
        service.updateProfileResult = .failure(APIError.server(statusCode: 500, code: "UPDATE_FAILED", message: "Update failed"))

        let viewModel = ProfileViewModel(service: service)
        await viewModel.loadProfile()

        let success = await viewModel.updateProfile(nickname: "NewName", avatarURL: nil, bio: nil)

        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.errorMessage, "Server error (500): Update failed")
    }

    func testClearErrorResetsErrorMessage() async {
        let service = ProfileServiceMock()
        service.myProfileResult = .failure(APIError.server(statusCode: 500, code: "ERROR", message: "Error"))

        let viewModel = ProfileViewModel(service: service)
        await viewModel.loadProfile()

        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    private func sampleProfile(id: Int64, nickname: String = "TestUser") -> UserProfile {
        UserProfile(
            id: id,
            phone: "13800138000",
            nickname: nickname,
            avatarURL: "https://example.com/avatar.jpg",
            bio: "Test bio",
            postCount: 5,
            createdAt: Date()
        )
    }

    private func samplePost(id: Int64) -> FeedPost {
        FeedPost(
            id: id,
            userID: 1,
            title: "Title \(id)",
            content: "Content \(id)",
            postType: "image",
            likeCount: 10,
            commentCount: 2,
            isLiked: false,
            createdAt: Date(),
            author: FeedAuthor(id: 1, nickname: "tester", avatarURL: nil),
            media: []
        )
    }
}

private final class ProfileServiceMock: ProfileServiceProtocol, @unchecked Sendable {
    var myProfileResult: Result<UserProfile, Error> = .failure(APIError.invalidResponse)
    var userProfileResult: Result<UserProfile, Error> = .failure(APIError.invalidResponse)
    var userPostsResult: Result<UserPostPage, Error> = .failure(APIError.invalidResponse)
    var updateProfileResult: Result<UserProfile, Error> = .failure(APIError.invalidResponse)

    private(set) var myProfileCalls = 0
    private(set) var userProfileCalls: [Int64] = []
    private(set) var userPostsCalls: [(userID: Int64, offset: Int, limit: Int)] = []
    private(set) var updateProfileCalls: [(nickname: String?, avatarURL: String?, bio: String?)] = []

    func fetchMyProfile() async throws -> UserProfile {
        myProfileCalls += 1
        return try myProfileResult.get()
    }

    func fetchUserProfile(userID: Int64) async throws -> UserProfile {
        userProfileCalls.append(userID)
        return try userProfileResult.get()
    }

    func fetchUserPosts(userID: Int64, offset: Int, limit: Int) async throws -> UserPostPage {
        userPostsCalls.append((userID: userID, offset: offset, limit: limit))
        return try userPostsResult.get()
    }

    func updateProfile(nickname: String?, avatarURL: String?, bio: String?) async throws -> UserProfile {
        updateProfileCalls.append((nickname: nickname, avatarURL: avatarURL, bio: bio))
        return try updateProfileResult.get()
    }
}
