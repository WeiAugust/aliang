import SwiftUI

public struct PostDetailView: View {
    let post: FeedPost

    @StateObject private var interactionViewModel: InteractionViewModel
    @State private var commentDraft = ""

    private let onInteractionStateChange: ((PostInteractionState) -> Void)?

    public init(
        post: FeedPost,
        interactionViewModel: @autoclosure @escaping () -> InteractionViewModel,
        onInteractionStateChange: ((PostInteractionState) -> Void)? = nil
    ) {
        self.post = post
        _interactionViewModel = StateObject(wrappedValue: interactionViewModel())
        self.onInteractionStateChange = onInteractionStateChange
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                HStack(spacing: 12) {
                    Text(post.author?.nickname ?? "User \(post.userID)")
                        .font(.subheadline)
                    Text(post.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if post.content.isEmpty == false {
                    Text(post.content)
                        .font(.body)
                }

                if post.media.isEmpty == false {
                    Text("Media")
                        .font(.headline)

                    ForEach(post.media) { media in
                        VStack(alignment: .leading, spacing: 4) {
                            if media.mediaType.lowercased() == "image" {
                                AsyncImage(url: URL(string: media.mediaURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    case .failure:
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.title)
                                            Text(media.mediaURL)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    case .empty:
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    @unknown default:
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                            } else {
                                VStack {
                                    Image(systemName: "video")
                                        .font(.title)
                                    Text("Video URL")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                Divider()

                interactionBar

                Divider()

                commentComposer

                commentsSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Post Detail")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            await interactionViewModel.loadInitialComments()
        }
        .onChange(of: interactionViewModel.state) { oldValue, newValue in
            guard oldValue != newValue else { return }
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

    private var interactionBar: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await interactionViewModel.toggleLike()
                }
            } label: {
                Label(
                    "\(interactionViewModel.state.likeCount)",
                    systemImage: interactionViewModel.state.isLiked ? "heart.fill" : "heart"
                )
            }
            .disabled(interactionViewModel.state.isLikeUpdating)
            .foregroundStyle(interactionViewModel.state.isLiked ? .red : .secondary)

            Label("\(interactionViewModel.state.commentCount)", systemImage: "bubble.right")
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
    }

    private var commentComposer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Add a comment...", text: $commentDraft, axis: .vertical)
                .lineLimit(1 ... 4)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(interactionViewModel.isSubmittingComment ? "Sending..." : "Send") {
                submitComment()
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    interactionViewModel.isSubmittingComment
            )
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comments")
                .font(.headline)

            if interactionViewModel.comments.isEmpty {
                if interactionViewModel.isLoadingComments {
                    HStack {
                        Spacer()
                        ProgressView("Loading comments...")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func commentRow(_ comment: InteractionComment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("User \(comment.userID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(comment.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if comment.isPending {
                    Text("Sending...")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Text(comment.content)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private func submitComment() {
        let content = commentDraft
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        commentDraft = ""
        Task {
            await interactionViewModel.submitComment(content: content)
            if interactionViewModel.errorMessage != nil {
                commentDraft = content
            }
        }
    }

    private func loadMoreCommentsIfNeeded(triggeredBy comment: InteractionComment) {
        guard comment.id == interactionViewModel.comments.last?.id else {
            return
        }

        guard interactionViewModel.canLoadMoreComments else {
            return
        }

        Task {
            await interactionViewModel.loadMoreCommentsIfNeeded()
        }
    }
}
