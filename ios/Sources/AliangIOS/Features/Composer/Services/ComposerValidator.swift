import Foundation

public struct ComposerValidator: Sendable {
    public static let maxImages = 9
    public static let maxVideos = 1
    public static let maxImageBytes = 10 * 1024 * 1024
    public static let maxVideoBytes = 100 * 1024 * 1024

    public init() {}

    public func validate(draft: ComposerPostDraft, media: [ComposerMediaDraft]) -> [ComposerValidationError] {
        var errors: [ComposerValidationError] = []

        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyTitle)
        }

        if draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyContent)
        }

        let imageCount = media.filter { $0.mediaType == .image }.count
        let videoCount = media.filter { $0.mediaType == .video }.count

        if imageCount > 0 && videoCount > 0 {
            errors.append(.mixedMediaTypes)
        }

        if imageCount > Self.maxImages {
            errors.append(.tooManyImages(maxAllowed: Self.maxImages))
        }

        if videoCount > Self.maxVideos {
            errors.append(.tooManyVideos(maxAllowed: Self.maxVideos))
        }

        for item in media {
            switch item.mediaType {
            case .image:
                if item.byteSize > Self.maxImageBytes {
                    errors.append(.imageTooLarge(fileName: item.fileName, maxMB: 10))
                }
            case .video:
                if item.byteSize > Self.maxVideoBytes {
                    errors.append(.videoTooLarge(fileName: item.fileName, maxMB: 100))
                }
            }
        }

        return errors
    }
}
