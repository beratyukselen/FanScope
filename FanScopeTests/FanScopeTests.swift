import FanScopeKit
import Testing
@testable import FanScope

@Suite("LoadState")
struct LoadStateTests {
    @Test("Extracts loaded value and reflects loading status")
    func stateHelpers() {
        let loading: LoadState<[String]> = .loading
        #expect(loading.isLoading)
        #expect(loading.value == nil)

        let loaded: LoadState<[String]> = .loaded(["FB", "GAL"])
        #expect(!loaded.isLoading)
        #expect(loaded.value == ["FB", "GAL"])
    }
}

@Suite("AppLanguage")
struct AppLanguageTests {
    @Test("Maps explicit language selections to expected locale identifiers")
    func localeIdentifiers() {
        #expect(AppLanguage.english.locale.identifier == "en")
        #expect(AppLanguage.turkish.locale.identifier == "tr")
    }
}
