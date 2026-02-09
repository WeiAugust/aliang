import SwiftUI

public struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    private let interactionService: InteractionServiceProtocol
    private let currentUserIDProvider: () -> Int64
    @State private var searchDebounceTask: Task<Void, Never>?

    public init(
        viewModel: @autoclosure @escaping () -> SearchViewModel,
        interactionService: InteractionServiceProtocol,
        currentUserIDProvider: @escaping () -> Int64 = { 0 }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.interactionService = interactionService
        self.currentUserIDProvider = currentUserIDProvider
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                AppDivider()

                if !viewModel.searchQuery.isEmpty {
                    searchResultsView
                } else if let hashtag = viewModel.selectedHashtag {
                    hashtagPostsView(for: hashtag)
                } else {
                    trendingHashtagsView
                }
            }
            .background(Color.appSurface.ignoresSafeArea())
            .navigationTitle("Search")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadTrendingHashtags()
            }
            .onDisappear {
                searchDebounceTask?.cancel()
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
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 50)
        }
    }

    // MARK: - Search Bar

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appTextTertiary)

                TextField("Search posts...", text: Binding(
                    get: { viewModel.searchQuery },
                    set: { newValue in
                        viewModel.searchQuery = newValue
                        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.clearSearch()
                        } else {
                            scheduleSearch()
                        }
                    }
                ))
                .textFieldStyle(.plain)
                .font(.subheadline)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .submitLabel(.search)
                .onSubmit {
                    runSearchImmediately()
                }

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                        searchDebounceTask?.cancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(Color.appInputBackground)
            )

            if !viewModel.searchQuery.isEmpty {
                Button("Cancel") {
                    searchDebounceTask?.cancel()
                    viewModel.clearSearch()
                }
                .font(.subheadline)
                .foregroundStyle(Color.appAccent)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: !viewModel.searchQuery.isEmpty)
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsView: some View {
        if viewModel.isSearching, viewModel.searchResults.isEmpty {
            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.appAccent)
                Text("Searching...")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.searchResults.isEmpty {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(Color.appTextTertiary)
                Text("No results")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            searchResultsList
        }
    }

    @ViewBuilder
    private var searchResultsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
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
                    .buttonStyle(.plain)
                    .onAppear {
                        guard post.id == viewModel.searchResults.last?.id else { return }
                        Task {
                            await viewModel.loadMoreSearchResults()
                        }
                    }
                }

                if viewModel.isSearching {
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

    // MARK: - Trending Hashtags

    @ViewBuilder
    private var trendingHashtagsView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("TRENDING")
                    .appSectionHeader()
                    .padding(.horizontal, AppSpacing.lg)

                if viewModel.isLoadingTrending {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.appAccent)
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.xxl)
                } else if viewModel.trendingHashtags.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "flame")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundStyle(Color.appTextTertiary)
                        Text("No trending hashtags")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xxl)
                } else {
                    flowLayoutHashtags
                }
            }
            .padding(.top, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var flowLayoutHashtags: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.trendingHashtags) { hashtag in
                Button {
                    viewModel.selectHashtag(hashtag)
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.appInputBackground)
                                .frame(width: 44, height: 44)
                            Image(systemName: "number")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.appTextPrimary)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text("#\(hashtag.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)

                            if let count = hashtag.postCount {
                                Text("\(count) posts")
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextTertiary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextTertiary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                }
                .buttonStyle(.plain)

                AppDivider()
                    .padding(.leading, 72)
            }
        }
    }

    // MARK: - Hashtag Posts

    @ViewBuilder
    private func hashtagPostsView(for hashtag: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.appBrandGradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: "number")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("#\(hashtag)")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.appInputBackground, in: Circle())
                }
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
    }

    // MARK: - Helpers

    private func scheduleSearch() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
    }

    private func runSearchImmediately() {
        searchDebounceTask?.cancel()
        Task {
            await viewModel.search()
        }
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

// MARK: - Search Result Row

struct SearchResultRowView: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                // Text content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(post.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)

                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: AppSpacing.md) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "heart")
                                .font(.system(size: 11))
                            Text("\(post.likeCount)")
                        }
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 11))
                            Text("\(post.commentCount)")
                        }

                        Spacer()

                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            Text(PostTimestampFormatter.relativeText(for: post.createdAt, relativeTo: context.date))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.appTextTertiary)
                }

                // Thumbnail
                if let firstMedia = post.media.first {
                    AsyncImage(url: URL(string: firstMedia.displayURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            thumbnailFallback(for: firstMedia)
                        case .empty:
                            thumbnailFallback(for: firstMedia)
                        @unknown default:
                            thumbnailFallback(for: firstMedia)
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            AppDivider()
                .padding(.leading, AppSpacing.lg)
        }
    }

    private func thumbnailFallback(for media: FeedMedia) -> some View {
        ZStack {
            Color.appInputBackground
            Image(systemName: media.mediaType.lowercased() == "video" ? "video" : "photo")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextTertiary)
        }
    }
}
