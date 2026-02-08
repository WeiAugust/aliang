import Foundation

public protocol MediaPickerProviding {
    func pickMedia() async throws -> [ComposerMediaDraft]
}

public enum MediaPickerError: Error, Equatable, LocalizedError {
    case unavailable
    case noSelection

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Media picker is unavailable"
        case .noSelection:
            return "No media selected"
        }
    }
}

#if canImport(UIKit) && canImport(PhotosUI)
import UIKit
import PhotosUI

@MainActor
public final class PhotosUIMediaPickerProvider: NSObject, MediaPickerProviding {
    private weak var presentingViewController: UIViewController?

    public init(presentingViewController: UIViewController?) {
        self.presentingViewController = presentingViewController
    }

    public func pickMedia() async throws -> [ComposerMediaDraft] {
        guard let presentingViewController else {
            throw MediaPickerError.unavailable
        }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 9
        configuration.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: configuration)
        let delegate = PickerDelegate()
        picker.delegate = delegate

        presentingViewController.present(picker, animated: true)
        let results = await delegate.awaitResults()

        guard !results.isEmpty else {
            throw MediaPickerError.noSelection
        }

        var drafts: [ComposerMediaDraft] = []
        drafts.reserveCapacity(results.count)

        for result in results {
            if let imageData = try await result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") {
                let fileName = result.itemProvider.suggestedName.map { "\($0).jpg" } ?? "image_\(UUID().uuidString).jpg"
                drafts.append(ComposerMediaDraft(fileName: fileName, data: imageData, mediaType: .image))
                continue
            }

            if let videoData = try await result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") {
                let fileName = result.itemProvider.suggestedName.map { "\($0).mp4" } ?? "video_\(UUID().uuidString).mp4"
                drafts.append(ComposerMediaDraft(fileName: fileName, data: videoData, mediaType: .video))
                continue
            }
        }

        guard !drafts.isEmpty else {
            throw MediaPickerError.noSelection
        }

        return drafts
    }
}

@MainActor
private final class PickerDelegate: NSObject, PHPickerViewControllerDelegate {
    private var continuation: CheckedContinuation<[PHPickerResult], Never>?

    func awaitResults() async -> [PHPickerResult] {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        continuation?.resume(returning: results)
        continuation = nil
    }
}

private extension NSItemProvider {
    func loadDataRepresentation(forTypeIdentifier typeIdentifier: String) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            guard hasItemConformingToTypeIdentifier(typeIdentifier) else {
                continuation.resume(returning: nil)
                return
            }

            loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }
}
#endif
