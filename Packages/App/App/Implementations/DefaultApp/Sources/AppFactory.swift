import AppBase
import App
internal import DesignSystem

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
