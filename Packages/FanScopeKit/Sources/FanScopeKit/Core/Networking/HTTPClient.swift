import Foundation
import OSLog

public protocol HTTPClientProtocol: Sendable {
    func send(_ endpoint: Endpoint) async throws -> Data
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint, decoder: JSONDecoder) async throws -> T
}

public extension HTTPClientProtocol {
    func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        try await send(endpoint, decoder: JSONDecoder())
    }
}

public final class URLSessionHTTPClient: HTTPClientProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ endpoint: Endpoint) async throws -> Data {
        let request = try endpoint.makeURLRequest()
        let urlDescription = request.url?.absoluteString ?? endpoint.path

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch {
            AppLogger.network.error("Request failed for \(urlDescription, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw NetworkError.transportFailed(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 429:
            let retryAfter = httpResponse
                .value(forHTTPHeaderField: "Retry-After")
                .flatMap(Int.init)
            AppLogger.network.warning("Rate limited on \(urlDescription, privacy: .public)")
            throw NetworkError.rateLimited(retryAfterSeconds: retryAfter)
        default:
            AppLogger.network.error("HTTP \(httpResponse.statusCode) on \(urlDescription, privacy: .public)")
            throw NetworkError.httpStatus(code: httpResponse.statusCode)
        }
    }

    public func send<T: Decodable & Sendable>(_ endpoint: Endpoint, decoder: JSONDecoder) async throws -> T {
        let data = try await send(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            AppLogger.network.error("Decode failed for \(endpoint.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
}
