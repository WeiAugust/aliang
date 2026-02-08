import Foundation

public protocol ProfileServiceProtocol: Sendable {
    func fetchMyProfile() async throws -> UserProfile
    func fetchUserProfile(userID: Int64) async throws -> UserProfile
    func fetchUserPosts(userID: Int64, offset: Int, limit: Int) async throws -> UserPostPage
    func updateProfile(nickname: String?, avatarURL: String?, bio: String?) async throws -> UserProfile
}

public final class ProfileService: ProfileServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let tokenProvider: @Sendable () -> String?

    public init(
        httpClient: HTTPClientProtocol,
        tokenProvider: @escaping @Sendable () -> String? = { nil }
    ) {
        self.httpClient = httpClient
        self.tokenProvider = tokenProvider
    }

    public func fetchMyProfile() async throws -> UserProfile {
        try await httpClient.send(
            GetMyProfileRequest(),
            authToken: tokenProvider()
        )
    }

    public func fetchUserProfile(userID: Int64) async throws -> UserProfile {
        try await httpClient.send(
            GetUserProfileRequest(userID: userID),
            authToken: tokenProvider()
        )
    }

    public func fetchUserPosts(userID: Int64, offset: Int, limit: Int) async throws -> UserPostPage {
        try await httpClient.send(
            GetUserPostsRequest(userID: userID, offset: offset, limit: limit),
            authToken: tokenProvider()
        )
    }

    public func updateProfile(nickname: String?, avatarURL: String?, bio: String?) async throws -> UserProfile {
        let payload = UpdateProfileRequest(nickname: nickname, avatarURL: avatarURL, bio: bio)
        return try await httpClient.send(
            UpdateProfileRequestWrapper(payload: payload),
            authToken: tokenProvider()
        )
    }
}
