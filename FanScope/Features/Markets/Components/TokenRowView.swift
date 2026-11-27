import FanScopeKit
import SwiftUI

struct TokenRowView: View {
    let token: FanToken
    var isWatched: Bool = false

    private var movementColor: Color {
        AppColors.priceMovement(token.ticker.changePercent24h)
    }

    var body: some View {
        HStack(spacing: 10) {
            ClubBadgeView(definition: token.definition, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(token.definition.symbol)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    if isWatched {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.warning)
                    }
                }

                Text(token.definition.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            MiniSparklineView(
                points: downsampledSparkline(token.sparkline7dTRY, maxCount: 28),
                tintColor: movementColor
            )
            .frame(width: 48, height: 26)

            VStack(alignment: .trailing, spacing: 3) {
                Text(FanScopeFormatter.tryPrice(token.ticker.lastPriceTRY))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(FanScopeFormatter.signedPercentage(token.ticker.changePercent24h))
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(movementColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(movementColor.opacity(0.14), in: Capsule())
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
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
