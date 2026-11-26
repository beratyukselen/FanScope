import FanScopeKit
import Foundation
import OSLog
@preconcurrency import UserNotifications

actor PriceTargetNotifier {
    private var notifiedKeys: Set<String> = []

    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await currentAuthorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await requestNotificationAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func notifyReachedTargets(in rows: [WatchlistItemRow]) async {
        let status = await currentAuthorizationStatus()
        guard status == .authorized || status == .provisional else {
            return
        }

        for row in rows {
            guard let targetStatus = row.targetStatus,
                  targetStatus.isReached,
                  let target = row.entry.targetPriceTRY,
                  let current = row.token?.ticker.lastPriceTRY else {
                continue
            }

            let dedupKey = "\(row.entry.symbol)-\(target)-\(row.entry.targetDirection.rawValue)"
            guard !notifiedKeys.contains(dedupKey) else { continue }
            notifiedKeys.insert(dedupKey)

            let title = "\(row.entry.symbol) Target Reached"
            let body = "Current: \(FanScopeFormatter.tryPrice(current)) · Target: \(FanScopeFormatter.tryPrice(target))"

            do {
                try await scheduleLocalNotification(
                    identifier: "fanscope.target.\(dedupKey)",
                    title: title,
                    body: body
                )
            } catch {
                AppLogger.ui.warning("Failed to schedule local alert for \(row.entry.symbol, privacy: .public)")
            }
        }
    }

    private nonisolated func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private nonisolated func requestNotificationAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    private nonisolated func scheduleLocalNotification(
        identifier: String,
        title: String,
        body: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
