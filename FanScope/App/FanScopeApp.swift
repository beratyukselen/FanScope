import SwiftUI

@main
struct FanScopeApp: App {
    @AppStorage("app_language") private var selectedLanguage: AppLanguage = .system
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView(container: container)
                .environment(\.locale, selectedLanguage.locale)
        }
    }
}
