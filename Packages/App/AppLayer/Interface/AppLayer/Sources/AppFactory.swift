import AppBase

public protocol AppFactory: Sendable {
    @MainActor func view() -> AppView
}
