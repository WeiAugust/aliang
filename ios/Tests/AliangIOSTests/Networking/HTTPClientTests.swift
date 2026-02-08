import AliangIOS
import Foundation
import XCTest

final class HTTPClientTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com")!

    override func setUp() {
        super.setUp()
        URLProtocolStub.handler = nil
    }

    func testSendDecodesEnvelopePayload() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://example.com/api/v1/ping")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = #"{"success":true,"data":{"value":"pong"}}"#.data(using: .utf8)!
            return (response, data)
        }

        let client = makeClient()

        let result = try await client.send(PingRequest(), authToken: nil)

        XCTAssertEqual(result, PingResponse(value: "pong"))
    }

    func testSendAddsAuthorizationHeaderForAuthRequest() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-abc")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = #"{"success":true,"data":{"value":"ok"}}"#.data(using: .utf8)!
            return (response, data)
        }

        let client = makeClient()

        _ = try await client.send(ProtectedPingRequest(), authToken: "token-abc")
    }

    func testSendWithoutAuthTokenThrowsUnauthorized() async {
        let client = makeClient()

        do {
            _ = try await client.send(ProtectedPingRequest(), authToken: nil)
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMaps401AsUnauthorized() async {
        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let client = makeClient()

        do {
            _ = try await client.send(PingRequest(), authToken: nil)
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMapsServerEnvelopeError() async {
        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let data = #"{"success":false,"error_code":"INTERNAL","message":"boom"}"#.data(using: .utf8)!
            return (response, data)
        }

        let client = makeClient()

        do {
            _ = try await client.send(PingRequest(), authToken: nil)
            XCTFail("Expected server error")
        } catch let error as APIError {
            XCTAssertEqual(error, .server(statusCode: 500, code: "INTERNAL", message: "boom"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSendMapsTransportError() async {
        URLProtocolStub.handler = { _ in
            throw URLError(.timedOut)
        }

        let client = makeClient()

        do {
            _ = try await client.send(PingRequest(), authToken: nil)
            XCTFail("Expected network error")
        } catch let error as APIError {
            guard case .network = error else {
                return XCTFail("Unexpected APIError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeClient() -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return HTTPClient(baseURL: baseURL, urlSession: session)
    }
}

private struct PingRequest: APIRequest {
    typealias Response = PingResponse

    let path = "api/v1/ping"
}

private struct ProtectedPingRequest: APIRequest {
    typealias Response = PingResponse

    let path = "api/v1/ping"
    let requiresAuth = true
}

private struct PingResponse: Codable, Equatable {
    let value: String
}

private final class URLProtocolStub: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            fatalError("URLProtocolStub.handler must be set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
