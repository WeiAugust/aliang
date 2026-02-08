import Foundation
import XCTest
@testable import AliangIOS

@MainActor
final class TrackFRegressionRunnerTests: XCTestCase {
    func testRegressionPathPassesAllSteps() async {
        let auth = TrackFAuthServiceMock()
        let feed = TrackFFeedServiceMock(posts: [TrackFFixtures.samplePost])
        let composer = TrackFComposerServiceMock()
        let interaction = TrackFInteractionServiceMock()
        let session = AppSession(tokenStore: InMemoryTokenStore())

        let runner = TrackFRegressionRunner(
            authService: auth,
            session: session,
            feedService: feed,
            composerService: composer,
            interactionService: interaction
        )

        let report = await runner.runStandardRegression(phone: "13800138000", code: "123456")

        XCTAssertTrue(report.allPassed)
        XCTAssertEqual(report.steps.map(\.step), ["login", "feed", "publish", "like_comment"])
        XCTAssertEqual(report.steps.map(\.status), [.passed, .passed, .passed, .passed])
        XCTAssertTrue(session.isLoggedIn)
    }

    func testRegressionStopsWhenFeedFails() async {
        let auth = TrackFAuthServiceMock()
        let feed = TrackFFeedServiceMock(posts: [])
        let composer = TrackFComposerServiceMock()
        let interaction = TrackFInteractionServiceMock()
        let session = AppSession(tokenStore: InMemoryTokenStore())

        let runner = TrackFRegressionRunner(
            authService: auth,
            session: session,
            feedService: feed,
            composerService: composer,
            interactionService: interaction
        )

        let report = await runner.runStandardRegression(phone: "13800138000", code: "123456")

        XCTAssertFalse(report.allPassed)
        XCTAssertEqual(report.steps.count, 2)
        XCTAssertEqual(report.steps[0].status, .passed)
        XCTAssertEqual(report.steps[1].step, "feed")
        XCTAssertEqual(report.steps[1].status, .failed)
        XCTAssertTrue(report.steps[1].detail.contains("no posts"))
    }

    func testPRSummaryReflectsFailedSteps() {
        let report = TrackFRegressionReport(
            startedAt: Date(),
            finishedAt: Date(),
            steps: [
                TrackFStepResult(step: "login", status: .passed, detail: "ok"),
                TrackFStepResult(step: "publish", status: .failed, detail: "upload failed"),
            ]
        )

        let runner = TrackFRegressionRunner(
            authService: TrackFAuthServiceMock(),
            session: AppSession(tokenStore: InMemoryTokenStore()),
            feedService: TrackFFeedServiceMock(posts: [TrackFFixtures.samplePost]),
            composerService: TrackFComposerServiceMock(),
            interactionService: TrackFInteractionServiceMock()
        )

        let summary = runner.makePRSummary(from: report)

        XCTAssertEqual(summary.regressionResult, "Failed")
        XCTAssertEqual(summary.risks, ["publish: upload failed"])
        XCTAssertTrue(summary.title.contains("Track F"))
    }

    func testStandardChecklistIncludesTracksBToE() {
        let checklist = TrackFReleaseChecklist.standard()

        XCTAssertEqual(checklist.branch, "feat/ios-05-integration-qa")
        XCTAssertTrue(checklist.requiredTracks.contains("feat/ios-01-auth"))
        XCTAssertTrue(checklist.requiredTracks.contains("feat/ios-02-feed"))
        XCTAssertTrue(checklist.requiredTracks.contains("feat/ios-03-compose-media"))
        XCTAssertTrue(checklist.requiredTracks.contains("feat/ios-04-interactions"))
        XCTAssertTrue(checklist.mergeRule.contains("Track A-F"))
    }
}

private enum TrackFFixtures {
    static let samplePost = FeedPost(
        id: 101,
        userID: 1,
        title: "Sample",
        content: "Post",
        postType: "image",
        likeCount: 0,
        commentCount: 0,
        createdAt: Date(),
        author: FeedAuthor(id: 1, nickname: "u1", avatarURL: nil),
        media: []
    )
}

private actor TrackFAuthServiceMock: TrackFAuthServicing {
    func sendSMSCode(phone: String) async throws -> SendSMSResponse {
        SendSMSResponse(code: "123456", expiresAt: "5m")
    }

    func verifySMSCode(phone: String, code: String) async throws -> VerifySMSResponse {
        VerifySMSResponse(
            token: "token-trackf",
            user: AuthUser(id: 1, phone: phone, nickname: "tester", avatarURL: nil, createdAt: nil)
        )
    }
}

private actor TrackFFeedServiceMock: FeedServiceProtocol {
    private let posts: [FeedPost]

    init(posts: [FeedPost]) {
        self.posts = posts
    }

    func fetchFeed(offset: Int, limit: Int) async throws -> FeedPage {
        FeedPage(items: posts, hasMore: false)
    }

    func fetchPostDetail(postID: Int64) async throws -> FeedPost {
        if let item = posts.first(where: { $0.id == postID }) {
            return item
        }
        return TrackFFixtures.samplePost
    }
}

private actor TrackFComposerServiceMock: ComposerServiceProtocol {
    func publish(
        draft: ComposerPostDraft,
        media: [ComposerMediaDraft],
        progress: (@Sendable (ComposerProgressEvent) -> Void)?
    ) async throws -> ComposerPublishResult {
        progress?(.validating)
        progress?(.publishing)

        return ComposerPublishResult(
            post: PublishedPost(id: 333),
            uploadedMedia: media.map {
                UploadedMediaResource(url: "https://cdn.local/\($0.fileName)", thumbnailURL: nil, mediaType: $0.mediaType)
            }
        )
    }
}

private actor TrackFInteractionServiceMock: InteractionServiceProtocol {
    func toggleLike(postID: Int64) async throws -> ToggleLikeResponse {
        ToggleLikeResponse(isLiked: true, likeCount: 1)
    }

    func listComments(postID: Int64, offset: Int, limit: Int) async throws -> CommentPage {
        CommentPage(items: [], hasMore: false)
    }

    func createComment(postID: Int64, content: String) async throws -> InteractionComment {
        InteractionComment(
            id: 9,
            postID: postID,
            userID: 1,
            content: content,
            createdAt: Date(),
            isPending: false
        )
    }
}
