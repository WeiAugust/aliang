import SwiftUI

public struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel

    public init(viewModel: @autoclosure @escaping () -> AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ZStack {
            backgroundGradient

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xxxl) {
                    Spacer().frame(height: 60)

                    brandHeader

                    VStack(spacing: AppSpacing.xl) {
                        phoneSection
                        if viewModel.isCodeSent {
                            verificationSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppSpacing.xxl)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isCodeSent)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.errorMessage != nil)
            }

            if viewModel.isSendingCode || viewModel.isVerifyingCode {
                loadingOverlay
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color.appSurface.ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color.appAccentLight.opacity(0.08))
                    .frame(width: geo.size.width * 1.2)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.15)
                    .blur(radius: 80)

                Circle()
                    .fill(Color.appAccentPurple.opacity(0.06))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.5)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(LinearGradient.appBrandGradient)
                    .frame(width: 72, height: 72)

                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text("Aliang")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Sign in with your phone number")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    // MARK: - Phone Section

    private var phoneSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("PHONE NUMBER")
                .appSectionHeader()

            phoneInputField
                .accessibilityIdentifier("auth.phone")

            Button {
                Task { await viewModel.sendCode() }
            } label: {
                Text("Send Verification Code")
                    .appGradientButton()
            }
            .disabled(!viewModel.canSendCode)
            .opacity(viewModel.canSendCode ? 1 : 0.5)
            .accessibilityIdentifier("auth.send")
        }
        .padding(AppSpacing.xl)
        .appElevatedCard(cornerRadius: AppRadius.xl)
    }

    // MARK: - Verification Section

    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("VERIFICATION CODE")
                .appSectionHeader()

            codeInputField
                .accessibilityIdentifier("auth.code")

            Button {
                Task { await viewModel.verifyCode() }
            } label: {
                Text("Sign In")
                    .appGradientButton()
            }
            .disabled(!viewModel.canVerify)
            .opacity(viewModel.canVerify ? 1 : 0.5)
            .accessibilityIdentifier("auth.login")

            if let sentCode = viewModel.sentCode {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Dev code: \(sentCode)")
                        .font(.caption)
                }
                .foregroundStyle(Color.appTextTertiary)
                .accessibilityIdentifier("auth.devCode")
            }
        }
        .padding(AppSpacing.xl)
        .appElevatedCard(cornerRadius: AppRadius.xl)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.appLikeRed)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.appLikeRed)
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(Color.appLikeRed.opacity(0.08))
        )
        .accessibilityIdentifier("auth.error")
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.appAccent)
                Text("Please wait...")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(AppSpacing.xxxl)
            .appElevatedCard(cornerRadius: AppRadius.xl)
        }
    }

    // MARK: - Input Fields

    @ViewBuilder
    private var phoneInputField: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "phone.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appAccent)
                .frame(width: 20)

            #if os(iOS)
            TextField("Enter phone number", text: $viewModel.phoneNumber)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .font(.body)
            #else
            TextField("Enter phone number", text: $viewModel.phoneNumber)
                .font(.body)
            #endif
        }
        .appInputStyle()
    }

    @ViewBuilder
    private var codeInputField: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appAccent)
                .frame(width: 20)

            #if os(iOS)
            TextField("Enter SMS code", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.body)
            #else
            TextField("Enter SMS code", text: $viewModel.verificationCode)
                .font(.body)
            #endif
        }
        .appInputStyle()
    }
}
