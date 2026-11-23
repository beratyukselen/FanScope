import FanScopeKit
import SwiftUI

extension Color {
    init(_ rgb: RGBColor) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

extension ClubBadgeView {
    init(definition: TokenDefinition, size: CGFloat = 40) {
        self.init(
            symbol: definition.symbol,
            primaryColor: Color(definition.badgeColors.primary),
            secondaryColor: Color(definition.badgeColors.secondary),
            size: size
        )
    }
}
