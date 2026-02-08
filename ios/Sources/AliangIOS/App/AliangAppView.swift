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
                VStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.appBrandGradient)
                            .frame(width: 64, height: 64)
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    ProgressView()
                        .tint(Color.appAccent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appSurface.ignoresSafeArea())
            case .authenticated:
                MainTabView(
                    feedService: dependencies.feedService,
                    profileService: dependencies.profileService,
                    searchService: dependencies.searchService,
                    interactionService: dependencies.interactionService,
                    composerService: dependencies.composerService,
                    currentUserIDProvider: {
                        session.currentUserID ?? 0
                    },
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
