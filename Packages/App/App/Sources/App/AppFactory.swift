import AppBase
import DI

@MainActor public protocol AppFactory: Sendable {
    func create() -> any ScreenProvider<Void, AppView>
}

public final class DefaultAppFactory: AppFactory {
    let di: AnonymousDomainLayerSession

    public init(di: AnonymousDomainLayerSession) {
        self.di = di
    }

    public func create() -> any ScreenProvider<Void, AppView> {
        AppModel(di: di)
    }
}
