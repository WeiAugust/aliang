import SwiftUI
import Combine

public struct MainTabView: View {
    @StateObject private var feedViewModel: FeedViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var searchViewModel: SearchViewModel
    private let interactionService: InteractionServiceProtocol
    private let composerService: ComposerService
    private let onLogout: (() -> Void)?
    @State private var selectedTab = 0
    @State private var postPublishedTrigger = false

    public init(
        feedService: FeedServiceProtocol,
        profileService: ProfileServiceProtocol,
        searchService: SearchServiceProtocol,
        interactionService: InteractionServiceProtocol,
        composerService: ComposerService,
        onLogout: (() -> Void)? = nil
    ) {
        _feedViewModel = StateObject(wrappedValue: FeedViewModel(service: feedService))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(service: profileService))
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(service: searchService))
        self.interactionService = interactionService
        self.composerService = composerService
        self.onLogout = onLogout
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(
                viewModel: feedViewModel,
                interactionService: interactionService,
                composerService: composerService
            )
            .tabItem {
                Label("Feed", systemImage: "house")
            }
            .tag(0)

            SearchView(
                viewModel: searchViewModel,
                interactionService: interactionService
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)

            ProfileView(
                viewModel: profileViewModel,
                onLogout: onLogout
            )
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(2)
        }
        .onReceive(Just(postPublishedTrigger)) { _ in
            postPublishedTrigger = false
            selectedTab = 0
            Task {
                await feedViewModel.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostPublished"))) { _ in
            postPublishedTrigger = true
        }
    }
}
