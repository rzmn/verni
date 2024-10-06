import AppBase
import DI

@MainActor public protocol AppFactory: Sendable {
    func create() -> any ScreenProvider<Void, AppView>
}

public final class DefaultAppFactory: AppFactory {
    let di: DIContainer

    public init(di: DIContainer) {
        self.di = di
    }

    public func create() -> any ScreenProvider<Void, AppView> {
        AppModel(di: di)
    }
}
