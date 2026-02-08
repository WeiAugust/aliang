import SwiftUI

public struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    private let interactionService: InteractionServiceProtocol

    public init(
        viewModel: @autoclosure @escaping () -> SearchViewModel,
        interactionService: InteractionServiceProtocol
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.interactionService = interactionService
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if !viewModel.searchQuery.isEmpty {
                    searchResultsView
                } else if let hashtag = viewModel.selectedHashtag {
                    hashtagPostsView(for: hashtag)
                } else {
                    trendingHashtagsView
                }
            }
            .navigationTitle("Search")
            .task {
                await viewModel.loadTrendingHashtags()
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
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search posts...", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { newValue in
                        viewModel.searchQuery = newValue
                        if newValue.isEmpty {
                            viewModel.clearSearch()
                        }
                    }
                ))
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !viewModel.searchQuery.isEmpty {
                Button("Cancel") {
                    viewModel.clearSearch()
                }
                .foregroundStyle(.blue)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var searchResultsView: some View {
        if viewModel.isSearching, viewModel.searchResults.isEmpty {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.searchResults.isEmpty {
            ContentUnavailableView(
                "No results",
                systemImage: "magnifyingglass",
                description: Text("Try a different search term")
            )
        } else {
            searchResultsList
        }
    }

    @ViewBuilder
    private var searchResultsList: some View {
        List {
            ForEach(viewModel.searchResults) { post in
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
                        await viewModel.loadMoreSearchResults()
                    }
                }
            }

            if viewModel.isSearching {
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

    @ViewBuilder
    private var trendingHashtagsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text("Trending Hashtags")
                    .font(.headline)
                    .padding(.horizontal)

                if viewModel.isLoadingTrending {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.trendingHashtags.isEmpty {
                    Text("No trending hashtags")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    flowLayoutHashtags
                }
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private var flowLayoutHashtags: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 8)
        ], spacing: 8) {
            ForEach(viewModel.trendingHashtags) { hashtag in
                Button {
                    viewModel.selectHashtag(hashtag)
                } label: {
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(.orange)
                        Text("#\(hashtag.name)")
                            .fontWeight(.medium)
                        Spacer()
                        if let count = hashtag.postCount {
                            Text("\(count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    #if os(iOS)
                    .background(Color(.secondarySystemBackground))
                    #else
                    .background(Color(nsColor: .controlBackgroundColor))
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func hashtagPostsView(for hashtag: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "number")
                    .foregroundStyle(.blue)
                Text("#\(hashtag)")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark")
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

struct SearchResultRowView: View {
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

                Text(post.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                    Spacer()
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
