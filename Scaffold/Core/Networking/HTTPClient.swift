//
//  HTTPClient.swift
//  Scaffold
//

import Foundation

/// JSON over HTTP: build a request, check the status, decode the body.
///
/// Deliberately not a protocol, not a request builder and not a retry policy. `URLSession`
/// already does caching, cookies, proxies, connection retry, background transfer and
/// cancellation. The one thing it does not do is treat a 500 as a failure — it hands back
/// the error page as `Data` and a decode failure ten lines later. That is the bug this
/// type exists to prevent; everything else here is passing values through.
///
/// Replace it the day you need auth refresh or multipart. Until then it is the whole
/// networking layer.
nonisolated struct HTTPClient: Sendable {
    let baseURL: URL
    let userAgent: String
    let session: URLSession

    init(baseURL: URL, userAgent: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.session = session
    }

    func get<Value: Decodable>(_ path: String) async throws -> Value {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.notHTTP
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw HTTPError.status(http.statusCode)
        }

        return try JSONDecoder().decode(Value.self, from: data)
    }
}

/// Transport failures stay as `URLError` and decode failures stay as `DecodingError` —
/// both already say what went wrong. This covers only what `URLSession` does not.
enum HTTPError: Error, Equatable {
    /// A response that is not HTTP. Only reachable through a custom `URLProtocol`.
    case notHTTP
    case status(Int)
}

extension HTTPError: LocalizedError {
    /// Without this, `PresentableError` shows "The operation couldn't be completed
    /// (Scaffold.HTTPError error 1.)" on screen.
    var errorDescription: String? {
        switch self {
        case .notHTTP:
            String(localized: "The server sent a response the app could not read.")
        case let .status(code) where code == 401 || code == 403:
            String(localized: "You are not allowed to see this.")
        case let .status(code) where code >= 500:
            String(localized: "The server is having trouble. Try again shortly.")
        case let .status(code):
            String(localized: "The request failed (\(code)).")
        }
    }
}
