import Foundation
import XCTest
@testable import AliangIOS

final class ComposerMediaTests: XCTestCase {
    func testMediaDraftCreation() {
        let data = Data(repeating: 0xFF, count: 1024)
        let media = ComposerMediaDraft(
            fileName: "test.jpg",
            data: data,
            mediaType: .image
        )

        XCTAssertEqual(media.fileName, "test.jpg")
        XCTAssertEqual(media.data.count, 1024)
        XCTAssertEqual(media.mediaType, .image)
        XCTAssertNotNil(media.id)
    }

    func testMediaDraftVideoType() {
        let data = Data(repeating: 0x00, count: 2048)
        let media = ComposerMediaDraft(
            fileName: "video.mp4",
            data: data,
            mediaType: .video
        )

        XCTAssertEqual(media.mediaType, .video)
        XCTAssertEqual(media.fileName, "video.mp4")
    }

    func testMediaDraftEquatable() {
        let data = Data([1, 2, 3])
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let media1 = ComposerMediaDraft(id: id, fileName: "test.jpg", data: data, mediaType: .image)
        let media2 = ComposerMediaDraft(id: id, fileName: "test.jpg", data: data, mediaType: .image)

        XCTAssertEqual(media1, media2)
    }

    func testMediaDraftDifferentDataNotEqual() {
        let media1 = ComposerMediaDraft(fileName: "test.jpg", data: Data([1, 2]), mediaType: .image)
        let media2 = ComposerMediaDraft(fileName: "test.jpg", data: Data([3, 4]), mediaType: .image)

        XCTAssertNotEqual(media1, media2)
    }

    func testPostDraftCreation() {
        let draft = ComposerPostDraft(title: "Test Title", content: "Test Content")

        XCTAssertEqual(draft.title, "Test Title")
        XCTAssertEqual(draft.content, "Test Content")
    }

    func testUploadedMediaResourceCreation() {
        let resource = UploadedMediaResource(
            url: "https://cdn.example.com/image.jpg",
            thumbnailURL: "https://cdn.example.com/thumb.jpg",
            mediaType: .image
        )

        XCTAssertEqual(resource.url, "https://cdn.example.com/image.jpg")
        XCTAssertEqual(resource.thumbnailURL, "https://cdn.example.com/thumb.jpg")
        XCTAssertEqual(resource.mediaType, .image)
    }

    func testMediaPickerErrorDescriptions() {
        XCTAssertEqual(MediaPickerError.unavailable.errorDescription, "Media picker is unavailable")
        XCTAssertEqual(MediaPickerError.noSelection.errorDescription, "No media selected")
    }
}

@MainActor
final class ComposerViewMediaHandlingTests: XCTestCase {
    func testMediaAppendIncreasesCount() {
        let mockService = MockComposerService()
        let viewModel = ComposerViewModel(composerService: mockService)

        let media1 = ComposerMediaDraft(fileName: "test1.jpg", data: Data([1]), mediaType: .image)
        let media2 = ComposerMediaDraft(fileName: "test2.mp4", data: Data([2]), mediaType: .video)

        viewModel.appendMedia(media1)
        XCTAssertEqual(viewModel.media.count, 1)

        viewModel.appendMedia(media2)
        XCTAssertEqual(viewModel.media.count, 2)
    }

    func testRemoveMediaDecreasesCount() {
        let mockService = MockComposerService()
        let viewModel = ComposerViewModel(composerService: mockService)

        let media1 = ComposerMediaDraft(fileName: "test1.jpg", data: Data([1]), mediaType: .image)
        let media2 = ComposerMediaDraft(fileName: "test2.jpg", data: Data([2]), mediaType: .image)

        viewModel.replaceMedia([media1, media2])
        XCTAssertEqual(viewModel.media.count, 2)

        viewModel.removeMedia(id: media1.id)
        XCTAssertEqual(viewModel.media.count, 1)
        XCTAssertFalse(viewModel.media.contains(media1))
    }

    func testReplaceMediaOverwritesExisting() {
        let mockService = MockComposerService()
        let viewModel = ComposerViewModel(composerService: mockService)

        let initialMedia = ComposerMediaDraft(fileName: "initial.jpg", data: Data([1]), mediaType: .image)
        let newMedia = ComposerMediaDraft(fileName: "new.jpg", data: Data([2]), mediaType: .image)

        viewModel.replaceMedia([initialMedia])
        XCTAssertEqual(viewModel.media.count, 1)

        viewModel.replaceMedia([newMedia])
        XCTAssertEqual(viewModel.media.count, 1)
        XCTAssertEqual(viewModel.media.first?.fileName, "new.jpg")
    }

    func testUploadProgressTracking() async {
        let media = ComposerMediaDraft(fileName: "test.jpg", data: Data([1]), mediaType: .image)
        let mockService = MockComposerService(
            progressEventsToEmit: [
                .uploading(id: media.id, progress: 0.75),
                .uploaded(id: media.id, url: "https://example.com/test.jpg")
            ],
            postID: 42
        )
        let viewModel = ComposerViewModel(composerService: mockService)

        viewModel.updateTitle("Title")
        viewModel.updateContent("Content")
        viewModel.replaceMedia([media])

        let success = await viewModel.publish()

        let deadline = Date().addingTimeInterval(0.5)
        while Date() < deadline {
            let hasCompletedProgress = viewModel.uploadProgressByID[media.id] == 1
            let hasUploadEvent = viewModel.progressEvents.contains {
                if case .uploading(id: media.id, progress: 0.75) = $0 { return true }
                return false
            }

            if hasCompletedProgress && hasUploadEvent {
                break
            }

            await Task.yield()
        }

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.uploadProgressByID[media.id], 1)
        XCTAssertTrue(viewModel.progressEvents.contains {
            if case .uploading(id: media.id, progress: 0.75) = $0 { return true }
            return false
        })
    }
}

// MARK: - Mock Composer Service

@MainActor
private final class MockComposerService: ComposerServiceProtocol {
    private let progressEventsToEmit: [ComposerProgressEvent]
    private let postID: Int64

    init(
        progressEventsToEmit: [ComposerProgressEvent] = [],
        postID: Int64 = 1
    ) {
        self.progressEventsToEmit = progressEventsToEmit
        self.postID = postID
    }

    func publish(
        draft _: ComposerPostDraft,
        media: [ComposerMediaDraft],
        progress: (@Sendable (ComposerProgressEvent) -> Void)?
    ) async throws -> ComposerPublishResult {
        progressEventsToEmit.forEach { progress?($0) }

        let uploaded = media.map {
            UploadedMediaResource(
                url: "https://example.com/\($0.fileName)",
                thumbnailURL: nil,
                mediaType: $0.mediaType
            )
        }

        return ComposerPublishResult(post: PublishedPost(id: postID), uploadedMedia: uploaded)
    }
}
