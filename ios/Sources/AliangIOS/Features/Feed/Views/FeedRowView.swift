import SwiftUI

struct FeedRowView: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
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
