import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("tab.markets", systemImage: "chart.line.uptrend.xyaxis") {
                NavigationStack {
                    ContentUnavailableView(
                        "tab.markets",
                        systemImage: "chart.bar.xaxis",
                        description: Text("markets.placeholder.description")
                    )
                    .navigationTitle("FanScope")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            LanguageMenuButton()
                        }
                    }
                }
            }

            Tab("tab.watchlist", systemImage: "star.fill") {
                NavigationStack {
                    ContentUnavailableView(
                        "tab.watchlist",
                        systemImage: "star",
                        description: Text("watchlist.placeholder.description")
                    )
                    .navigationTitle("tab.watchlist")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            LanguageMenuButton()
                        }
                    }
                }
            }
        }
        .tint(AppColors.accent)
    }
}

#Preview {
    MainTabView()
}
