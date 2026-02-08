import Foundation
@testable import AliangIOS

actor AuthServiceMock: AuthServiceProtocol {
    private(set) var sendCodeCalls: [String] = []
    private(set) var verifyCalls: [(phone: String, code: String)] = []

    var sendCodeResult: Result<SendSMSResponse, Error> = .success(
        SendSMSResponse(code: "123456", expiresAt: "5 minutes", phone: "13800138000")
    )
    var verifyResult: Result<VerifySMSResponse, Error> = .success(
        VerifySMSResponse(
            token: "token",
            user: AuthUser(
                id: 1,
                phone: "13800138000",
                nickname: "User_8000",
                avatarURL: nil,
                createdAt: nil
            )
        )
    )

    func sendSMSCode(phone: String) async throws -> SendSMSResponse {
        sendCodeCalls.append(phone)
        return try sendCodeResult.get()
    }

    func verifySMSCode(phone: String, code: String) async throws -> VerifySMSResponse {
        verifyCalls.append((phone: phone, code: code))
        return try verifyResult.get()
    }

    func setVerifyFailure() {
        verifyResult = .failure(TestError.expected)
    }
}
