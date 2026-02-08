import SwiftUI

struct FeedRowView: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: post.author?.avatarURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .squaredFrame(size: 32)
                            .clipShape(Circle())
                    case .failure, .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .squaredFrame(size: 32)
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .squaredFrame(size: 32)
                    }
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author?.nickname ?? "User \(post.userID)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !post.media.isEmpty, let firstMedia = post.media.first {
                AsyncImage(url: URL(string: firstMedia.mediaURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                    @unknown default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Text(post.title)
                .font(.headline)

            if post.content.isEmpty == false {
                Text(post.content)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 16) {
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(post.isLiked ? .red : .secondary)
                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .foregroundStyle(.secondary)
                Label(post.postType, systemImage: "photo")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }
}
