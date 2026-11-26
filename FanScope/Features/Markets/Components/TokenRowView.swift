import FanScopeKit
import SwiftUI

struct TokenRowView: View {
    let token: FanToken
    var isWatched: Bool = false

    private var movementColor: Color {
        AppColors.priceMovement(token.ticker.changePercent24h)
    }

    var body: some View {
        HStack(spacing: 12) {
            ClubBadgeView(definition: token.definition, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(token.definition.symbol)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if isWatched {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.warning)
                    }

                    Text(token.definition.network.tokenStandard)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                }

                Text(token.definition.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            MiniSparklineView(
                points: downsampledSparkline(token.sparkline7dTRY, maxCount: 28),
                tintColor: movementColor
            )
            .frame(width: 56, height: 28)

            VStack(alignment: .trailing, spacing: 4) {
                Text(FanScopeFormatter.tryPrice(token.ticker.lastPriceTRY))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(FanScopeFormatter.signedPercentage(token.ticker.changePercent24h))
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(movementColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(movementColor.opacity(0.14), in: Capsule())
            }
            .frame(minWidth: 78, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func downsampledSparkline(_ points: [Double], maxCount: Int) -> [Double] {
        guard points.count > maxCount, maxCount > 1 else { return points }
        let strideStep = Double(points.count - 1) / Double(maxCount - 1)
        return (0..<maxCount).map { idx in
            let sourceIndex = Int((Double(idx) * strideStep).rounded())
            return points[min(sourceIndex, points.count - 1)]
        }
    }
}
