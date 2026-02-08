import SwiftUI

struct PostMediaGridView: View {
    let media: [FeedMedia]
    var cellHeight: CGFloat = 220
    var cornerRadius: CGFloat = 14

    var body: some View {
        if media.isEmpty {
            EmptyView()
        } else if media.count == 1 {
            mediaCell(media[0])
                .frame(height: cellHeight)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(media.prefix(4).enumerated()), id: \.element.id) { index, item in
                    ZStack {
                        mediaCell(item)

                        if index == 3 && media.count > 4 {
                            Rectangle()
                                .fill(.ultraThinMaterial)

                            Text("+\(media.count - 4)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .frame(height: media.count == 2 ? cellHeight : (cellHeight - 2) / 2)
                    .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 2),
            GridItem(.flexible(), spacing: 2),
        ]
    }

    @ViewBuilder
    private func mediaCell(_ item: FeedMedia) -> some View {
        if item.mediaType.lowercased() == "image" {
            AsyncImage(url: URL(string: item.mediaURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallback(symbol: "photo", text: "Load failed")
                case .empty:
                    ZStack {
                        Color.appShimmer
                        ProgressView()
                            .tint(Color.appTextTertiary)
                    }
                @unknown default:
                    fallback(symbol: "photo", text: "Unavailable")
                }
            }
        } else {
            ZStack {
                fallback(symbol: "video.fill", text: "Video")

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .offset(x: 1)
                    }
            }
        }
    }

    private func fallback(symbol: String, text: String) -> some View {
        ZStack {
            Color.appInputBackground
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(text)
                    .font(.caption2)
            }
            .foregroundStyle(Color.appTextTertiary)
        }
    }
}
