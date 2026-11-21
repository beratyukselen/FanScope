import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Markets", systemImage: "chart.line.uptrend.xyaxis") {
                NavigationStack {
                    ContentUnavailableView(
                        "Markets",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Live TRY fan token prices and supply metrics will appear here.")
                    )
                    .navigationTitle("FanScope")
                }
            }

            Tab("Watchlist", systemImage: "star.fill") {
                NavigationStack {
                    ContentUnavailableView(
                        "Watchlist",
                        systemImage: "star",
                        description: Text("Track favorite fan tokens and target TRY prices.")
                    )
                    .navigationTitle("Watchlist")
                }
            }
        }
        .tint(AppColors.accent)
    }
}

#Preview {
    MainTabView()
}
