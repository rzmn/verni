import AppBase
import DI
internal import DesignSystem

@MainActor public protocol AppFactory: Sendable {
    func create() -> any ScreenProvider<Void, AppView>
}

public final class DefaultAppFactory: AppFactory {
    private let di: AnonymousDomainLayerSession
    private let haptic: HapticManager

    public init(di: AnonymousDomainLayerSession, haptic: HapticManager) {
        self.di = di
        self.haptic = haptic
        CustomFonts.registerCustomFonts(class: DefaultAppFactory.self)
    }

    public func create() -> any ScreenProvider<Void, AppView> {
        AppModel(di: di, haptic: haptic)
    }
}
