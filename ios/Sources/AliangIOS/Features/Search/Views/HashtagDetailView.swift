import SwiftUI

public struct HashtagDetailView: View {
    let hashtag: TrendingHashtag
    @StateObject private var viewModel: SearchViewModel
    private let interactionService: InteractionServiceProtocol

    public init(
        hashtag: TrendingHashtag,
        searchService: SearchServiceProtocol,
        interactionService: InteractionServiceProtocol
    ) {
        self.hashtag = hashtag
        _viewModel = StateObject(wrappedValue: SearchViewModel(service: searchService))
        self.interactionService = interactionService
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.appBrandGradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: "number")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("#\(hashtag.name)")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    if let count = hashtag.postCount {
                        Text("\(count) posts")
                            .font(.caption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            AppDivider()

            if viewModel.hashtagPosts.isEmpty, !viewModel.isLoadingHashtagPosts {
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color.appTextTertiary)
                    Text("No posts")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("No posts with this hashtag")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.hashtagPosts) { post in
                            NavigationLink {
                                PostDetailView(
                                    post: post,
                                    interactionViewModel: makeInteractionViewModel(for: post),
                                    onInteractionStateChange: { _ in }
                                )
                            } label: {
                                SearchResultRowView(post: post)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentPost: post)
                                }
                            }
                        }

                        if viewModel.isLoadingHashtagPosts {
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
        }
        .background(Color.appSurface.ignoresSafeArea())
        .navigationTitle("Hashtag")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            viewModel.selectHashtag(hashtag)
        }
    }

    private func makeInteractionViewModel(for post: FeedPost) -> InteractionViewModel {
        InteractionViewModel(
            interactionService: interactionService,
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
