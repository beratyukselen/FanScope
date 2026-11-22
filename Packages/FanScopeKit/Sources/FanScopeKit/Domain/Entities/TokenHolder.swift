import Foundation

public struct TokenHolder: Identifiable, Hashable, Sendable {
    public var id: String { address.lowercased() }
    public let address: String
    public let label: String?
    public let role: WalletRole?
    public let balance: Double
    public let sharePercentage: Double?

    public init(
        address: String,
        label: String? = nil,
        role: WalletRole? = nil,
        balance: Double,
        sharePercentage: Double? = nil
    ) {
        self.address = address
        self.label = label
        self.role = role
        self.balance = balance
        self.sharePercentage = sharePercentage
    }
}
