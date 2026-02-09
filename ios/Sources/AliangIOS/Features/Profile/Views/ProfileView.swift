import SwiftUI

public struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    private let interactionService: InteractionServiceProtocol
    private let currentUserIDProvider: () -> Int64
    private let onLogout: (() -> Void)?

    public init(
        viewModel: @autoclosure @escaping () -> ProfileViewModel,
        interactionService: InteractionServiceProtocol,
        currentUserIDProvider: @escaping () -> Int64,
        onLogout: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.interactionService = interactionService
        self.currentUserIDProvider = currentUserIDProvider
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    profileHeader

                    if viewModel.isLoadingProfile, viewModel.profile == nil {
                        VStack(spacing: AppSpacing.lg) {
                            ProgressView()
                                .controlSize(.large)
                                .tint(Color.appAccent)
                            Text("Loading profile...")
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }

                    postsSection
                }
                .padding(.bottom, 60)
            }
            .background(Color.appSurface.ignoresSafeArea())
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    if viewModel.isMyProfile, let onLogout = onLogout {
                        Button {
                            onLogout()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
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

    // MARK: - Profile Header

    @ViewBuilder
    private var profileHeader: some View {
        if let profile = viewModel.profile {
            VStack(spacing: AppSpacing.xl) {
                // Avatar + Stats row
                HStack(spacing: AppSpacing.xxl) {
                    AppAvatarView(
                        url: profile.avatarURL,
                        size: AppAvatar.xlarge,
                        showBorder: true
                    )

                    // Stats
                    HStack(spacing: 0) {
                        statColumn(value: viewModel.effectivePostCount, label: "Posts")

                        Spacer()

                        if let createdAt = validJoinDate(profile.createdAt) {
                            VStack(spacing: AppSpacing.xs) {
                                Text("Joined")
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextTertiary)
                                Text(createdAt, style: .date)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }

                // Name + Bio
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(profile.nickname)
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Action buttons
                HStack(spacing: AppSpacing.sm) {
                    if viewModel.isMyProfile {
                        Button {
                        } label: {
                            Text("Edit Profile")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                        .fill(Color.appInputBackground)
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                        } label: {
                            Text("Share Profile")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                        .fill(Color.appInputBackground)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.xl)

            AppDivider()
        }
    }

    // MARK: - Posts Section

    @ViewBuilder
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header with grid icon
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "square.grid.3x3")
                    .font(.system(size: 14, weight: .medium))
                Text("POSTS")
                    .appSectionHeader()
            }
            .foregroundStyle(Color.appTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)

            AppDivider()

            if viewModel.posts.isEmpty, !viewModel.isLoadingPosts {
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "camera")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color.appTextTertiary)

                    Text("No posts yet")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Posts will appear here")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Grid layout for posts
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                ], spacing: 2) {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            PostDetailView(
                                post: post,
                                interactionViewModel: makeInteractionViewModel(for: post),
                                onInteractionStateChange: { _ in }
                            )
                        } label: {
                            ProfileGridCell(post: post)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            Task {
                                await viewModel.loadMoreIfNeeded(currentPost: post)
                            }
                        }
                    }
                }

                if viewModel.isLoadingPosts {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.appAccent)
                            .padding(.vertical, AppSpacing.xl)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func statColumn(value: Int, label: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.appTextTertiary)
        }
    }

    private func validJoinDate(_ date: Date) -> Date? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) || calendar.isDateInYesterday(date) {
            return nil
        }
        return date
    }

    private func makeInteractionViewModel(for post: FeedPost) -> InteractionViewModel {
        let currentUserID = currentUserIDProvider()
        return InteractionViewModel(
            interactionService: interactionService,
            initialState: PostInteractionState(
                postID: post.id,
                isLiked: post.isLiked,
                likeCount: post.likeCount,
                commentCount: post.commentCount
            ),
            currentUserIDProvider: { currentUserID }
        )
    }
}

// MARK: - Profile Grid Cell

struct ProfileGridCell: View {
    let post: FeedPost

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                if let firstMedia = post.media.first {
                    AsyncImage(url: URL(string: firstMedia.mediaURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.width)
                                .clipped()
                        case .failure, .empty:
                            cellPlaceholder(title: post.title)
                        @unknown default:
                            Color.appShimmer
                        }
                    }
                } else {
                    cellPlaceholder(title: post.title)
                }

                // Multi-media indicator
                if post.media.count > 1 {
                    Image(systemName: "square.fill.on.square.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellPlaceholder(title: String) -> some View {
        ZStack {
            Color.appInputBackground
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(AppSpacing.sm)
        }
    }
}
extension View {
    func squaredFrame(size: CGFloat) -> some View {
        frame(width: size, height: size)
    }
}
