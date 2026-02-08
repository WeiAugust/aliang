import Foundation

struct SendSMSRequest: APIRequest {
    typealias Response = SendSMSResponse

    let phone: String

    var path: String { "api/v1/auth/sms/send" }
    var method: HTTPMethod { .post }

    var body: Data? {
        try? JSONEncoder().encode(SendSMSRequestBody(phone: phone))
    }

    var headers: [String: String] {
        ["Content-Type": "application/json"]
    }
}

struct VerifySMSRequest: APIRequest {
    typealias Response = VerifySMSResponse

    let phone: String
    let code: String

    var path: String { "api/v1/auth/sms/verify" }
    var method: HTTPMethod { .post }

    var body: Data? {
        try? JSONEncoder().encode(VerifySMSRequestBody(phone: phone, code: code))
    }

    var headers: [String: String] {
        ["Content-Type": "application/json"]
    }
}
