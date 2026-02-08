import Foundation
import XCTest
@testable import AliangIOS

@MainActor
private final class ViewModelComposerAPIClient: ComposerAPIClient {
    private let imageUploadFailuresBeforeSuccess: Int
    private let createPostID: Int64

    private(set) var imageUploadAttempts = 0

    init(imageUploadFailuresBeforeSuccess: Int, createPostID: Int64) {
        self.imageUploadFailuresBeforeSuccess = imageUploadFailuresBeforeSuccess
        self.createPostID = createPostID
    }

    func uploadImage(
        fileName: String,
        data _: Data,
        onProgress: @escaping (Double) -> Void
    ) async throws -> UploadedMediaResource {
        imageUploadAttempts += 1
        onProgress(0.5)
        if imageUploadAttempts <= imageUploadFailuresBeforeSuccess {
            throw NSError(domain: "mock", code: -1)
        }
        onProgress(1)
        return UploadedMediaResource(url: "https://cdn.example.com/\(fileName)", thumbnailURL: nil, mediaType: .image)
    }

    func uploadVideo(
        fileName: String,
        data _: Data,
        onProgress _: @escaping (Double) -> Void
    ) async throws -> UploadedMediaResource {
        UploadedMediaResource(url: "https://cdn.example.com/\(fileName)", thumbnailURL: nil, mediaType: .video)
    }

    func createPost(payload _: CreatePostPayload) async throws -> PublishedPost {
        PublishedPost(id: createPostID)
    }
}

@MainActor
final class ComposerViewModelTests: XCTestCase {
    func testPublishSuccessUpdatesState() async {
        let api = ViewModelComposerAPIClient(
            imageUploadFailuresBeforeSuccess: 0,
            createPostID: 77
        )
        let service = ComposerService(apiClient: api, retryPolicy: RetryPolicy(maxAttempts: 1, baseDelaySeconds: 0))
        let viewModel = ComposerViewModel(composerService: service)

        viewModel.updateTitle("Title")
        viewModel.updateContent("Body")
        let media = ComposerMediaDraft(fileName: "ok.jpg", data: Data(repeating: 1, count: 100), mediaType: .image)
        viewModel.replaceMedia([media])

        let success = await viewModel.publish()

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.publishSuccessPostID, 77)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.uploadProgressByID[media.id], 1)
    }

    func testPublishValidationFailureReturnsFalse() async {
        let api = ViewModelComposerAPIClient(
            imageUploadFailuresBeforeSuccess: 0,
            createPostID: 77
        )
        let service = ComposerService(apiClient: api)
        let viewModel = ComposerViewModel(composerService: service)

        viewModel.updateTitle("")
        viewModel.updateContent("")

        let success = await viewModel.publish()

        XCTAssertFalse(success)
        XCTAssertNil(viewModel.publishSuccessPostID)
        XCTAssertFalse(viewModel.errorMessage?.isEmpty ?? true)
    }
}
