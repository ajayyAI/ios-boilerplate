//
//  HTTPClientTests.swift
//  ScaffoldTests
//

import Foundation
import Testing
@testable import Scaffold

/// The reason `HTTPClient` exists is that `URLSession` hands back a 500's error page as
/// `Data` and lets it fail during decoding instead. These assert the status check, which is
/// the only behaviour the type adds.
///
/// Serialized only for `lastRequest`, the single piece of shared state in the stub.
@Suite(.serialized)
struct HTTPClientTests {
    @Test func `decodes a 200 body`() async throws {
        let user: UserEntity = try await Self.client(host: "api.test").get("user")

        #expect(user.email == StubURLProtocol.email)
    }

    @Test func `sends the user agent`() async throws {
        StubURLProtocol.lastRequest = nil

        let _: UserEntity = try await Self.client(host: "api.test").get("user")

        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "User-Agent") == "Test/1.0")
    }

    /// The case the type exists for: a body that would decode cleanly is still a failure.
    @Test(arguments: [400, 401, 404, 500, 503])
    func `throws on a non-2xx status even when the body parses`(status: Int) async throws {
        let client = try Self.client(host: "status-\(status).test")

        await #expect(throws: HTTPError.status(status)) {
            let _: UserEntity = try await client.get("user")
        }
    }

    /// `PresentableError` renders `localizedDescription`, which for a bare enum is
    /// "The operation couldn't be completed. (Scaffold.HTTPError error 1.)".
    @Test func `status errors read as a sentence`() throws {
        let message = try #require(HTTPError.status(503).errorDescription)

        #expect(!message.isEmpty)
        #expect(!message.contains("HTTPError"))
    }

    private static func client(host: String) throws -> HTTPClient {
        try HTTPClient(
            baseURL: #require(URL(string: "https://\(host)")),
            userAgent: "Test/1.0",
            session: StubURLProtocol.session(),
        )
    }
}
