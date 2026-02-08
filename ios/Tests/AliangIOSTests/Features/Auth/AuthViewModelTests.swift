import XCTest
@testable import AliangIOS

@MainActor
final class AuthViewModelTests: XCTestCase {
    func testSendCodeSuccessUpdatesVerificationState() async {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession(tokenStore: tokenStore)
        let mock = AuthServiceMock()

        let viewModel = AuthViewModel(authService: mock, session: session)
        viewModel.phoneNumber = "13800138000"

        await viewModel.sendCode()

        XCTAssertTrue(viewModel.isCodeSent)
        XCTAssertEqual(viewModel.sentCode, "123456")
        XCTAssertNil(viewModel.errorMessage)

        let calls = await mock.sendCodeCalls
        XCTAssertEqual(calls, ["13800138000"])
    }

    func testSendCodeInvalidPhoneShowsValidationMessage() async {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession(tokenStore: tokenStore)
        let mock = AuthServiceMock()

        let viewModel = AuthViewModel(authService: mock, session: session)
        viewModel.phoneNumber = "123"

        await viewModel.sendCode()

        XCTAssertFalse(viewModel.isCodeSent)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a valid phone number")

        let calls = await mock.sendCodeCalls
        XCTAssertTrue(calls.isEmpty)
    }

    func testVerifyAndLoginPersistsTokenAndResetsState() async throws {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession(tokenStore: tokenStore)
        let mock = AuthServiceMock()

        let viewModel = AuthViewModel(authService: mock, session: session)
        viewModel.phoneNumber = "13800138000"
        viewModel.verificationCode = "123456"

        await viewModel.sendCode()
        await viewModel.verifyCode()

        XCTAssertTrue(session.isLoggedIn)
        XCTAssertEqual(session.currentUserID, 1)
        XCTAssertEqual(try tokenStore.readToken(), "token")
        XCTAssertEqual(viewModel.verificationCode, "")
        XCTAssertFalse(viewModel.isCodeSent)
        XCTAssertNil(viewModel.sentCode)

        let calls = await mock.verifyCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.phone, "13800138000")
        XCTAssertEqual(calls.first?.code, "123456")
    }

    func testVerifyFailureShowsErrorAndKeepsLoggedOut() async {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession(tokenStore: tokenStore)
        let mock = AuthServiceMock()
        await mock.setVerifyFailure()

        let viewModel = AuthViewModel(authService: mock, session: session)
        viewModel.phoneNumber = "13800138000"
        viewModel.verificationCode = "000000"

        await viewModel.verifyCode()

        XCTAssertFalse(session.isLoggedIn)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testLogoutClearsTokenAndVerificationState() async throws {
        let tokenStore = InMemoryTokenStore()
        let session = AppSession(tokenStore: tokenStore)
        session.login(with: "existing-token")

        let viewModel = AuthViewModel(authService: AuthServiceMock(), session: session)
        viewModel.verificationCode = "123456"

        viewModel.logout()

        XCTAssertFalse(session.isLoggedIn)
        XCTAssertNil(try tokenStore.readToken())
        XCTAssertEqual(viewModel.verificationCode, "")
        XCTAssertFalse(viewModel.isCodeSent)
        XCTAssertNil(viewModel.sentCode)
    }
}
