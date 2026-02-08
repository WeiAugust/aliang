import SwiftUI

@MainActor
public struct AliangAppView: View {
    @StateObject private var session: AppSession
    private let dependencies: Dependencies

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
        _session = StateObject(wrappedValue: dependencies.session)
    }

    public var body: some View {
        Group {
            switch session.state {
            case .launching:
                ProgressView("Loading session…")
            case .authenticated:
                MainTabView(
                    feedService: dependencies.feedService,
                    profileService: dependencies.profileService,
                    searchService: dependencies.searchService,
                    interactionService: dependencies.interactionService,
                    composerService: dependencies.composerService,
                    onLogout: {
                        session.logout()
                    }
                )
            case .unauthenticated:
                AuthView(
                    viewModel: AuthViewModel(
                        authService: dependencies.authService,
                        session: session
                    )
                )
            }
        }
        .onAppear {
            session.bootstrap()
        }
    }
}

#Preview {
    AliangAppView(dependencies: Dependencies())
}
