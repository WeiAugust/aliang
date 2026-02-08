import Foundation
import SwiftUI

#if canImport(UIKit) && canImport(PhotosUI)
import UIKit
import PhotosUI

/// SwiftUI wrapper for PHPickerViewController
public struct MediaPickerViewRepresentable: UIViewControllerRepresentable {
    public let selectionLimit: Int
    public let filter: PHPickerFilter
    public let onCompletion: ([ComposerMediaDraft]) -> Void

    public init(
        selectionLimit: Int = 9,
        filter: PHPickerFilter = .any(of: [.images, .videos]),
        onCompletion: @escaping ([ComposerMediaDraft]) -> Void
    ) {
        self.selectionLimit = selectionLimit
        self.filter = filter
        self.onCompletion = onCompletion
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = selectionLimit
        configuration.filter = filter

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    public final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onCompletion: ([ComposerMediaDraft]) -> Void

        public init(onCompletion: @escaping ([ComposerMediaDraft]) -> Void) {
            self.onCompletion = onCompletion
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                onCompletion([])
                return
            }

            Task {
                var drafts: [ComposerMediaDraft] = []
                drafts.reserveCapacity(results.count)

                for result in results {
                    if let imageData = await loadImageData(from: result) {
                        let fileName = result.itemProvider.suggestedName.map { "\($0).jpg" } ?? "image_\(UUID().uuidString).jpg"
                        drafts.append(ComposerMediaDraft(fileName: fileName, data: imageData, mediaType: .image))
                        continue
                    }

                    if let videoData = await loadVideoData(from: result) {
                        let fileName = result.itemProvider.suggestedName.map { "\($0).mp4" } ?? "video_\(UUID().uuidString).mp4"
                        drafts.append(ComposerMediaDraft(fileName: fileName, data: videoData, mediaType: .video))
                        continue
                    }
                }

                onCompletion(drafts)
            }
        }

        private func loadImageData(from result: PHPickerResult) async -> Data? {
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                return nil
            }

            return await withCheckedContinuation { continuation in
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if error != nil {
                        continuation.resume(returning: nil)
                        return
                    }

                    guard let image = object as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.8) else {
                        continuation.resume(returning: nil)
                        return
                    }

                    continuation.resume(returning: data)
                }
            }
        }

        private func loadVideoData(from result: PHPickerResult) async -> Data? {
            guard result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") else {
                return nil
            }

            return await withCheckedContinuation { continuation in
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, error in
                    if error != nil {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: data)
                    }
                }
            }
        }
    }
}
#endif
