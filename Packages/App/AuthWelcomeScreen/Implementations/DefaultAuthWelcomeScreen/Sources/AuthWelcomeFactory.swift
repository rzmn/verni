import AppBase
import DI
import Logging

public protocol AuthWelcomeFactory: Sendable {
    func create() async -> any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions>
}

public final class DefaultAuthWelcomeFactory: AuthWelcomeFactory {
    private let di: AnonymousDomainLayerSession
    private let logger: Logger

    public init(di: AnonymousDomainLayerSession, logger: Logger) {
        self.di = di
        self.logger = logger
    }

    public func create() async -> any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions> {
        await AuthWelcomeModel(di: di, logger: logger)
    }
}
