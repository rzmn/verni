import AppBase
import DI
import Logging

public protocol LogInFactory: Sendable {
    func create() async -> any ScreenProvider<LogInEvent, LogInView, ModalTransition>
}

public final class DefaultLogInFactory: LogInFactory {
    private let di: AnonymousDomainLayerSession
    private let logger: Logger

    public init(di: AnonymousDomainLayerSession, logger: Logger) {
        self.di = di
        self.logger = logger
    }

    public func create() async -> any ScreenProvider<LogInEvent, LogInView, ModalTransition> {
        await LogInModel(di: di, logger: logger)
    }
}
