import AppBase
import DI

@MainActor public protocol DebugMenuFactory: Sendable {
    func create() -> any ScreenProvider<DebugMenuEvent, DebugMenuView>
}

@MainActor public final class DefaultDebugMenuFactory: DebugMenuFactory {

    public init() {}

    public func create() -> any ScreenProvider<DebugMenuEvent, DebugMenuView> {
        DebugMenuModel()
    }
}
