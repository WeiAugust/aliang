import Foundation

public enum TrackFStepStatus: String, Codable, Equatable, Sendable {
    case passed
    case failed
    case skipped
}

public struct TrackFStepResult: Equatable, Sendable {
    public let step: String
    public let status: TrackFStepStatus
    public let detail: String

    public init(step: String, status: TrackFStepStatus, detail: String) {
        self.step = step
        self.status = status
        self.detail = detail
    }
}

public struct TrackFRegressionReport: Equatable, Sendable {
    public let startedAt: Date
    public let finishedAt: Date
    public let steps: [TrackFStepResult]

    public init(startedAt: Date, finishedAt: Date, steps: [TrackFStepResult]) {
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.steps = steps
    }

    public var allPassed: Bool {
        steps.allSatisfy { $0.status == .passed || $0.status == .skipped }
    }
}

public struct TrackFReleaseChecklist: Equatable, Sendable {
    public let branch: String
    public let requiredTracks: [String]
    public let requiredTests: [String]
    public let manualChecks: [String]
    public let mergeRule: String

    public init(
        branch: String = "feat/ios-05-integration-qa",
        requiredTracks: [String],
        requiredTests: [String],
        manualChecks: [String],
        mergeRule: String
    ) {
        self.branch = branch
        self.requiredTracks = requiredTracks
        self.requiredTests = requiredTests
        self.manualChecks = manualChecks
        self.mergeRule = mergeRule
    }

    public static func standard() -> TrackFReleaseChecklist {
        TrackFReleaseChecklist(
            requiredTracks: [
                "feat/ios-01-auth",
                "feat/ios-02-feed",
                "feat/ios-03-compose-media",
                "feat/ios-04-interactions",
            ],
            requiredTests: [
                "Auth ViewModel tests",
                "Feed pagination/detail tests",
                "Composer validation/publish tests",
                "Interaction optimistic state tests",
                "Track F regression runner tests",
            ],
            manualChecks: [
                "Login and logout on simulator",
                "Feed refresh and infinite scroll",
                "Publish post with media",
                "Like and comment optimistic rollback",
            ],
            mergeRule: "Merge to main only when all Track A-F test gates are green"
        )
    }
}

public struct TrackFPRSummary: Equatable, Sendable {
    public let title: String
    public let highlights: [String]
    public let regressionResult: String
    public let risks: [String]

    public init(
        title: String,
        highlights: [String],
        regressionResult: String,
        risks: [String]
    ) {
        self.title = title
        self.highlights = highlights
        self.regressionResult = regressionResult
        self.risks = risks
    }
}

public protocol TrackFAuthServicing: Sendable {
    func sendSMSCode(phone: String) async throws -> SendSMSResponse
    func verifySMSCode(phone: String, code: String) async throws -> VerifySMSResponse
}

extension AuthService: TrackFAuthServicing {}

private struct TrackFAuthServiceAdapter: TrackFAuthServicing {
    let base: any AuthServiceProtocol

    func sendSMSCode(phone: String) async throws -> SendSMSResponse {
        try await base.sendSMSCode(phone: phone)
    }

    func verifySMSCode(phone: String, code: String) async throws -> VerifySMSResponse {
        try await base.verifySMSCode(phone: phone, code: code)
    }
}

public final class TrackFRegressionRunner {
    private let authService: TrackFAuthServicing
    private let session: AppSession
    private let feedService: FeedServiceProtocol
    private let composerService: ComposerServiceProtocol
    private let interactionService: InteractionServiceProtocol

    public init(
        authService: TrackFAuthServicing,
        session: AppSession,
        feedService: FeedServiceProtocol,
        composerService: ComposerServiceProtocol,
        interactionService: InteractionServiceProtocol
    ) {
        self.authService = authService
        self.session = session
        self.feedService = feedService
        self.composerService = composerService
        self.interactionService = interactionService
    }

