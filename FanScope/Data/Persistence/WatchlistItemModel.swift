import FanScopeKit
import Foundation
import SwiftData

@Model
final class WatchlistItemModel {
    @Attribute(.unique) var symbol: String
    var targetPriceTRY: Decimal?
    var targetDirectionRaw: String
    var note: String
    var createdAt: Date

    init(
        symbol: String,
        targetPriceTRY: Decimal? = nil,
        targetDirectionRaw: String = PriceTargetDirection.above.rawValue,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.symbol = symbol.uppercased()
        self.targetPriceTRY = targetPriceTRY
        self.targetDirectionRaw = targetDirectionRaw
        self.note = note
        self.createdAt = createdAt
    }

    func toDomain() -> WatchlistEntry {
        WatchlistEntry(
            symbol: symbol,
            targetPriceTRY: targetPriceTRY,
            targetDirection: PriceTargetDirection(rawValue: targetDirectionRaw) ?? .above,
            note: note,
            createdAt: createdAt
        )
    }
}
