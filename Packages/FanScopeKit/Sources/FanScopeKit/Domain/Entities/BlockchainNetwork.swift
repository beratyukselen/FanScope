import Foundation

public enum BlockchainNetwork: String, CaseIterable, Codable, Hashable, Sendable {
    case ethereum
    case chiliz

    public var displayName: String {
        switch self {
        case .ethereum:
            return "Ethereum"
        case .chiliz:
            return "Chiliz Chain"
        }
    }

    public var tokenStandard: String {
        switch self {
        case .ethereum:
            return "ERC-20"
        case .chiliz:
            return "CAP-20"
        }
    }

    public func transactionURL(hash: String) -> URL? {
        switch self {
        case .ethereum:
            return URL(string: "https://eth.blockscout.com/tx/\(hash)")
        case .chiliz:
            return URL(string: "https://chiliscan.com/tx/\(hash)")
        }
    }

    public func addressURL(address: String) -> URL? {
        switch self {
        case .ethereum:
            return URL(string: "https://eth.blockscout.com/address/\(address)")
        case .chiliz:
            return URL(string: "https://chiliscan.com/address/\(address)")
        }
    }
}
