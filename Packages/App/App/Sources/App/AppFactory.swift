import AppBase
import DI
internal import DesignSystem

@MainActor public protocol AppFactory: Sendable {
    func create() -> any ScreenProvider<Void, AppView, Void>
}

public final class DefaultAppFactory: AppFactory {
    private let di: AnonymousDomainLayerSession

    public init(di: AnonymousDomainLayerSession) {
        self.di = di
        CustomFonts.registerCustomFonts(class: DefaultAppFactory.self)
    }

    public func create() -> any ScreenProvider<Void, AppView, Void> {
        AppModel(di: di)
    }
}
