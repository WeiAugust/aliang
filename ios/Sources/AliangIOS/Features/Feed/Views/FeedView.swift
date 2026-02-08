import SwiftUI
import Combine

public struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var showComposer = false
    private let interactionService: InteractionServiceProtocol
    private let currentUserIDProvider: () -> Int64
    private let onLogout: (() -> Void)?
    private let composerService: ComposerService

    public init(
        viewModel: @autoclosure @escaping () -> FeedViewModel,
        interactionService: InteractionServiceProtocol,
        composerService: ComposerService,
        currentUserIDProvider: @escaping () -> Int64 = { 0 },
        onLogout: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.interactionService = interactionService
        self.composerService = composerService
        self.currentUserIDProvider = currentUserIDProvider
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading, viewModel.posts.isEmpty {
                    loadingState
                } else if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    feedList
                }
            }
            .background(Color.appSurface.ignoresSafeArea())
            .navigationTitle("Home")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showComposer = true
                    } label: {
                        Image(systemName: "plus.app")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }
                if let onLogout {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            onLogout()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showComposer) {
                NavigationStack {
                    ComposerView(viewModel: ComposerViewModel(composerService: composerService))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    showComposer = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Color.appTextPrimary)
                                }
                            }
                        }
                }
            }
            #endif
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostPublished"))) { _ in
                showComposer = false
                Task {
                    await viewModel.refresh()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.onAppearLoadIfNeeded()
            }
            .alert(
                "Load Failed",
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
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.selectedPost != nil },
                    set: { show in
                        if !show {
                            viewModel.closePostDetail()
                        }
                    }
                )
            ) {
                if let post = viewModel.selectedPost {
                    PostDetailView(
                        post: post,
                        interactionViewModel: makeInteractionViewModel(for: post),
                        onInteractionStateChange: { state in
                            viewModel.applyInteractionState(state)
                        }
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 50)
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    Button {
                        Task {
                            await viewModel.openPostDetail(postID: post.id)
                        }
                    } label: {
                        FeedRowView(post: post)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(currentPost: post)
                        }
                    }
                }

                if viewModel.isLoadingMore {
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
        .scrollIndicators(.hidden)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.appAccent)
            Text("Loading feed...")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.appTextTertiary)

            Text("No posts yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            Text(viewModel.errorMessage ?? "Pull down to refresh")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    static func buildInitialInteractionState(for post: FeedPost) -> PostInteractionState {
        PostInteractionState(
            postID: post.id,
            isLiked: post.isLiked,
            likeCount: post.likeCount,
            commentCount: post.commentCount
        )
    }

    private func makeInteractionViewModel(for post: FeedPost) -> InteractionViewModel {
        let currentUserID = currentUserIDProvider()

        return InteractionViewModel(
            interactionService: interactionService,
            initialState: Self.buildInitialInteractionState(for: post),
            currentUserIDProvider: { currentUserID }
        )
    }
}
