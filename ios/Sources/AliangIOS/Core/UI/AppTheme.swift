import SwiftUI

// MARK: - Color Palette

extension Color {
    // Backgrounds
    static var appCardBackground: Color {
        #if os(iOS)
        Color(.secondarySystemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var appGroupedBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var appSurface: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    // Brand accent — warm coral-rose inspired by Instagram's gradient
    static let appAccent = Color(red: 0.91, green: 0.30, blue: 0.42)
    static let appAccentLight = Color(red: 0.98, green: 0.56, blue: 0.36)
    static let appAccentPurple = Color(red: 0.55, green: 0.23, blue: 0.83)

    // Semantic
    static let appLikeRed = Color(red: 0.93, green: 0.24, blue: 0.30)
    static let appTextPrimary = Color.primary
    static let appTextSecondary = Color.secondary
    static let appTextTertiary = Color.secondary.opacity(0.6)
    static let appDivider = Color.primary.opacity(0.08)
    static let appInputBackground = Color.primary.opacity(0.04)
    static let appShimmer = Color.secondary.opacity(0.12)
}

// MARK: - Gradients

extension LinearGradient {
    static let appBrandGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.56, blue: 0.36),
            Color(red: 0.91, green: 0.30, blue: 0.42),
            Color(red: 0.55, green: 0.23, blue: 0.83),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appSubtleGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.96, blue: 0.94),
            Color(red: 0.95, green: 0.93, blue: 0.97),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let appDarkSubtleGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.11, blue: 0.13),
            Color(red: 0.10, green: 0.09, blue: 0.14),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Spacing Tokens

enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Radius Tokens

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Avatar Sizes

enum AppAvatar {
    static let small: CGFloat = 32
    static let medium: CGFloat = 40
    static let large: CGFloat = 80
    static let xlarge: CGFloat = 96
}

// MARK: - View Modifiers

extension View {
    func appCardStyle(cornerRadius: CGFloat = 14) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.appCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.appDivider, lineWidth: 0.5)
        )
    }

    func appElevatedCard(cornerRadius: CGFloat = AppRadius.lg) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
        )
    }

    func appInputStyle(cornerRadius: CGFloat = AppRadius.md) -> some View {
        padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.appInputBackground)
        )
    }

    func appGradientButton() -> some View {
        font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(LinearGradient.appBrandGradient)
        )
    }

    func appSecondaryButton() -> some View {
        font(.subheadline.weight(.medium))
        .foregroundStyle(Color.appAccent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color.appAccent.opacity(0.1))
        )
    }

    func appSectionHeader() -> some View {
        font(.footnote.weight(.semibold))
        .foregroundStyle(Color.appTextSecondary)
        .textCase(.uppercase)
        .tracking(0.5)
    }
}

// MARK: - Animated Like Button

struct AnimatedLikeButton: View {
    let isLiked: Bool
    let count: Int
    let action: () -> Void

    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animationScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animationScale = 1.0
                }
            }
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isLiked ? Color.appLikeRed : Color.appTextSecondary)
                    .scaleEffect(animationScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)

                if count > 0 {
                    Text("\(count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isLiked ? Color.appLikeRed : Color.appTextSecondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interaction Button

struct InteractionButton: View {
    let icon: String
    let count: Int
    var tint: Color = .appTextSecondary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
            if count > 0 {
                Text("\(count)")
                    .font(.subheadline.weight(.medium))
                    .contentTransition(.numericText())
            }
        }
        .foregroundStyle(tint)
    }
}

// MARK: - Avatar View

struct AppAvatarView: View {
    let url: String?
    var size: CGFloat = AppAvatar.medium
    var showBorder: Bool = false

    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                ZStack {
                    LinearGradient.appBrandGradient
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.38, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            @unknown default:
                Color.appShimmer
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showBorder {
                Circle()
                    .strokeBorder(
                        LinearGradient.appBrandGradient,
                        lineWidth: 2.5
                    )
                    .padding(-3)
            }
        }
    }
}

// MARK: - Divider

struct AppDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.appDivider)
            .frame(height: 0.5)
    }
}
