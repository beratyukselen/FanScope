import SwiftUI

struct ClubBadgeView: View {
    let symbol: String
    let primaryColor: Color
    let secondaryColor: Color
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(symbol.uppercased())
                .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .padding(.horizontal, 4)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(symbol.uppercased()) token badge")
    }
}

#Preview {
    HStack(spacing: 12) {
        ClubBadgeView(symbol: "FB", primaryColor: .yellow, secondaryColor: .indigo)
        ClubBadgeView(symbol: "GAL", primaryColor: .red, secondaryColor: .orange)
        ClubBadgeView(symbol: "BJK", primaryColor: .black, secondaryColor: .gray)
        ClubBadgeView(symbol: "TRA", primaryColor: .purple, secondaryColor: .cyan)
    }
    .padding()
}
