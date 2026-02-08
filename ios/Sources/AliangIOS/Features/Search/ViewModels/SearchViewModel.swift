import Foundation
import SwiftUI

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var searchQuery = ""
    @Published public private(set) var trendingHashtags: [TrendingHashtag] = []
    @Published public private(set) var searchResults: [FeedPost] = []
    @Published public private(set) var hashtagPosts: [FeedPost] = []
    @Published public private(set) var isLoadingTrending = false
    @Published public private(set) var isSearching = false
    @Published public private(set) var isLoadingHashtagPosts = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var hasMoreSearchResults = true
    @Published public private(set) var hasMoreHashtagPosts = true

    private let service: SearchServiceProtocol
    private let pageSize: Int
    private let trendingLimit: Int

    public init(
        service: SearchServiceProtocol,
        pageSize: Int = 20,
        trendingLimit: Int = 10
    ) {
        self.service = service
        self.pageSize = pageSize
        self.trendingLimit = trendingLimit
    }

    public var selectedHashtag: String?

    public func loadTrendingHashtags() async {
        guard !isLoadingTrending else { return }
        isLoadingTrending = true
        errorMessage = nil

        do {
            trendingHashtags = try await service.getTrendingHashtags(limit: trendingLimit)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingTrending = false
    }

    public func search() async {
        let normalizedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        searchQuery = normalizedQuery

        guard !normalizedQuery.isEmpty else {
            searchResults = []
            hasMoreSearchResults = true
            return
        }

        guard !isSearching else { return }
        isSearching = true
        errorMessage = nil

        do {
            let result = try await service.searchPosts(
                query: normalizedQuery,
                offset: 0,
                limit: pageSize
            )
            searchResults = result.items
            hasMoreSearchResults = result.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    public func loadMoreSearchResults() async {
        guard hasMoreSearchResults,
              !isSearching,
              !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isSearching = true

        do {
            let result = try await service.searchPosts(
                query: searchQuery,
                offset: searchResults.count,
                limit: pageSize
            )
            searchResults.append(contentsOf: result.items)
            hasMoreSearchResults = result.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    public func selectHashtag(_ hashtag: TrendingHashtag) {
        selectedHashtag = hashtag.name
        hashtagPosts = []
        hasMoreHashtagPosts = true
        Task {
            await loadHashtagPosts()
        }
    }

    public func loadHashtagPosts(refresh: Bool = false) async {
        guard let hashtag = selectedHashtag else { return }

        if refresh {
            hashtagPosts = []
            hasMoreHashtagPosts = true
        }

        guard hasMoreHashtagPosts else { return }

        guard !isLoadingHashtagPosts else { return }
        isLoadingHashtagPosts = true
        errorMessage = nil

        do {
            let result = try await service.getPostsByHashtag(
                name: hashtag,
                offset: hashtagPosts.count,
                limit: pageSize
            )
            hashtagPosts.append(contentsOf: result.items)
            hasMoreHashtagPosts = result.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingHashtagPosts = false
    }

    public func loadMoreIfNeeded(currentPost: FeedPost) async {
        guard selectedHashtag != nil else { return }

        guard let lastPost = hashtagPosts.last,
              lastPost.id == currentPost.id,
              hasMoreHashtagPosts,
              !isLoadingHashtagPosts else {
            return
        }
        await loadHashtagPosts()
    }

    public func clearSearch() {
        searchQuery = ""
        searchResults = []
        hasMoreSearchResults = true
        selectedHashtag = nil
        hashtagPosts = []
        hasMoreHashtagPosts = true
    }

    public func clearError() {
        errorMessage = nil
    }
}
