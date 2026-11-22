import Foundation

public enum NetworkError: Error, Equatable, Sendable, LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited(retryAfterSeconds: Int?)
    case httpStatus(code: Int)
    case decodingFailed(String)
    case transportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to build a valid request URL."
        case .invalidResponse:
            return "Received an invalid server response."
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limit reached. Retry after \(retryAfter) seconds."
            }
            return "Rate limit reached. Please try again shortly."
        case .httpStatus(let code):
            return "Server returned HTTP status \(code)."
        case .decodingFailed(let detail):
            return "Failed to decode server payload: \(detail)"
        case .transportFailed(let detail):
            return "Network request failed: \(detail)"
        }
    }
}
