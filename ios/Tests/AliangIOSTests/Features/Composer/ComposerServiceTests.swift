import Foundation
import XCTest
@testable import AliangIOS

private final class CounterBox: @unchecked Sendable {
    private let lock = NSLock()
    private(set) var value = 0

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
    }
}

private final class EventsBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [ComposerProgressEvent] = []

    func append(_ event: ComposerProgressEvent) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(event)
    }

    var values: [ComposerProgressEvent] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

final class ComposerServiceTests: XCTestCase {
    func testRetriesUploadThenPublishesPost() async throws {
        let image = ComposerMediaDraft(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            fileName: "cover.jpg",
            data: Data(repeating: 1, count: 1024),
            mediaType: .image
        )

        let api = MockComposerAPIClient(
            imageUploadFailuresBeforeSuccess: 1,
            createPostID: 9527
        )

        let sleepCalls = CounterBox()
        let service = ComposerService(
            apiClient: api,
            retryPolicy: RetryPolicy(maxAttempts: 3, baseDelaySeconds: 0.01),
            sleep: { _ in sleepCalls.increment() }
        )

        let events = EventsBox()
        let result = try await service.publish(
            draft: ComposerPostDraft(title: "A", content: "B"),
            media: [image],
            progress: { events.append($0) }
        )

        let receivedEvents = events.values

        XCTAssertEqual(result.post.id, 9527)
        XCTAssertEqual(result.uploadedMedia.count, 1)
        XCTAssertEqual(api.imageUploadAttempts, 2)
        XCTAssertEqual(sleepCalls.value, 1)
        XCTAssertTrue(receivedEvents.contains(where: {
            if case .retrying(id: image.id, attempt: 2) = $0 { return true }
            return false
        }))
        XCTAssertEqual(api.lastCreatePayload?.postType, "image")
        XCTAssertEqual(api.lastCreatePayload?.mediaURLs, ["https://cdn.example.com/cover.jpg"])
    }

    func testFailsAfterMaxRetries() async {
        let api = MockComposerAPIClient(
            imageUploadFailuresBeforeSuccess: 5,
            createPostID: 1
        )
        let service = ComposerService(
            apiClient: api,
            retryPolicy: RetryPolicy(maxAttempts: 2, baseDelaySeconds: 0),
            sleep: { _ in }
        )

        let image = ComposerMediaDraft(fileName: "fail.jpg", data: Data(repeating: 1, count: 16), mediaType: .image)

        do {
            _ = try await service.publish(
                draft: ComposerPostDraft(title: "A", content: "B"),
                media: [image],
                progress: nil
            )
            XCTFail("Expected upload failure but publish succeeded")
        } catch let error as ComposerServiceError {
            switch error {
            case .uploadFailed(let fileName, let attempts, _):
                XCTAssertEqual(fileName, "fail.jpg")
                XCTAssertEqual(attempts, 2)
            default:
                XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected non-composer error: \(error)")
        }
    }

    func testTextOnlyPostPublishesWithoutUploadUsingDefaultImageType() async throws {
        let api = MockComposerAPIClient(
            imageUploadFailuresBeforeSuccess: 0,
            createPostID: 2026
        )
        let service = ComposerService(apiClient: api)

        let result = try await service.publish(
            draft: ComposerPostDraft(title: "Text title", content: "Text content"),
            media: [],
            progress: nil
        )

        XCTAssertEqual(result.post.id, 2026)
        XCTAssertTrue(result.uploadedMedia.isEmpty)
        XCTAssertEqual(api.imageUploadAttempts, 0)
        XCTAssertEqual(api.lastCreatePayload?.postType, "image")
        XCTAssertEqual(api.lastCreatePayload?.mediaURLs, [])
    }
}

private final class MockComposerAPIClient: ComposerAPIClient, @unchecked Sendable {
    private let imageUploadFailuresBeforeSuccess: Int
    private let createPostID: Int64

    private(set) var imageUploadAttempts = 0
    private(set) var lastCreatePayload: CreatePostPayload?

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
        onProgress(0.4)
        if imageUploadAttempts <= imageUploadFailuresBeforeSuccess {
            throw MockError.simulatedUploadFailure
        }
        onProgress(1)
        return UploadedMediaResource(
            url: "https://cdn.example.com/\(fileName)",
            thumbnailURL: nil,
            mediaType: .image
        )
    }

    func uploadVideo(
        fileName: String,
        data _: Data,
        onProgress _: @escaping (Double) -> Void
    ) async throws -> UploadedMediaResource {
        UploadedMediaResource(
            url: "https://cdn.example.com/\(fileName)",
            thumbnailURL: nil,
            mediaType: .video
        )
    }

    func createPost(payload: CreatePostPayload) async throws -> PublishedPost {
        lastCreatePayload = payload
        return PublishedPost(id: createPostID)
    }

    enum MockError: Error {
        case simulatedUploadFailure
    }
}
