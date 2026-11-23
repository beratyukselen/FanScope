import SwiftUI

struct MainTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            Tab("tab.markets", systemImage: "chart.line.uptrend.xyaxis") {
                MarketListView(container: container)
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
    MainTabView(container: AppContainer())
}
