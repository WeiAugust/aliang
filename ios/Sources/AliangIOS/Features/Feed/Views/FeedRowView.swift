import SwiftUI

struct FeedRowView: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Author header
            HStack(spacing: AppSpacing.md) {
                AppAvatarView(url: post.author?.avatarURL, size: AppAvatar.medium)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(post.author?.nickname ?? "User \(post.userID)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text(PostTimestampFormatter.relativeText(for: post.createdAt, relativeTo: context.date))
                            .font(.caption)
                            .foregroundStyle(Color.appTextTertiary)
                    }
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 28, height: 28)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            // Media
            if !post.media.isEmpty {
                PostMediaGridView(media: post.media, cellHeight: 320, cornerRadius: 0)
                    .clipped()
            }

            // Interaction bar
            HStack(spacing: AppSpacing.xl) {
                AnimatedLikeButton(isLiked: post.isLiked, count: post.likeCount, action: {})

                InteractionButton(icon: "bubble.right", count: post.commentCount)

                InteractionButton(icon: "paperplane", count: 0)

                Spacer()

                if post.media.count > 1 {
                    Text("\(post.media.count) photos")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            // Title & Content
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(post.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(Color.appTextPrimary)

                if !post.content.isEmpty {
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)

            AppDivider()
        }
    }
}
