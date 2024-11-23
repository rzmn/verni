import AppBase
import DI

public protocol DebugMenuFactory: Sendable {
    func create() async -> any ScreenProvider<DebugMenuEvent, DebugMenuView>
}

public final class DefaultDebugMenuFactory: DebugMenuFactory {
    private let di: AnonymousDomainLayerSession
    private let haptic: HapticManager

    public init(di: AnonymousDomainLayerSession, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
    }

    public func create() async -> any ScreenProvider<DebugMenuEvent, DebugMenuView> {
        await DebugMenuModel(di: di, haptic: haptic)
    }
}
