import AppBase

@MainActor public protocol DebugMenuFactory: Sendable {
    func create() -> any ScreenProvider<DebugMenuEvent, DebugMenuView, Void>
}
