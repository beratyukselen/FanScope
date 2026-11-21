import SwiftUI

struct LanguageMenuButton: View {
    @AppStorage("app_language") private var selectedLanguage: AppLanguage = .system

    var body: some View {
        Menu {
            Picker(LocalizedStringKey("language.picker.title"), selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(LocalizedStringKey(language.displayNameKey))
                        .tag(language)
                }
            }
        } label: {
            Image(systemName: "globe")
                .accessibilityLabel(LocalizedStringKey("language.picker.title"))
        }
    }
}
