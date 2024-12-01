import AppBase
import DI

public protocol AuthWelcomeFactory: Sendable {
    func create() async -> any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView>
}

public final class DefaultAuthWelcomeFactory: AuthWelcomeFactory {
    private let di: AnonymousDomainLayerSession

    public init(di: AnonymousDomainLayerSession) {
        self.di = di
    }

    public func create() async -> any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView> {
        await AuthWelcomeModel(di: di)
    }
}
