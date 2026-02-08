import Foundation

public enum ComposerMediaType: String, Codable, Sendable {
    case image
    case video

    public static func infer(from fileExtension: String) throws -> ComposerMediaType {
        let normalized = fileExtension.lowercased()
        if ["jpg", "jpeg", "png", "gif", "webp"].contains(normalized) {
            return .image
        }
        if ["mp4", "mov", "avi", "webm"].contains(normalized) {
            return .video
        }
        throw ComposerMediaInferenceError.unsupportedFileType(fileExtension: normalized)
    }
}

public enum ComposerMediaInferenceError: Error, LocalizedError, Equatable {
    case unsupportedFileType(fileExtension: String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let fileExtension):
            return "Unsupported file extension: \(fileExtension)"
        }
    }
}

public struct ComposerPostDraft: Equatable, Sendable {
    public var title: String
    public var content: String

    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }
}

public struct ComposerMediaDraft: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileName: String
    public let data: Data
    public let byteSize: Int
    public let mediaType: ComposerMediaType

    public init(id: UUID = UUID(), fileName: String, data: Data, mediaType: ComposerMediaType) {
        self.id = id
        self.fileName = fileName
        self.data = data
        self.byteSize = data.count
        self.mediaType = mediaType
    }

    public static func fromLocalFile(url: URL, preferredType: ComposerMediaType? = nil) throws -> ComposerMediaDraft {
        let data = try Data(contentsOf: url)
        let inferredType = try preferredType ?? ComposerMediaType.infer(from: url.pathExtension)
        return ComposerMediaDraft(fileName: url.lastPathComponent, data: data, mediaType: inferredType)
    }
}

public struct UploadedMediaResource: Equatable, Sendable {
    public let url: String
    public let thumbnailURL: String?
    public let mediaType: ComposerMediaType

    public init(url: String, thumbnailURL: String?, mediaType: ComposerMediaType) {
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.mediaType = mediaType
    }
}

public struct PublishedPost: Equatable, Sendable {
    public let id: Int64

    public init(id: Int64) {
        self.id = id
    }
}

public struct ComposerPublishResult: Equatable, Sendable {
    public let post: PublishedPost
    public let uploadedMedia: [UploadedMediaResource]

    public init(post: PublishedPost, uploadedMedia: [UploadedMediaResource]) {
        self.post = post
        self.uploadedMedia = uploadedMedia
    }
}

public struct CreatePostPayload: Encodable, Equatable, Sendable {
    public let title: String
    public let content: String
    public let postType: String
    public let mediaURLs: [String]

    public init(title: String, content: String, postType: String, mediaURLs: [String]) {
        self.title = title
        self.content = content
        self.postType = postType
        self.mediaURLs = mediaURLs
    }

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case postType = "post_type"
        case mediaURLs = "media_urls"
    }
}

public enum ComposerProgressEvent: Equatable, Sendable {
    case validating
    case uploadQueued(id: UUID)
    case uploading(id: UUID, progress: Double)
    case retrying(id: UUID, attempt: Int)
    case uploaded(id: UUID, url: String)
    case failed(id: UUID, message: String)
    case publishing
    case completed(postID: Int64)
}

public struct RetryPolicy: Equatable, Sendable {
    public let maxAttempts: Int
    public let baseDelaySeconds: Double

    public init(maxAttempts: Int = 3, baseDelaySeconds: Double = 0.5) {
        self.maxAttempts = max(maxAttempts, 1)
        self.baseDelaySeconds = max(baseDelaySeconds, 0)
    }

    func delayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        let exponent = Double(max(0, attempt - 1))
        let seconds = baseDelaySeconds * pow(2, exponent)
        return UInt64(seconds * 1_000_000_000)
    }
}

public enum ComposerValidationError: Error, Equatable, LocalizedError, Sendable {
    case emptyTitle
    case emptyContent
    case mixedMediaTypes
    case tooManyImages(maxAllowed: Int)
    case tooManyVideos(maxAllowed: Int)
    case imageTooLarge(fileName: String, maxMB: Int)
    case videoTooLarge(fileName: String, maxMB: Int)
    case unsupportedFileType(fileName: String)

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Title cannot be empty"
        case .emptyContent:
            return "Content cannot be empty"
        case .mixedMediaTypes:
            return "Images and video cannot be mixed in the same post"
        case .tooManyImages(let maxAllowed):
            return "At most \(maxAllowed) images are allowed"
        case .tooManyVideos(let maxAllowed):
            return "At most \(maxAllowed) video is allowed"
        case .imageTooLarge(let fileName, let maxMB):
            return "\(fileName) exceeds \(maxMB)MB image size limit"
        case .videoTooLarge(let fileName, let maxMB):
            return "\(fileName) exceeds \(maxMB)MB video size limit"
        case .unsupportedFileType(let fileName):
            return "\(fileName) has unsupported file type"
        }
    }
}

public enum ComposerServiceError: Error, Equatable, LocalizedError, Sendable {
    case validation([ComposerValidationError])
    case uploadFailed(fileName: String, attempts: Int, message: String)
    case publishFailed(message: String)

    public var errorDescription: String? {
        switch self {
        case .validation(let errors):
            return errors.compactMap(\.errorDescription).joined(separator: " | ")
        case .uploadFailed(let fileName, let attempts, let message):
            return "Upload failed for \(fileName) after \(attempts) attempts: \(message)"
        case .publishFailed(let message):
            return "Publish post failed: \(message)"
        }
    }
}
