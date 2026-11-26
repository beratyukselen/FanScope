import FanScopeKit
import Foundation
import OSLog
import UserNotifications

actor PriceTargetNotifier {
    private var notifiedKeys: Set<String> = []

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func notifyReachedTargets(in rows: [WatchlistItemRow]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        for row in rows {
            guard let status = row.targetStatus,
                  status.isReached,
                  let target = row.entry.targetPriceTRY,
                  let current = row.token?.ticker.lastPriceTRY else {
                continue
            }

            let dedupKey = "\(row.entry.symbol)-\(target)-\(row.entry.targetDirection.rawValue)"
            guard !notifiedKeys.contains(dedupKey) else { continue }
            notifiedKeys.insert(dedupKey)

            let content = UNMutableNotificationContent()
            content.title = "\(row.entry.symbol) Target Reached"
            content.body = "Current: \(FanScopeFormatter.tryPrice(current)) · Target: \(FanScopeFormatter.tryPrice(target))"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "fanscope.target.\(dedupKey)",
                content: content,
                trigger: nil
            )

            do {
                try await center.add(request)
            } catch {
                AppLogger.ui.warning("Failed to schedule local alert for \(row.entry.symbol, privacy: .public)")
            }
        }
    }
}
