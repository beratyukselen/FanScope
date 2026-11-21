import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .turkish:
            return Locale(identifier: "tr")
        }
    }

    var displayNameKey: String {
        switch self {
        case .system:
            return "language.system"
        case .english:
            return "language.english"
        case .turkish:
            return "language.turkish"
        }
    }
}
