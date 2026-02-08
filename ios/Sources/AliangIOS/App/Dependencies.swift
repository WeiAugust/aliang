import Foundation

@MainActor
public struct Dependencies {
    public let config: AppConfig
    public let tokenStore: TokenStore
    public let session: AppSession
    public let httpClient: HTTPClientProtocol
    public let authService: AuthServiceProtocol
    public let feedService: FeedServiceProtocol
    public let profileService: ProfileServiceProtocol
    public let searchService: SearchServiceProtocol
    public let composerService: ComposerService
    public let interactionService: InteractionServiceProtocol
    public let trackFRegressionRunner: TrackFRegressionRunner

    public init(config: AppConfig = AppConfig()) {
        self.config = config

        let tokenStore = KeychainTokenStore()
        self.tokenStore = tokenStore

        let session = AppSession(tokenStore: tokenStore)
        self.session = session

        let client = HTTPClient(baseURL: config.baseAPIURL)
        self.httpClient = client

        self.authService = AuthService(httpClient: client)
        self.feedService = FeedService(
            httpClient: client,
            tokenProvider: {
                (try? tokenStore.readToken()) ?? nil
            }
        )

        self.profileService = ProfileService(
            httpClient: client,
            tokenProvider: {
                (try? tokenStore.readToken()) ?? nil
            }
        )

        self.searchService = SearchService(
            httpClient: client,
            tokenProvider: {
                (try? tokenStore.readToken()) ?? nil
            }
        )

        let composerTokenProvider = TokenStoreComposerTokenProvider(tokenStore: tokenStore)
        let composerAPIClient = URLSessionComposerAPIClient(
            baseURL: config.baseAPIURL,
            tokenProvider: composerTokenProvider
        )
        self.composerService = ComposerService(apiClient: composerAPIClient)

        self.interactionService = InteractionService(
            httpClient: client,
            tokenProvider: {
                (try? tokenStore.readToken()) ?? nil
            }
        )

        self.trackFRegressionRunner = TrackFRegressionRunner(
            authService: authService,
            session: session,
            feedService: feedService,
            composerService: composerService,
            interactionService: interactionService
        )
    }
}

private struct TokenStoreComposerTokenProvider: ComposerTokenProvider {
    private let tokenStore: any TokenStore

    init(tokenStore: any TokenStore) {
        self.tokenStore = tokenStore
    }

    func authToken() -> String? {
        (try? tokenStore.readToken()) ?? nil
    }
}