    @MainActor
    public func runStandardRegression(phone: String, code: String) async -> TrackFRegressionReport {
        let startedAt = Date()
        var steps: [TrackFStepResult] = []

        do {
            _ = try await authService.sendSMSCode(phone: phone)
            let verify = try await authService.verifySMSCode(phone: phone, code: code)
            session.login(with: verify.token)
            steps.append(.init(step: "login", status: .passed, detail: "Auth flow completed"))
        } catch {
            steps.append(.init(step: "login", status: .failed, detail: error.localizedDescription))
            let finishedAt = Date()
            return TrackFRegressionReport(startedAt: startedAt, finishedAt: finishedAt, steps: steps)
        }

        let loadedPost: FeedPost
        do {
            let feed = try await feedService.fetchFeed(offset: 0, limit: 20)
            guard let post = feed.items.first else {
                steps.append(.init(step: "feed", status: .failed, detail: "Feed has no posts to verify"))
                let finishedAt = Date()
                return TrackFRegressionReport(startedAt: startedAt, finishedAt: finishedAt, steps: steps)
            }
            loadedPost = post
            steps.append(.init(step: "feed", status: .passed, detail: "Loaded \(feed.items.count) posts"))
        } catch {
            steps.append(.init(step: "feed", status: .failed, detail: error.localizedDescription))
            let finishedAt = Date()
            return TrackFRegressionReport(startedAt: startedAt, finishedAt: finishedAt, steps: steps)
        }

        do {
            let media = ComposerMediaDraft(
                fileName: "trackf.jpg",
                data: Data(repeating: 1, count: 1024),
                mediaType: .image
            )
            _ = try await composerService.publish(
                draft: ComposerPostDraft(title: "Track F Regression", content: "Automated end-to-end check"),
                media: [media],
                progress: nil
            )
            steps.append(.init(step: "publish", status: .passed, detail: "Post publish succeeded"))
        } catch {
            steps.append(.init(step: "publish", status: .failed, detail: error.localizedDescription))
            let finishedAt = Date()
            return TrackFRegressionReport(startedAt: startedAt, finishedAt: finishedAt, steps: steps)
        }

        do {
            _ = try await interactionService.toggleLike(postID: loadedPost.id)
            _ = try await interactionService.createComment(postID: loadedPost.id, content: "Track F comment")
            steps.append(.init(step: "like_comment", status: .passed, detail: "Like and comment succeeded"))
        } catch {
            steps.append(.init(step: "like_comment", status: .failed, detail: error.localizedDescription))
            let finishedAt = Date()
            return TrackFRegressionReport(startedAt: startedAt, finishedAt: finishedAt, steps: steps)
        }

        let finishedAt = Date()
        return TrackFRegressionReport(startedAt: startedAt, finishedAt: finishedAt, steps: steps)
    }

    public func makePRSummary(from report: TrackFRegressionReport) -> TrackFPRSummary {
        TrackFPRSummary(
            title: "feat(ios): complete Track F integration and QA",
            highlights: [
                "Integrated Auth, Feed, Composer, and Interactions in one regression path",
                "Added automated regression runner for login → feed → publish → like/comment",
                "Prepared release checklist for feat/ios-05-integration-qa",
            ],
            regressionResult: report.allPassed ? "Passed" : "Failed",
            risks: report.steps.filter { $0.status == .failed }.map { "\($0.step): \($0.detail)" }
        )
    }
}

extension TrackFRegressionRunner {
    @MainActor
    public convenience init(
        authService: any AuthServiceProtocol,
        session: AppSession,
        feedService: FeedServiceProtocol,
        composerService: ComposerServiceProtocol,
        interactionService: InteractionServiceProtocol
    ) {
        self.init(
            authService: TrackFAuthServiceAdapter(base: authService),
            session: session,
            feedService: feedService,
            composerService: composerService,
            interactionService: interactionService
        )
    }
}
