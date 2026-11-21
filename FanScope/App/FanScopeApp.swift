import SwiftUI

@main
struct FanScopeApp: App {
    @AppStorage("app_language") private var selectedLanguage: AppLanguage = .system

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.locale, selectedLanguage.locale)
        }
    }
}
