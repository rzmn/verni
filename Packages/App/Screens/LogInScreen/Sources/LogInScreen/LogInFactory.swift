import AppBase
import DI

public protocol LogInFactory: Sendable {
    func create() async -> any ScreenProvider<LogInEvent, LogInView>
}

public final class DefaultLogInFactory: LogInFactory {
    private let di: AnonymousDomainLayerSession

    public init(di: AnonymousDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<LogInEvent, LogInView> {
        await LogInModel(di: di)
    }
}
