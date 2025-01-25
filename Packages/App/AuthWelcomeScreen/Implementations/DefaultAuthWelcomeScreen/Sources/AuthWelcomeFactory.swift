import Logging
import AppBase
import AuthWelcomeScreen

public final class DefaultAuthWelcomeFactory: AuthWelcomeFactory {
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func create() async -> any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions> {
        await AuthWelcomeModel(logger: logger)
    }
}
