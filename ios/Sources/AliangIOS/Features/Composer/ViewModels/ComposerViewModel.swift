import Foundation

@MainActor
public final class ComposerViewModel: ObservableObject {
    @Published public var title = ""
    @Published public var content = ""
    @Published public private(set) var media: [ComposerMediaDraft] = []
    @Published public private(set) var isPublishing = false
    @Published public private(set) var progressEvents: [ComposerProgressEvent] = []
    @Published public private(set) var uploadProgressByID: [UUID: Double] = [:]
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var publishSuccessPostID: Int64?

    public var publishedPostID: Int64? {
        publishSuccessPostID
    }

    private let composerService: ComposerServiceProtocol

    public init(composerService: ComposerServiceProtocol) {
        self.composerService = composerService
    }

    public func updateTitle(_ value: String) {
        title = value
    }

    public func updateContent(_ value: String) {
        content = value
    }

    public func replaceMedia(_ value: [ComposerMediaDraft]) {
        media = value
    }

    public func setMedia(_ value: [ComposerMediaDraft]) {
        replaceMedia(value)
    }

    public func appendMedia(_ item: ComposerMediaDraft) {
        media.append(item)
    }

    public func removeMedia(id: UUID) {
        media.removeAll { $0.id == id }
        uploadProgressByID[id] = nil
    }

    @discardableResult
    public func publish() async -> Bool {
        guard !isPublishing else {
            return false
        }

        errorMessage = nil
        publishSuccessPostID = nil
        progressEvents = []
        uploadProgressByID = [:]
        isPublishing = true
        defer { isPublishing = false }

        let draft = ComposerPostDraft(title: title, content: content)

        do {
            let result = try await composerService.publish(
                draft: draft,
                media: media,
                progress: { [weak self] event in
                    Task { @MainActor in
                        self?.handleProgressEvent(event)
                    }
                }
            )

            publishSuccessPostID = result.post.id
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    private func handleProgressEvent(_ event: ComposerProgressEvent) {
        progressEvents.append(event)

        switch event {
        case .uploading(let id, let progress):
            uploadProgressByID[id] = min(max(progress, 0), 1)
        case .uploaded(let id, _):
            uploadProgressByID[id] = 1
        case .failed(let id, _):
            if uploadProgressByID[id] == nil {
                uploadProgressByID[id] = 0
            }
        default:
            break
        }
    }
}
