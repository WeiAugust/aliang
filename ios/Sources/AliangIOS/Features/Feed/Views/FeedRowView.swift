import SwiftUI

struct FeedRowView: View {
    let post: FeedPost
    let interactionService: InteractionServiceProtocol
    let onOpenPost: () -> Void
    let onOpenComments: () -> Void
    let onInteractionStateChange: (PostInteractionState) -> Void

    @State private var interactionState: PostInteractionState

    init(
        post: FeedPost,
        interactionService: InteractionServiceProtocol,
        onOpenPost: @escaping () -> Void,
        onOpenComments: @escaping () -> Void,
        onInteractionStateChange: @escaping (PostInteractionState) -> Void
    ) {
        self.post = post
        self.interactionService = interactionService
        self.onOpenPost = onOpenPost
        self.onOpenComments = onOpenComments
        self.onInteractionStateChange = onInteractionStateChange
        _interactionState = State(initialValue: Self.makeInteractionState(from: post))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpenPost) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    AppAvatarView(url: post.author?.avatarURL, size: AppAvatar.medium)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: AppSpacing.sm) {
                            Text(post.author?.nickname ?? "User \(post.userID)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)

                            TimelineView(.periodic(from: .now, by: 60)) { context in
                                Text(PostTimestampFormatter.relativeText(for: post.createdAt, relativeTo: context.date))
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextTertiary)
                            }

                            Spacer(minLength: 0)
                        }

                        Text(post.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .foregroundStyle(Color.appTextPrimary)

                        if !post.content.isEmpty {
                            Text(post.content)
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                                .lineLimit(2)
                        }
                    }

                    if let firstMedia = post.media.first {
                        FeedThumbnailView(media: firstMedia, mediaCount: post.media.count)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            }
            .buttonStyle(.plain)

            HStack(spacing: AppSpacing.xl) {
                AnimatedLikeButton(
                    isLiked: interactionState.isLiked,
                    count: interactionState.likeCount,
                    action: toggleLike
                )
                .disabled(interactionState.isLikeUpdating)

                InteractionButton(
                    icon: "bubble.right",
                    count: interactionState.commentCount,
                    action: onOpenComments
                )

                Spacer()

                if post.media.count > 1 {
                    Text("\(post.media.count) photos")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            AppDivider()
        }
        .onChange(of: post) { _, newPost in
            guard !interactionState.isLikeUpdating else { return }
            interactionState = Self.makeInteractionState(from: newPost)
        }
    }

    private static func makeInteractionState(from post: FeedPost) -> PostInteractionState {
        PostInteractionState(
            postID: post.id,
            isLiked: post.isLiked,
            likeCount: post.likeCount,
            commentCount: post.commentCount
        )
    }

    private func toggleLike() {
        guard !interactionState.isLikeUpdating else {
            return
        }

        let rollbackState = interactionState

        interactionState.isLikeUpdating = true
        if interactionState.isLiked {
            interactionState.isLiked = false
            interactionState.likeCount = max(0, interactionState.likeCount - 1)
        } else {
            interactionState.isLiked = true
            interactionState.likeCount += 1
        }
        onInteractionStateChange(interactionState)

        Task {
            do {
                let result = try await interactionService.toggleLike(postID: post.id)
                await MainActor.run {
                    interactionState.isLiked = result.isLiked
                    interactionState.likeCount = max(0, result.likeCount ?? interactionState.likeCount)
                    interactionState.isLikeUpdating = false
                    onInteractionStateChange(interactionState)
                }
            } catch {
                await MainActor.run {
                    interactionState = rollbackState
                    onInteractionStateChange(interactionState)
                }
            }
        }
    }
}

private struct FeedThumbnailView: View {
    let media: FeedMedia
    let mediaCount: Int

    private var displayURL: String {
        media.thumbnailURL ?? media.mediaURL
    }

    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: displayURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    Color.appShimmer
                @unknown default:
                    Color.appShimmer
                }
            }

            if media.mediaType.lowercased() == "video" {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if mediaCount > 1 {
                Text("+\(mediaCount - 1)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(6)
            }
        }
    }
}
