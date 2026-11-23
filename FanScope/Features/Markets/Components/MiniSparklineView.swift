import Charts
import SwiftUI

struct MiniSparklineView: View {
    let points: [Double]
    let tintColor: Color

    private var yDomain: ClosedRange<Double> {
        guard let minValue = points.min(), let maxValue = points.max() else {
            return 0...1
        }
        if minValue == maxValue {
            let padding = max(abs(minValue) * 0.02, 0.01)
            return (minValue - padding)...(maxValue + padding)
        }
        return minValue...maxValue
    }

    var body: some View {
        if points.count >= 2 {
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Price", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(tintColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))

                    AreaMark(
                        x: .value("Index", index),
                        yStart: .value("Min", yDomain.lowerBound),
                        yEnd: .value("Price", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tintColor.opacity(0.22), tintColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: yDomain)
            .chartLegend(.hidden)
            .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.08))
                .overlay {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityHidden(true)
        }
    }
}
