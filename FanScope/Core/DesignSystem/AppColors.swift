import SwiftUI

enum AppColors {
    static let accent = Color.blue
    static let positive = Color(red: 0.08, green: 0.68, blue: 0.42)
    static let negative = Color(red: 0.88, green: 0.25, blue: 0.29)
    static let warning = Color(red: 0.92, green: 0.58, blue: 0.12)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let surfaceBackground = Color(.systemGroupedBackground)

    static func priceMovement(_ percentage: Double) -> Color {
        if percentage > 0 { return positive }
        if percentage < 0 { return negative }
        return .secondary
    }
}
