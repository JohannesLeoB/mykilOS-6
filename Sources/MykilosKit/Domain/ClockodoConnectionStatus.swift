public enum ClockodoConnectionStatus: Equatable, Sendable {
    case disconnected
    case connected
    case error(String)
}
