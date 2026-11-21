import OSLog

public enum AppLogger {
    private static let subsystem = "com.beratyukselen.fanscope"

    public static let network = Logger(subsystem: subsystem, category: "network")
    public static let onChain = Logger(subsystem: subsystem, category: "onchain")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
}
