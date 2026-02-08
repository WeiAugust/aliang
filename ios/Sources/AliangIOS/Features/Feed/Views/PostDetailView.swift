import SwiftUI

public struct PostDetailView: View {
    @State private var post: FeedPost

    @StateObject private var interactionViewModel: InteractionViewModel
    @State private var commentDraft = ""

    private let onInteractionStateChange: ((PostInteractionState) -> Void)?

    public init(
        post: FeedPost,
        interactionViewModel: @autoclosure @escaping () -> InteractionViewModel,
        onInteractionStateChange: ((PostInteractionState) -> Void)? = nil
    ) {
        _post = State(initialValue: post)
        _interactionViewModel = StateObject(wrappedValue: interactionViewModel())
        self.onInteractionStateChange = onInteractionStateChange
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Author header
                    authorHeader
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)

                    // Media
                    if !post.media.isEmpty {
                        PostMediaGridView(media: post.media, cellHeight: 360, cornerRadius: 0)
                            .clipped()
                    }

                    // Interaction bar
                    interactionBar
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)

                    // Title & Content
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(post.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)

                        if !post.content.isEmpty {
                            Text(post.content)
                                .font(.body)
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            Text(PostTimestampFormatter.relativeText(for: post.createdAt, relativeTo: context.date))
                                .font(.caption)
                                .foregroundStyle(Color.appTextTertiary)
                                .padding(.top, AppSpacing.xs)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.lg)

                    AppDivider()

                    // Comments section
                    commentsSection
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.lg)
                        .padding(.bottom, 100)
                }
            }

            // Comment composer pinned to bottom
            commentComposer
        }
        .background(Color.appSurface.ignoresSafeArea())
        .navigationTitle("Post")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await interactionViewModel.loadInitialComments()
        }
        .onChange(of: interactionViewModel.state) { oldValue, newValue in
            guard oldValue != newValue else { return }
            applyInteractionStateToPost(newValue)
            onInteractionStateChange?(newValue)
        }
        .alert(
            "Action Failed",
            isPresented: Binding(
                get: { interactionViewModel.errorMessage != nil },
                set: { show in
                    if !show {
                        interactionViewModel.clearError()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                interactionViewModel.clearError()
            }
        } message: {
            Text(interactionViewModel.errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Author Header

    private var authorHeader: some View {
        HStack(spacing: AppSpacing.md) {
            AppAvatarView(url: post.author?.avatarURL, size: AppAvatar.medium)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(post.author?.nickname ?? "User \(post.userID)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextTertiary)
        }
    }

    // MARK: - Interaction Bar

    private var interactionBar: some View {
        HStack(spacing: AppSpacing.xl) {
            AnimatedLikeButton(
                isLiked: interactionViewModel.state.isLiked,
                count: interactionViewModel.state.likeCount,
                action: {
                    Task { await interactionViewModel.toggleLike() }
                }
            )
            .disabled(interactionViewModel.state.isLikeUpdating)

            InteractionButton(
                icon: "bubble.right",
                count: interactionViewModel.state.commentCount
            )

            InteractionButton(icon: "paperplane", count: 0)

            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    // MARK: - Comment Composer

    private var commentComposer: some View {
        VStack(spacing: 0) {
            AppDivider()

            HStack(alignment: .bottom, spacing: AppSpacing.md) {
                AppAvatarView(url: nil, size: AppAvatar.small)

                TextField("Add a comment...", text: $commentDraft, axis: .vertical)
                    .lineLimit(1 ... 4)
                    .font(.subheadline)
                    .padding(.vertical, AppSpacing.sm)

                Button {
                    submitComment()
                } label: {
                    Text(interactionViewModel.isSubmittingComment ? "..." : "Post")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.appAccent.opacity(0.4)
                                : Color.appAccent
                        )
                }
                .disabled(
                    commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        interactionViewModel.isSubmittingComment
                )
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if interactionViewModel.comments.isEmpty {
                if interactionViewModel.isLoadingComments {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.appAccent)
                            .padding(.vertical, AppSpacing.xl)
                        Spacer()
                    }
                } else {
                    VStack(spacing: AppSpacing.sm) {
                        Text("No comments yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Start the conversation.")
                            .font(.caption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xxl)
                }
            } else {
                ForEach(interactionViewModel.comments) { comment in
                    commentRow(comment)
                        .onAppear {
                            loadMoreCommentsIfNeeded(triggeredBy: comment)
                        }
                }

                if interactionViewModel.canLoadMoreComments && interactionViewModel.isLoadingComments {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.appAccent)
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
        }
    }

    private func commentRow(_ comment: InteractionComment) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            AppAvatarView(url: nil, size: AppAvatar.small)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text("User \(comment.userID)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(PostTimestampFormatter.relativeText(for: comment.createdAt, relativeTo: context.date))
                            .font(.caption2)
                            .foregroundStyle(Color.appTextTertiary)
                    }

                    if comment.isPending {
                        Text("Sending...")
                            .font(.caption2)
                            .foregroundStyle(Color.appAccentLight)
                    }
                }

                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Actions

    private func submitComment() {
        let content = commentDraft
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        commentDraft = ""
        Task {
            await interactionViewModel.submitComment(content: content)
            if interactionViewModel.errorMessage != nil {
                commentDraft = content
            }
        }
    }

    private func loadMoreCommentsIfNeeded(triggeredBy comment: InteractionComment) {
        guard comment.id == interactionViewModel.comments.last?.id else { return }
        guard interactionViewModel.canLoadMoreComments else { return }

        Task {
            await interactionViewModel.loadMoreCommentsIfNeeded()
        }
    }

    private func applyInteractionStateToPost(_ state: PostInteractionState) {
        guard post.id == state.postID else { return }
        post = FeedPost(
            id: post.id,
            userID: post.userID,
            title: post.title,
            content: post.content,
            postType: post.postType,
            likeCount: state.likeCount,
            commentCount: state.commentCount,
            isLiked: state.isLiked,
            createdAt: post.createdAt,
            author: post.author,
            media: post.media
        )
    }
}
