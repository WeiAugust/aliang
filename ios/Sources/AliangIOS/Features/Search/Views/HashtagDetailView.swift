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
            HStack {
                Image(systemName: "number")
                    .foregroundStyle(.blue)
                Text("#\(hashtag.name)")
                    .font(.headline)
                if let count = hashtag.postCount {
                    Text("(\(count) posts)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            if viewModel.hashtagPosts.isEmpty, !viewModel.isLoadingHashtagPosts {
                ContentUnavailableView(
                    "No posts",
                    systemImage: "doc.text",
                    description: Text("No posts with this hashtag")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
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
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
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
