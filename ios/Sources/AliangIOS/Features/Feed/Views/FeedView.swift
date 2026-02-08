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
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No posts yet",
                        systemImage: "tray",
                        description: Text(viewModel.errorMessage ?? "Pull to refresh later")
                    )
                } else {
                    List {
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
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showComposer = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                if let onLogout {
                    ToolbarItem(placement: .automatic) {
                        Button("Logout") {
                            onLogout()
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
                                Button("Cancel") {
                                    showComposer = false
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
    }

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
