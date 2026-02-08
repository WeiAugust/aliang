import SwiftUI

public struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel

    public init(viewModel: @autoclosure @escaping () -> AuthViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Phone") {
                    phoneInputField
                        .accessibilityIdentifier("auth.phone")

                    Button("Send Code") {
                        Task { await viewModel.sendCode() }
                    }
                    .disabled(!viewModel.canSendCode)
                    .accessibilityIdentifier("auth.send")
                }

                if viewModel.isCodeSent {
                    Section("Verification") {
                        codeInputField
                            .accessibilityIdentifier("auth.code")

                        Button("Login") {
                            Task { await viewModel.verifyCode() }
                        }
                        .disabled(!viewModel.canVerify)
                        .accessibilityIdentifier("auth.login")

                        if let sentCode = viewModel.sentCode {
                            Text("Dev code: \(sentCode)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("auth.devCode")
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("auth.error")
                    }
                }
            }
            .navigationTitle("SMS Login")
            .overlay {
                if viewModel.isSendingCode || viewModel.isVerifyingCode {
                    ProgressView("Loading")
                }
            }
        }
    }

    @ViewBuilder
    private var phoneInputField: some View {
        #if os(iOS)
        TextField("Phone number", text: $viewModel.phoneNumber)
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
        #else
        TextField("Phone number", text: $viewModel.phoneNumber)
        #endif
    }

    @ViewBuilder
    private var codeInputField: some View {
        #if os(iOS)
        TextField("SMS code", text: $viewModel.verificationCode)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
        #else
        TextField("SMS code", text: $viewModel.verificationCode)
        #endif
    }
}
