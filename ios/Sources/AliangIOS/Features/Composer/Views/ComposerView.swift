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
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {
                    // Title & Content
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("WHAT'S NEW")
                            .appSectionHeader()

                        VStack(spacing: 0) {
                            TextField("Title", text: Binding(
                                get: { viewModel.title },
                                set: { viewModel.updateTitle($0) }
                            ))
                            .font(.body.weight(.semibold))
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .accessibilityIdentifier("composer.title")

                            AppDivider()
                                .padding(.leading, AppSpacing.lg)

                            TextField("Share your thoughts...", text: Binding(
                                get: { viewModel.content },
                                set: { viewModel.updateContent($0) }
                            ), axis: .vertical)
                            .lineLimit(6, reservesSpace: true)
                            .font(.body)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.md)
                            .accessibilityIdentifier("composer.content")
                        }
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(Color.appInputBackground)
                        )
                    }

                    // Media section
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("MEDIA")
                            .appSectionHeader()

                        mediaSelectionSection
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.appLikeRed)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(Color.appLikeRed)
                            Spacer()
                        }
                        .padding(AppSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(Color.appLikeRed.opacity(0.08))
                        )
                        .accessibilityIdentifier("composer.error")
                    }

                    // Success
                    if let postID = viewModel.publishSuccessPostID {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Published post #\(postID)")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                            Spacer()
                        }
                        .padding(AppSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(Color.green.opacity(0.08))
                        )
                        .accessibilityIdentifier("composer.success")
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, 100)
            }

            // Publish bar pinned to bottom
            publishBar
        }
        .background(Color.appSurface.ignoresSafeArea())
        .navigationTitle("New Post")
#if canImport(UIKit) && canImport(PhotosUI)
        .sheet(isPresented: $showMediaPicker) {
            MediaPickerViewRepresentable(
                selectionLimit: 9,
                filter: PHPickerFilter.any(of: [.images, .videos])
            ) { selectedMedia in
                handleMediaSelection(selectedMedia)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
#endif
    }

    // MARK: - Publish Bar

    private var publishBar: some View {
        VStack(spacing: 0) {
            AppDivider()

            HStack(spacing: AppSpacing.lg) {
                #if canImport(UIKit) && canImport(PhotosUI)
                Button {
                    showMediaPicker = true
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
                .accessibilityIdentifier("composer.addMedia")
                #endif

                Spacer()

                Button {
                    Task {
                        _ = await viewModel.publish()
                        if viewModel.publishSuccessPostID != nil {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PostPublished"),
                                object: nil
                            )
                        }
                    }
                } label: {
                    Text(viewModel.isPublishing ? "Publishing..." : "Share")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.xxl)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    viewModel.isPublishing
                                        ? AnyShapeStyle(Color.appAccent.opacity(0.5))
                                        : AnyShapeStyle(LinearGradient.appBrandGradient)
                                )
                        )
                }
                .disabled(viewModel.isPublishing)
                .accessibilityIdentifier("composer.publish")
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Media Selection

    @ViewBuilder
    private var mediaSelectionSection: some View {
        if localMedia.isEmpty {
            #if canImport(UIKit) && canImport(PhotosUI)
            Button {
                showMediaPicker = true
            } label: {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.appAccent)

                    Text("Add Photos or Videos")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appAccent)

                    Text("Up to 9 items")
                        .font(.caption)
                        .foregroundStyle(Color.appTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xxxl)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("composer.addMedia")
            #else
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.appTextTertiary)
                Text("Media picker is available on iOS.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xxl)
            .accessibilityIdentifier("composer.addMedia")
            #endif
        } else {
            // Media preview grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 90, maximum: 110), spacing: AppSpacing.sm)
            ], spacing: AppSpacing.sm) {
                ForEach(localMedia) { media in
                    MediaThumbnailView(media: media) {
                        removeMedia(id: media.id)
                    }
                }

                #if canImport(UIKit) && canImport(PhotosUI)
                // Add more button
                if localMedia.count < 9 {
                    Button {
                        showMediaPicker = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .strokeBorder(Color.appDivider, lineWidth: 1)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                        .frame(height: 90)
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
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

// MARK: - Media Thumbnail

struct MediaThumbnailView: View {
    let media: ComposerMediaDraft
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailContent
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .offset(x: 4, y: -4)
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

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .offset(x: 1)
                    }
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.appInputBackground
            Image(systemName: media.mediaType == .image ? "photo" : "video")
                .font(.title3)
                .foregroundStyle(Color.appTextTertiary)
        }
    }
}
