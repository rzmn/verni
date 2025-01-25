import AppBase
import DebugMenuScreen

@MainActor public final class DefaultDebugMenuFactory: DebugMenuFactory {

    public init() {}

    public func create() -> any ScreenProvider<DebugMenuEvent, DebugMenuView, Void> {
        DebugMenuModel()
    }
}
