import Foundation
import Testing
@testable import FanScopeKit

@Suite("URLSessionHTTPClient")
struct HTTPClientTests {
    private struct SamplePayload: Decodable, Equatable, Sendable {
        let symbol: String
        let price: Double
    }

    @Test("Decodes valid 200 JSON responses")
    func decodesSuccessPayload() async throws {
        let host = "success-\(UUID().uuidString.lowercased()).test"
        MockURLProtocol.register(host: host) { request in
            let url = try #require(request.url)
            let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
            let data = Data(#"{"symbol":"FB","price":10.31}"#.utf8)
            return (response, data)
        }
        defer { MockURLProtocol.unregister(host: host) }

        let client = URLSessionHTTPClient(session: MockURLProtocol.makeSession())
        let endpoint = Endpoint(host: host, path: "/ticker")

        let decoded: SamplePayload = try await client.send(endpoint)
        #expect(decoded == SamplePayload(symbol: "FB", price: 10.31))
    }

    @Test("Maps HTTP 429 and Retry-After header to rateLimited error")
    func mapsRateLimitedResponse() async throws {
        let host = "ratelimit-\(UUID().uuidString.lowercased()).test"
        MockURLProtocol.register(host: host) { request in
            let url = try #require(request.url)
            let response = try #require(
                HTTPURLResponse(
                    url: url,
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: ["Retry-After": "45"]
                )
            )
            return (response, Data())
        }
        defer { MockURLProtocol.unregister(host: host) }

        let client = URLSessionHTTPClient(session: MockURLProtocol.makeSession())
        let endpoint = Endpoint(host: host, path: "/coins/markets")

        await #expect(throws: NetworkError.rateLimited(retryAfterSeconds: 45)) {
            _ = try await client.send(endpoint)
        }
    }

    @Test("Maps non-2xx HTTP responses to httpStatus error")
    func mapsServerErrorStatus() async throws {
        let host = "servererror-\(UUID().uuidString.lowercased()).test"
        MockURLProtocol.register(host: host) { request in
            let url = try #require(request.url)
            let response = try #require(HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil))
            return (response, Data())
        }
        defer { MockURLProtocol.unregister(host: host) }

        let client = URLSessionHTTPClient(session: MockURLProtocol.makeSession())
        let endpoint = Endpoint(host: host, path: "/orderbook")

        await #expect(throws: NetworkError.httpStatus(code: 503)) {
            _ = try await client.send(endpoint)
        }
    }

    @Test("Maps malformed JSON to decodingFailed error")
    func mapsDecodingFailure() async throws {
        let host = "decode-\(UUID().uuidString.lowercased()).test"
        MockURLProtocol.register(host: host) { request in
            let url = try #require(request.url)
            let response = try #require(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil))
            return (response, Data(#"{"unexpected":true}"#.utf8))
        }
        defer { MockURLProtocol.unregister(host: host) }

        let client = URLSessionHTTPClient(session: MockURLProtocol.makeSession())
        let endpoint = Endpoint(host: host, path: "/ticker")

        do {
            let _: SamplePayload = try await client.send(endpoint)
            Issue.record("Expected decodingFailed error")
        } catch let error as NetworkError {
            if case .decodingFailed = error {
                #expect(Bool(true))
            } else {
                Issue.record("Expected decodingFailed, got \(error)")
            }
        }
    }

    @Test("Preserves CancellationError when request is cancelled")
    func preservesCancellation() async throws {
        let host = "cancel-\(UUID().uuidString.lowercased()).test"
        MockURLProtocol.register(host: host) { _ in
            throw URLError(.cancelled)
        }
        defer { MockURLProtocol.unregister(host: host) }

        let client = URLSessionHTTPClient(session: MockURLProtocol.makeSession())
        let endpoint = Endpoint(host: host, path: "/ticker")

        await #expect(throws: CancellationError.self) {
            _ = try await client.send(endpoint)
        }
    }

    @Test("Rejects endpoints with an empty host")
    func rejectsInvalidEndpoint() {
        let endpoint = Endpoint(host: "", path: "/ticker")
        #expect(throws: NetworkError.invalidURL) {
            _ = try endpoint.makeURLRequest()
        }
    }
}
