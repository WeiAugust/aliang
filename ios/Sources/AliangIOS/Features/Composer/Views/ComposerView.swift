import SwiftUI

#if canImport(UIKit) && canImport(PhotosUI)
import UIKit
import PhotosUI
#endif

public struct ComposerView: View {
    @StateObject private var viewModel: ComposerViewModel
    @State private var localMedia: [ComposerMediaDraft] = []
    @State private var showMediaPicker = false

#if canImport(UIKit) && canImport(PhotosUI)
    @State private var selectedItems: [PHPickerResult] = []
#endif

    public init(viewModel: @autoclosure @escaping () -> ComposerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Form {
            Section("Post") {
                TextField("Title", text: Binding(
                    get: { viewModel.title },
                    set: { viewModel.updateTitle($0) }
                ))
                .accessibilityIdentifier("composer.title")

                TextField("Content", text: Binding(
                    get: { viewModel.content },
                    set: { viewModel.updateContent($0) }
                ), axis: .vertical)
                .lineLimit(4, reservesSpace: true)
                .accessibilityIdentifier("composer.content")
            }

            Section("Media") {
                mediaSelectionSection
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("composer.error")
                }
            }

            Section {
                Button(viewModel.isPublishing ? "Publishing..." : "Publish") {
                    Task {
                        _ = await viewModel.publish()
                        if viewModel.publishSuccessPostID != nil {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostPublished"),
                                object: nil
                            )
                        }
                    }
                }
                .disabled(viewModel.isPublishing)
                .accessibilityIdentifier("composer.publish")

                if let postID = viewModel.publishSuccessPostID {
                    Text("Published post #\(postID)")
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("composer.success")
                }
            }
        }
        .navigationTitle("Compose")
#if canImport(UIKit) && canImport(PhotosUI)
        .sheet(isPresented: $showMediaPicker) {
            MediaPickerViewRepresentable(
                selectionLimit: 9,
                filter: PHPickerFilter.any(of: [.images, .videos])
            ) { selectedMedia in
                handleMediaSelection(selectedMedia)
            }
            .presentationDetents([.medium, .large])
        }
#endif
    }

    @ViewBuilder
    private var mediaSelectionSection: some View {
        // Add media button
#if canImport(UIKit) && canImport(PhotosUI)
        Button {
            showMediaPicker = true
        } label: {
            Label("Add Photos/Videos", systemImage: "photo.on.rectangle.angled")
        }
        .accessibilityIdentifier("composer.addMedia")
#else
        Button {
            showMediaPicker = false
        } label: {
            Label("Add Photos/Videos", systemImage: "photo.on.rectangle.angled")
        }
        .disabled(true)
        .accessibilityIdentifier("composer.addMedia")

        Text("Media picker is available on iOS with PhotosUI support.")
            .font(.caption)
            .foregroundStyle(.secondary)
#endif

        // Media preview grid
        if !localMedia.isEmpty {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(localMedia) { media in
                    MediaThumbnailView(media: media) {
                        removeMedia(id: media.id)
                    }
                }
            }
            .padding(.vertical, 8)
        }

        // Empty state
        if localMedia.isEmpty {
            Text("No media selected. Add photos or videos to your post.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func handleMediaSelection(_ selectedMedia: [ComposerMediaDraft]) {
        localMedia.append(contentsOf: selectedMedia)
        viewModel.replaceMedia(localMedia)
    }

    private func removeMedia(id: UUID) {
        localMedia.removeAll { $0.id == id }
        viewModel.removeMedia(id: id)
    }
}

/// Thumbnail view for media items
struct MediaThumbnailView: View {
    let media: ComposerMediaDraft
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailContent
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white, .red)
            }
            .offset(x: 6, y: -6)
        }
    }

    @ViewBuilder
    @MainActor
    private var thumbnailContent: some View {
        switch media.mediaType {
        case .image:
#if canImport(UIKit)
            if let uiImage = UIImage(data: media.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderView
            }
#else
            placeholderView
#endif
        case .video:
            ZStack {
                placeholderView
                Image(systemName: "video.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            Image(systemName: media.mediaType == .image ? "photo" : "video")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
