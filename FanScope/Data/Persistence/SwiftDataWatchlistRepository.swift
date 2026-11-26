import FanScopeKit
import Foundation
import SwiftData

@ModelActor
actor SwiftDataWatchlistRepository: WatchlistRepositoryProtocol {
    func fetchEntries() async throws -> [WatchlistEntry] {
        let descriptor = FetchDescriptor<WatchlistItemModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func upsert(_ entry: WatchlistEntry) async throws {
        let normalized = entry.symbol.uppercased()
        let descriptor = FetchDescriptor<WatchlistItemModel>(
            predicate: #Predicate { $0.symbol == normalized }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.targetPriceTRY = entry.targetPriceTRY
            existing.targetDirectionRaw = entry.targetDirection.rawValue
            existing.note = entry.note
        } else {
            let model = WatchlistItemModel(
                symbol: normalized,
                targetPriceTRY: entry.targetPriceTRY,
                targetDirectionRaw: entry.targetDirection.rawValue,
                note: entry.note,
                createdAt: entry.createdAt
            )
            modelContext.insert(model)
        }

        try modelContext.save()
    }

    func remove(symbol: String) async throws {
        let normalized = symbol.uppercased()
        let descriptor = FetchDescriptor<WatchlistItemModel>(
            predicate: #Predicate { $0.symbol == normalized }
        )

        let matches = try modelContext.fetch(descriptor)
        for item in matches {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}

actor InMemoryWatchlistRepository: WatchlistRepositoryProtocol {
    private var storage: [String: WatchlistEntry] = [:]

    func fetchEntries() async throws -> [WatchlistEntry] {
        Array(storage.values)
    }

    func upsert(_ entry: WatchlistEntry) async throws {
        storage[entry.symbol.uppercased()] = entry
    }

    func remove(symbol: String) async throws {
        _ = storage.removeValue(forKey: symbol.uppercased())
    }
}
