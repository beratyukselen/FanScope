import Foundation
import Testing
@testable import FanScopeKit

@Suite("PriceTargetEvaluator")
struct PriceTargetEvaluatorTests {
    private let evaluator = PriceTargetEvaluator()

    @Test("Evaluates above target as pending and reached accurately")
    func evaluatesAboveTarget() throws {
        let pending = try #require(
            evaluator.evaluate(
                currentPriceTRY: Decimal(10),
                targetPriceTRY: Decimal(12),
                direction: .above
            )
        )
        #expect(!pending.isReached)
        #expect(abs(pending.distancePercentage - 20.0) < 0.001)

        let reached = try #require(
            evaluator.evaluate(
                currentPriceTRY: Decimal(12),
                targetPriceTRY: Decimal(12),
                direction: .above
            )
        )
        #expect(reached.isReached)
        #expect(abs(reached.distancePercentage) < 0.001)
    }

    @Test("Evaluates below dip target accurately")
    func evaluatesBelowTarget() throws {
        let pending = try #require(
            evaluator.evaluate(
                currentPriceTRY: Decimal(10),
                targetPriceTRY: Decimal(8),
                direction: .below
            )
        )
        #expect(!pending.isReached)
        #expect(abs(pending.distancePercentage - (-20.0)) < 0.001)

        let reached = try #require(
            evaluator.evaluate(
                currentPriceTRY: Decimal(7.5),
                targetPriceTRY: Decimal(8),
                direction: .below
            )
        )
        #expect(reached.isReached)
    }

    @Test("Returns nil for non-positive prices")
    func rejectsNonPositiveInputs() {
        #expect(evaluator.evaluate(currentPriceTRY: Decimal(0), targetPriceTRY: Decimal(10), direction: .above) == nil)
        #expect(evaluator.evaluate(currentPriceTRY: Decimal(10), targetPriceTRY: Decimal(-5), direction: .below) == nil)
    }
}
