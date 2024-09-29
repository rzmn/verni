import AppBase
import DI

public protocol AppFactory: Sendable {
    func create() async -> any ScreenProvider<Void, AppView>
}

public final class DefaultAppFactory: AppFactory {
    let di: DIContainer

    public init(di: DIContainer) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<Void, AppView> {
        await AppModel(di: di)
    }
}
