import FanScopeKit
import Foundation
import SwiftData
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

@Suite("SwiftDataWatchlistRepository")
struct SwiftDataWatchlistRepositoryTests {
    @Test("Persists, updates, and deletes watchlist entries in an in-memory ModelContainer")
    func crudLifecycle() async throws {
        let schema = Schema([WatchlistItemModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let repository = SwiftDataWatchlistRepository(modelContainer: container)

        let initial = WatchlistEntry(
            symbol: "FB",
            targetPriceTRY: Decimal(12.5),
            targetDirection: .above,
            note: "Initial note"
        )
        try await repository.upsert(initial)

        var fetched = try await repository.fetchEntries()
        #expect(fetched.count == 1)
        #expect(fetched.first?.symbol == "FB")
        #expect(fetched.first?.targetPriceTRY == Decimal(12.5))

        let updated = WatchlistEntry(
            symbol: "fb",
            targetPriceTRY: Decimal(14),
            targetDirection: .below,
            note: "Updated note"
        )
        try await repository.upsert(updated)

        fetched = try await repository.fetchEntries()
        #expect(fetched.count == 1)
        #expect(fetched.first?.targetPriceTRY == Decimal(14))
        #expect(fetched.first?.targetDirection == .below)
        #expect(fetched.first?.note == "Updated note")

        try await repository.remove(symbol: "FB")
        fetched = try await repository.fetchEntries()
        #expect(fetched.isEmpty)
    }
}
