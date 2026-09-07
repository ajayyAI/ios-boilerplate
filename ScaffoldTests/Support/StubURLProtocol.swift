//
//  StubURLProtocol.swift
//  ScaffoldTests
//

import Foundation

/// Intercepts inside `URLSession` so the request building and response handling under test
/// are the real ones, rather than mocking `HTTPClient` and testing nothing.
///
/// The response comes from the host — `status-503.test` answers 503, anything else answers
/// 200 — because `URLSessionConfiguration` only accepts a `URLProtocol` *type*. Reading the
/// intended status out of static storage instead would have every parallel test case
/// picking up whichever status a sibling set last.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    static let email = "remote@example.com"

    /// The only mutable state left. Read by the one test that asserts on request headers,
    /// which is why that suite is `.serialized`.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    /// A session that answers every request through this protocol. `.ephemeral` so nothing
    /// is cached between tests.
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// `https://status-503.test` → 503. Any other host → 200.
    static func status(forHost host: String?) -> Int {
        guard let host, host.hasPrefix("status-"), let code = Int(host.dropFirst(7).prefix(3)) else {
            return 200
        }
        return code
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request

        guard
            let url = request.url,
            let response = HTTPURLResponse(
                url: url,
                statusCode: Self.status(forHost: url.host()),
                httpVersion: "HTTP/1.1",
                headerFields: nil,
            )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"email":"\#(Self.email)"}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
