import AppBase

@MainActor public protocol AppFactory: Sendable {
    func create() -> any ScreenProvider<Void, AppView, Void>
}
