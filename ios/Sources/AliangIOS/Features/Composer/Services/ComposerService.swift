import Foundation

public protocol ComposerServiceProtocol {
    func publish(
        draft: ComposerPostDraft,
        media: [ComposerMediaDraft],
        progress: (@Sendable (ComposerProgressEvent) -> Void)?
    ) async throws -> ComposerPublishResult
}

public final class ComposerService: ComposerServiceProtocol {
    private let apiClient: ComposerAPIClient
    private let validator: ComposerValidator
    private let retryPolicy: RetryPolicy
    private let sleep: @Sendable (UInt64) async -> Void

    public init(
        apiClient: ComposerAPIClient,
        validator: ComposerValidator = ComposerValidator(),
        retryPolicy: RetryPolicy = RetryPolicy(),
        sleep: @escaping @Sendable (UInt64) async -> Void = { delay in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    ) {
        self.apiClient = apiClient
        self.validator = validator
        self.retryPolicy = retryPolicy
        self.sleep = sleep
    }

    public convenience init(
        httpClient: HTTPClientProtocol,
        tokenProvider: @escaping @Sendable () -> String?
    ) {
        let bridge = ComposerTokenProviderBridge(tokenProvider: tokenProvider)

        if let concrete = httpClient as? HTTPClient {
            self.init(
                apiClient: URLSessionComposerAPIClient(
                    baseURL: concrete.configuredBaseURL,
                    tokenProvider: bridge
                )
            )
        } else {
            self.init(
                apiClient: URLSessionComposerAPIClient(
                    baseURL: URL(string: "http://localhost:8080")!,
                    tokenProvider: bridge
                )
            )
        }
    }

    public func publish(
        draft: ComposerPostDraft,
        media: [ComposerMediaDraft],
        progress: (@Sendable (ComposerProgressEvent) -> Void)? = nil
    ) async throws -> ComposerPublishResult {
        progress?(.validating)

        let validationErrors = validator.validate(draft: draft, media: media)
        guard validationErrors.isEmpty else {
            throw ComposerServiceError.validation(validationErrors)
        }

        var uploadedResources: [UploadedMediaResource] = []
        uploadedResources.reserveCapacity(media.count)

        for item in media {
            progress?(.uploadQueued(id: item.id))
            let uploaded = try await uploadWithRetry(item: item, progress: progress)
            uploadedResources.append(uploaded)
            progress?(.uploaded(id: item.id, url: uploaded.url))
        }

        progress?(.publishing)
        do {
            let payload = CreatePostPayload(
                title: draft.title,
                content: draft.content,
                postType: media.first?.mediaType.rawValue ?? "image",
                mediaURLs: uploadedResources.map(\.url)
            )

            let post = try await apiClient.createPost(payload: payload)
            progress?(.completed(postID: post.id))
            return ComposerPublishResult(post: post, uploadedMedia: uploadedResources)
        } catch {
            throw ComposerServiceError.publishFailed(message: error.localizedDescription)
        }
    }

    private func uploadWithRetry(
        item: ComposerMediaDraft,
        progress: (@Sendable (ComposerProgressEvent) -> Void)?
    ) async throws -> UploadedMediaResource {
        var currentAttempt = 0
        var lastError: Error?

        while currentAttempt < retryPolicy.maxAttempts {
            currentAttempt += 1

            do {
                let uploader: (String, Data, @escaping @Sendable (Double) -> Void) async throws -> UploadedMediaResource
                switch item.mediaType {
                case .image:
                    uploader = apiClient.uploadImage
                case .video:
                    uploader = apiClient.uploadVideo
                }

                return try await uploader(item.fileName, item.data) { value in
                    progress?(.uploading(id: item.id, progress: value))
                }
            } catch {
                lastError = error
                if currentAttempt < retryPolicy.maxAttempts {
                    progress?(.retrying(id: item.id, attempt: currentAttempt + 1))
                    let delay = retryPolicy.delayNanoseconds(forAttempt: currentAttempt)
                    await sleep(delay)
                }
            }
        }

        let message = lastError?.localizedDescription ?? "Unknown upload failure"
        progress?(.failed(id: item.id, message: message))
        throw ComposerServiceError.uploadFailed(
            fileName: item.fileName,
            attempts: retryPolicy.maxAttempts,
            message: message
        )
    }
}

private struct ComposerTokenProviderBridge: ComposerTokenProvider {
    let tokenProvider: @Sendable () -> String?

    func authToken() -> String? {
        tokenProvider()
    }
}
