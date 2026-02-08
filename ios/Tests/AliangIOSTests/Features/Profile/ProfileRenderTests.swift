import Foundation
import XCTest
@testable import AliangIOS

@MainActor
final class ProfileRenderTests: XCTestCase {
    func testProfileViewModelInitialState() {
        let service = ProfileServiceMock()
        let viewModel = ProfileViewModel(service: service)

        XCTAssertNil(viewModel.profile)
        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertFalse(viewModel.isLoadingProfile)
        XCTAssertFalse(viewModel.isLoadingPosts)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasMorePosts)
        XCTAssertTrue(viewModel.isMyProfile)
    }

    func testProfileViewModelWithUserIDNotMyProfile() {
        let service = ProfileServiceMock()
        let viewModel = ProfileViewModel(service: service, userID: 42)

        XCTAssertFalse(viewModel.isMyProfile)
    }

    func testProfileViewModelClearError() {
        let service = ProfileServiceMock()
        service.myProfileResult = .failure(APIError.server(statusCode: 500, code: "ERROR", message: "Test error"))

        let viewModel = ProfileViewModel(service: service)

        let expectation = XCTestExpectation(description: "Error loaded")
        Task {
            await viewModel.loadProfile()
            XCTAssertNotNil(viewModel.errorMessage)

            viewModel.clearError()
            XCTAssertNil(viewModel.errorMessage)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testProfileViewModelLoadMoreDoesNotTriggerWhenNoMore() async {
        let service = ProfileServiceMock()
        service.userPostsResult = .success(UserPostPage(items: [], hasMore: false))

        let viewModel = ProfileViewModel(service: service, pageSize: 10)
        await viewModel.loadPosts()

        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertFalse(viewModel.hasMorePosts)
    }
}

private final class ProfileServiceMock: ProfileServiceProtocol, @unchecked Sendable {
    var myProfileResult: Result<UserProfile, Error> = .failure(APIError.invalidResponse)
    var userProfileResult: Result<UserProfile, Error> = .failure(APIError.invalidResponse)
    var userPostsResult: Result<UserPostPage, Error> = .failure(APIError.invalidResponse)
    var updateProfileResult: Result<UserProfile, Error> = .failure(APIError.invalidResponse)

    func fetchMyProfile() async throws -> UserProfile {
        return try myProfileResult.get()
    }

    func fetchUserProfile(userID: Int64) async throws -> UserProfile {
        return try userProfileResult.get()
    }

    func fetchUserPosts(userID: Int64, offset: Int, limit: Int) async throws -> UserPostPage {
        return try userPostsResult.get()
    }

    func updateProfile(nickname: String?, avatarURL: String?, bio: String?) async throws -> UserProfile {
        return try updateProfileResult.get()
    }
}
