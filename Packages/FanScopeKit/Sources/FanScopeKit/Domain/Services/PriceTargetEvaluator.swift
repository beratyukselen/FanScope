import Foundation

public struct PriceTargetStatus: Hashable, Sendable {
    public let isReached: Bool
    public let distancePercentage: Double

    public init(isReached: Bool, distancePercentage: Double) {
        self.isReached = isReached
        self.distancePercentage = distancePercentage
    }
}

public struct PriceTargetEvaluator: Sendable {
    public init() {}

    public func evaluate(
        currentPriceTRY: Decimal,
        targetPriceTRY: Decimal,
        direction: PriceTargetDirection
    ) -> PriceTargetStatus? {
        guard currentPriceTRY > 0, targetPriceTRY > 0 else {
            return nil
        }

        let currentDouble = NSDecimalNumber(decimal: currentPriceTRY).doubleValue
        let targetDouble = NSDecimalNumber(decimal: targetPriceTRY).doubleValue
        let distancePercentage = ((targetDouble - currentDouble) / currentDouble) * 100.0

        let isReached: Bool = switch direction {
        case .above:
            currentPriceTRY >= targetPriceTRY
        case .below:
            currentPriceTRY <= targetPriceTRY
        }

        return PriceTargetStatus(
            isReached: isReached,
            distancePercentage: distancePercentage
        )
    }
}
