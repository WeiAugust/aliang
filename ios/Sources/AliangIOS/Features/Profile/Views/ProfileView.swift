import SwiftUI

public struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    private let onLogout: (() -> Void)?

    public init(
        viewModel: @autoclosure @escaping () -> ProfileViewModel,
        onLogout: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    profileHeader

                    if viewModel.isLoadingProfile, viewModel.profile == nil {
                        ProgressView("Loading profile...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }

                    postsSection
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if viewModel.isMyProfile, let onLogout = onLogout {
                        Button("Logout") {
                            onLogout()
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadProfile()
                await viewModel.loadPosts()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { show in
                        if !show {
                            viewModel.clearError()
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    @ViewBuilder
    private var profileHeader: some View {
        if let profile = viewModel.profile {
            VStack(spacing: 16) {
                avatarView(url: profile.avatarURL)

                Text(profile.nickname)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack(spacing: 32) {
                    statView(value: profile.postCount, label: "Posts")

                    if let createdAt = createdAtDate(profile.createdAt) {
                        VStack(spacing: 4) {
                            Text("Joined")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(createdAt, style: .date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            #if os(iOS)
            .background(Color(.systemBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
        }
    }

    @ViewBuilder
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Posts")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 12)

            if viewModel.posts.isEmpty, !viewModel.isLoadingPosts {
                ContentUnavailableView(
                    "No posts yet",
                    systemImage: "tray",
                    description: Text("Posts will appear here")
                )
                .frame(height: 200)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            PostDetailView(
                                post: post,
                                interactionViewModel: makeInteractionViewModel(for: post),
                                onInteractionStateChange: { _ in }
                            )
                        } label: {
                            ProfilePostRowView(post: post)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentPost: post)
                            }
                        }
                    }

                    if viewModel.isLoadingPosts {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
        }
    }

    private func avatarView(url: String?) -> some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .squaredFrame(size: 100)
                    .clipShape(Circle())
            case .failure, .empty:
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .squaredFrame(size: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    )
            @unknown default:
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .squaredFrame(size: 100)
            }
        }
    }

    private func statView(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func createdAtDate(_ date: Date) -> Date? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
            return nil
        }
        return date
    }

    private func makeInteractionViewModel(for post: FeedPost) -> InteractionViewModel {
        InteractionViewModel(
            interactionService: DummyInteractionService(),
            initialState: PostInteractionState(
                postID: post.id,
                isLiked: post.isLiked,
                likeCount: post.likeCount,
                commentCount: post.commentCount
            ),
            currentUserIDProvider: { 0 }
        )
    }
}

struct ProfilePostRowView: View {
    let post: FeedPost

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let firstMedia = post.media.first {
                AsyncImage(url: URL(string: firstMedia.mediaURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .squaredFrame(size: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .squaredFrame(size: 60)
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .squaredFrame(size: 60)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                    Spacer()
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct DummyInteractionService: InteractionServiceProtocol {
    func toggleLike(postID: Int64) async throws -> ToggleLikeResponse {
        ToggleLikeResponse(isLiked: false, likeCount: 0)
    }
    func listComments(postID: Int64, offset: Int, limit: Int) async throws -> CommentPage {
        CommentPage(items: [], hasMore: false)
    }
    func createComment(postID: Int64, content: String) async throws -> InteractionComment {
        InteractionComment(id: 0, postID: postID, userID: 0, content: content, createdAt: Date())
    }
}

extension View {
    func squaredFrame(size: CGFloat) -> some View {
        frame(width: size, height: size)
    }
}
