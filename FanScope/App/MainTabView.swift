import SwiftUI

struct MainTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            Tab("tab.markets", systemImage: "chart.line.uptrend.xyaxis") {
                MarketListView(container: container)
            }

            Tab("tab.watchlist", systemImage: "star.fill") {
                WatchlistView(container: container)
            }
            .badge(container.watchlistViewModel.reachedTargetCount)
        }
        .tint(AppColors.accent)
        .task {
            await container.watchlistViewModel.load()
        }
    }
}

#Preview {
    MainTabView(container: AppContainer())
}
