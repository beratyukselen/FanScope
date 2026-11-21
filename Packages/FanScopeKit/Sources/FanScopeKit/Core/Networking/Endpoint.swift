import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

public struct Endpoint: Sendable, Hashable {
    public let scheme: String
    public let host: String
    public let path: String
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let method: HTTPMethod
    public let timeout: TimeInterval

    public init(
        scheme: String = "https",
        host: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        method: HTTPMethod = .get,
        timeout: TimeInterval = 15
    ) {
        self.scheme = scheme
        self.host = host
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.method = method
        self.timeout = timeout
    }

    public func makeURLRequest() throws(NetworkError) -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path.hasPrefix("/") ? path : "/\(path)"
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url, !host.isEmpty else {
            throw .invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
