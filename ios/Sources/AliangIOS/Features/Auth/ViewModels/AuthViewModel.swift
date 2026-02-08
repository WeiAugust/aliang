import Foundation

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var phoneNumber = ""
    @Published public var verificationCode = ""
    @Published public private(set) var sentCode: String?

    @Published public private(set) var isSendingCode = false
    @Published public private(set) var isVerifyingCode = false
    @Published public private(set) var isCodeSent = false
    @Published public private(set) var errorMessage: String?

    private let authService: AuthServiceProtocol
    private let session: AppSession

    public init(authService: AuthServiceProtocol, session: AppSession) {
        self.authService = authService
        self.session = session
    }

    public var canSendCode: Bool {
        normalizedPhone(phoneNumber).count >= 11 && !isSendingCode
    }

    public var canVerify: Bool {
        normalizedPhone(phoneNumber).count >= 11
            && verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
            && !isVerifyingCode
    }

    public func sendCode() async {
        let phone = normalizedPhone(phoneNumber)
        guard phone.count >= 11 else {
            errorMessage = "Please enter a valid phone number"
            return
        }

        errorMessage = nil
        isSendingCode = true
        defer { isSendingCode = false }

        do {
            let response = try await authService.sendSMSCode(phone: phone)
            isCodeSent = true
            sentCode = response.code
        } catch {
            errorMessage = mapError(error)
        }
    }

    public func verifyCode() async {
        let phone = normalizedPhone(phoneNumber)
        let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard phone.count >= 11 else {
            errorMessage = "Please enter a valid phone number"
            return
        }

        guard code.count >= 4 else {
            errorMessage = "Please enter verification code"
            return
        }

        errorMessage = nil
        isVerifyingCode = true
        defer { isVerifyingCode = false }

        do {
            let response = try await authService.verifySMSCode(phone: phone, code: code)
            session.login(with: response.token, userID: response.user.id)
            verificationCode = ""
            isCodeSent = false
            sentCode = nil
        } catch {
            errorMessage = mapError(error)
        }
    }

    public func logout() {
        session.logout()
        verificationCode = ""
        isCodeSent = false
        sentCode = nil
    }

    private func normalizedPhone(_ raw: String) -> String {
        raw.filter { $0.isNumber }
    }

    private func mapError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.errorDescription ?? "Request failed"
        }

        return error.localizedDescription
    }
}
