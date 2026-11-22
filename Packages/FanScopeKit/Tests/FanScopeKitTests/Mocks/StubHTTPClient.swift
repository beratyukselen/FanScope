import Foundation
import Synchronization
@testable import FanScopeKit

final class StubHTTPClient: HTTPClientProtocol {
    typealias Responder = @Sendable (Endpoint) throws -> Data

    private let responder: Mutex<Responder>
    private let recordedEndpoints = Mutex<[Endpoint]>([])

    init(responder: @escaping Responder) {
        self.responder = Mutex(responder)
    }

    func setResponder(_ newResponder: @escaping Responder) {
        responder.withLock { $0 = newResponder }
    }

    func requestCount(matching predicate: (Endpoint) -> Bool) -> Int {
        recordedEndpoints.withLock { endpoints in
            endpoints.filter(predicate).count
        }
    }

    func send(_ endpoint: Endpoint) async throws -> Data {
        recordedEndpoints.withLock { $0.append(endpoint) }
        let currentResponder = responder.withLock { $0 }
        return try currentResponder(endpoint)
    }

    func send<T: Decodable & Sendable>(_ endpoint: Endpoint, decoder: JSONDecoder) async throws -> T {
        let data = try await send(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
}
