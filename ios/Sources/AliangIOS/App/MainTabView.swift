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
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    FeedView(
                        viewModel: feedViewModel,
                        interactionService: interactionService,
                        composerService: composerService
                    )
                case 1:
                    SearchView(
                        viewModel: searchViewModel,
                        interactionService: interactionService
                    )
                case 2:
                    ProfileView(
                        viewModel: profileViewModel,
                        onLogout: onLogout
                    )
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostPublished"))) { _ in
            selectedTab = 0
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "house", selectedIcon: "house.fill", label: "Home", tag: 0)
            tabBarItem(icon: "magnifyingglass", selectedIcon: "magnifyingglass", label: "Search", tag: 1)
            tabBarItem(icon: "person", selectedIcon: "person.fill", label: "Profile", tag: 2)
        }
        .padding(.horizontal, AppSpacing.xxl)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    AppDivider()
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabBarItem(icon: String, selectedIcon: String, label: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: selectedTab == tag ? selectedIcon : icon)
                    .font(.system(size: 22, weight: selectedTab == tag ? .semibold : .regular))
                    .symbolEffect(.bounce, value: selectedTab == tag)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tag ? Color.appTextPrimary : Color.appTextTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
